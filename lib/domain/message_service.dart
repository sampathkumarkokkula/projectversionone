import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hashlib/hashlib.dart' show sha256;

import '../core/clock.dart';
import '../core/ids.dart';
import '../data/local/app_database.dart';
import 'models.dart';
import 'outbound.dart';
import 'payload.dart';
import 'ports.dart';
import 'timer_policy.dart';

/// Result of handling one incoming envelope.
class IncomingOutcome {
  const IncomingOutcome._(this.chatId, this.deliveredMessageId);

  const IncomingOutcome.skipped() : this._(null, null);

  const IncomingOutcome.delivered(String chatId, String messageId) : this._(chatId, messageId);

  final String? chatId;

  /// Set for a newly stored chat message (a delivery receipt is due).
  final String? deliveredMessageId;
}

/// Sending into a blocked chat.
class ChatBlockedException implements Exception {
  const ChatBlockedException();
}

/// 1-to-1 chat logic on top of the encrypted local database: text and photo
/// messages, replies, receipts, deletions, auto-delete timers, wipes,
/// message requests, blocking and profile sharing.
class MessageService {
  MessageService({
    required this.db,
    required this.crypto,
    required this.outbound,
    required this.clock,
    required this.ids,
  });

  final AppDatabase db;
  final E2eCrypto crypto;
  final Outbound outbound;
  final Clock clock;
  final IdGenerator ids;

  static const int maxBodyLength = 4000;

  /// Largest photo accepted for sending (the picker output is ~100-300 KB).
  static const int maxImageBytes = 512 * 1024;

  /// Largest profile picture accepted from a peer.
  static const int maxAvatarBytes = 48 * 1024;

  /// Photo parts never stay on the server longer than this, even without a
  /// timer (text envelopes: 30 days).
  static const Duration imageServerTtl = Duration(days: 7);

  static const Duration _directoryCheckInterval = Duration(hours: 24);
  static const int _idsPerEnvelope = 200;
  static const Duration _repairInterval = Duration(minutes: 10);
  static const String _profileVersionKey = 'profile.version';

  // ---------------------------------------------------------------------------
  // Chats
  // ---------------------------------------------------------------------------

  /// Creates the local chat entry for [peer] (pinning their identity keys).
  /// Chats this user starts are accepted; an existing message request is
  /// accepted by starting a chat with that person.
  Future<Chat> ensureChat(PeerKeys peer) => db.transaction(() async {
        final existing = await db.chatById(peer.userId);
        if (existing != null) {
          if (!existing.accepted) await acceptChat(peer.userId);
          return (await db.chatById(peer.userId))!;
        }
        final now = clock.nowMs();
        await db.into(db.chats).insert(
              ChatsCompanion.insert(
                peerId: peer.userId,
                peerUsername: peer.username,
                peerIdentityKey: peer.identityKey,
                peerSigningKey: peer.signingKey,
                createdAt: now,
                lastActivityAt: now,
                directoryCheckedAt: Value(now),
              ),
            );
        return (await db.chatById(peer.userId))!;
      });

  Future<Chat> _requireChat(String chatId) async {
    final chat = await db.chatById(chatId);
    if (chat == null) throw StateError('unknown chat');
    return chat;
  }

  Future<void> _updateChat(String chatId, ChatsCompanion values) =>
      (db.update(db.chats)..where((c) => c.peerId.equals(chatId))).write(values);

  Future<void> _notice(String chatId, String text, int now) => db.into(db.messages).insert(
        MessagesCompanion.insert(
          id: ids.newId(),
          chatId: chatId,
          fromMe: false,
          kind: MessageKind.system.name,
          body: text,
          sentAt: now,
          localAt: now,
          status: MessageStatus.received.name,
        ),
      );

  /// Accepts a message request: receipts and the profile picture flow from now on.
  Future<void> acceptChat(String chatId) => _updateChat(chatId, const ChatsCompanion(accepted: Value(true)));

  /// Local half of blocking (the server half is in ChatActions).
  Future<void> setBlocked(String chatId, bool blocked) => db.transaction(() async {
        final chat = await db.chatById(chatId);
        if (chat == null || chat.blocked == blocked) return;
        await _updateChat(chatId, ChatsCompanion(blocked: Value(blocked), accepted: Value(blocked ? chat.accepted : true)));
        if (blocked) {
          // Nothing more leaves this phone for them.
          await db.dropOutboxFor(chatId, const ['message', 'receipt', 'timer_change']);
        }
        await _notice(chatId, blocked ? 'You blocked ${chat.peerUsername}.' : 'You unblocked ${chat.peerUsername}.',
            clock.nowMs());
      });

  /// Deletes the chat and everything in it from this phone only. The Olm
  /// session stays, so if the person writes again a new request appears.
  Future<void> deleteChat(String chatId) => db.transaction(() async {
        await db.deletePartsOfChat(chatId);
        await db.dropOutboxFor(chatId, const ['message', 'receipt', 'timer_change']);
        await (db.delete(db.pendingDeletes)..where((p) => p.chatId.equals(chatId))).go();
        await db.removeAvatar(chatId);
        await (db.delete(db.chats)..where((c) => c.peerId.equals(chatId))).go();
      });

  // ---------------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------------

  Future<Chat> _sendableChat(String chatId) async {
    final chat = await _requireChat(chatId);
    if (chat.blocked) throw const ChatBlockedException();
    // Replying to a message request accepts it.
    if (!chat.accepted) await acceptChat(chatId);
    return chat;
  }

  /// Stores the message locally and queues it, encrypted, for the relay.
  ///
  /// The countdown of an auto-delete timer starts now, and only the timer
  /// that is active at this moment applies to this message.
  Future<String> sendText(String chatId, String text, {String? replyTo}) {
    final body = text.trim();
    if (body.isEmpty) throw ArgumentError('empty message');
    if (body.length > maxBodyLength) throw ArgumentError('message too long');
    return db.transaction(() async {
      final chat = await _sendableChat(chatId);
      final now = clock.nowMs();
      final id = ids.newId();
      final ttl = chat.timerSeconds;
      final expiresAt = ttl == null ? null : now + ttl * 1000;
      await db.into(db.messages).insert(
            MessagesCompanion.insert(
              id: id,
              chatId: chatId,
              fromMe: true,
              kind: MessageKind.text.name,
              body: body,
              sentAt: now,
              localAt: now,
              expiresAt: Value(expiresAt),
              status: MessageStatus.pending.name,
              replyTo: Value(replyTo),
            ),
          );
      await outbound.enqueue(
        chatId,
        TextPayload(id: id, body: body, sentAt: now, ttlSeconds: ttl, replyTo: replyTo),
        messageId: id,
        // An undelivered timed message never outlives its timer on the server.
        expiresAtMs: expiresAt,
      );
      await db.touchChat(chatId, now);
      return id;
    });
  }

  /// Sends a photo (a JPEG already shrunk and stripped of metadata by the
  /// image processor) in parts of [ImagePartPayload.partBytes].
  Future<String> sendImage(String chatId, Uint8List jpeg, {required int width, required int height, String? replyTo}) {
    if (!_isJpeg(jpeg)) throw ArgumentError('not a JPEG');
    if (jpeg.length > maxImageBytes) throw ArgumentError('image too large');
    final parts = (jpeg.length / ImagePartPayload.partBytes).ceil();
    if (parts > ImagePartPayload.maxParts) throw ArgumentError('image too large');
    return db.transaction(() async {
      final chat = await _sendableChat(chatId);
      final now = clock.nowMs();
      final id = ids.newId();
      final ttl = chat.timerSeconds;
      final expiresAt = ttl == null ? null : now + ttl * 1000;
      final serverExpiry = min(expiresAt ?? now + imageServerTtl.inMilliseconds, now + imageServerTtl.inMilliseconds);
      await db.into(db.messages).insert(
            MessagesCompanion.insert(
              id: id,
              chatId: chatId,
              fromMe: true,
              kind: MessageKind.image.name,
              body: '',
              sentAt: now,
              localAt: now,
              expiresAt: Value(expiresAt),
              status: MessageStatus.pending.name,
              replyTo: Value(replyTo),
            ),
          );
      await db.into(db.media).insert(MediaCompanion.insert(messageId: id, bytes: jpeg, width: width, height: height));
      final digest = sha256.convert(jpeg).hex();
      for (var i = 0; i < parts; i++) {
        final start = i * ImagePartPayload.partBytes;
        final end = min(start + ImagePartPayload.partBytes, jpeg.length);
        await outbound.enqueue(
          chatId,
          ImagePartPayload(
            id: id,
            part: i,
            total: parts,
            sentAt: now,
            ttlSeconds: ttl,
            width: width,
            height: height,
            sha256: digest,
            data: base64Encode(Uint8List.sublistView(jpeg, start, end)),
            replyTo: replyTo,
          ),
          messageId: id,
          expiresAtMs: serverExpiry,
        );
      }
      await db.touchChat(chatId, now);
      return id;
    });
  }

  /// Removes a message from this phone only. A message that has not left the
  /// phone yet is not sent at all.
  Future<void> deleteForMe(String messageId) => db.transaction(() async {
        await (db.delete(db.outbox)..where((o) => o.messageId.equals(messageId))).go();
        await db.deleteMessagesByIds([messageId]);
      });

  /// Removes one of this user's own messages from both phones (an encrypted
  /// delete command, relayed like a timer expiry).
  Future<void> deleteForEveryone(String messageId) => db.transaction(() async {
        final message = await db.messageById(messageId);
        if (message == null || !message.fromMe || message.kind == MessageKind.system.name) return;
        await (db.delete(db.outbox)..where((o) => o.messageId.equals(messageId))).go();
        await db.into(db.pendingDeletes).insertOnConflictUpdate(
              PendingDeletesCompanion.insert(messageId: messageId, chatId: message.chatId),
            );
        await db.deleteMessagesByIds([messageId]);
      });

  /// Changes the auto-delete timer of a chat (either participant may).
  ///
  /// Throws [TimerLimitReached] when this would be a third timer chat on the
  /// free plan.
  Future<void> setTimer(String chatId, int? seconds) => db.transaction(() async {
        if (!isOfferedTimer(seconds)) throw ArgumentError.value(seconds, 'seconds');
        final chat = await _sendableChat(chatId);
        if (chat.timerSeconds == seconds) return;
        final others = await db.countTimerChats(excluding: chatId);
        if (!TimerPolicy.canChange(current: chat.timerSeconds, next: seconds, otherTimerChats: others)) {
          throw const TimerLimitReached();
        }
        final now = clock.nowMs();
        await _updateChat(chatId, ChatsCompanion(timerSeconds: Value(seconds), timerChangedAt: Value(now)));
        await _notice(
          chatId,
          seconds == null
              ? 'You turned off the auto-delete timer.'
              : 'You set the auto-delete timer to ${timerLabel(seconds)}.',
          now,
        );
        await outbound.enqueue(chatId, TimerPayload(seconds: seconds, changedAt: now));
      });

  /// Marks incoming messages as read and, for accepted chats, queues read
  /// receipts.
  Future<void> markRead(String chatId) => db.transaction(() async {
        final unread = await (db.select(db.messages)
              ..where((m) =>
                  m.chatId.equals(chatId) &
                  m.fromMe.equals(false) &
                  m.kind.isIn([MessageKind.text.name, MessageKind.image.name]) &
                  m.status.equals(MessageStatus.received.name)))
            .get();
        if (unread.isEmpty) return;
        final unreadIds = unread.map((m) => m.id).toList();
        for (final chunk in _chunks(unreadIds)) {
          await (db.update(db.messages)..where((m) => m.id.isIn(chunk)))
              .write(MessagesCompanion(status: Value(MessageStatus.read.name)));
        }
        final chat = await db.chatById(chatId);
        if (chat == null || !chat.accepted || chat.blocked || !await crypto.hasSession(chatId)) return;
        for (final chunk in _chunks(unreadIds)) {
          await outbound.enqueue(chatId, ReceiptPayload(ids: chunk, read: true));
        }
      });

  /// Delivery receipts, only for accepted chats (a stranger does not learn
  /// whether the message arrived until it is accepted).
  Future<void> sendDeliveryReceipts(Map<String, List<String>> idsByChat) => db.transaction(() async {
        for (final entry in idsByChat.entries) {
          if (entry.value.isEmpty) continue;
          final chat = await db.chatById(entry.key);
          if (chat == null || !chat.accepted || chat.blocked || !await crypto.hasSession(entry.key)) continue;
          for (final chunk in _chunks(entry.value)) {
            await outbound.enqueue(entry.key, ReceiptPayload(ids: chunk, read: false));
          }
        }
      });

  /// Turns queued deletions (timer expiries and "delete for everyone") into
  /// encrypted delete commands. Ids for a chat without a session stay queued
  /// until one exists.
  Future<void> relayPendingDeletes() => db.transaction(() async {
        final rows = await db.select(db.pendingDeletes).get();
        if (rows.isEmpty) return;
        final byChat = <String, List<String>>{};
        for (final r in rows) {
          byChat.putIfAbsent(r.chatId, () => []).add(r.messageId);
        }
        final handled = <String>[];
        for (final entry in byChat.entries) {
          if (await db.chatById(entry.key) == null) {
            handled.addAll(entry.value);
            continue;
          }
          if (!await crypto.hasSession(entry.key)) continue;
          for (final chunk in _chunks(entry.value)) {
            await outbound.enqueue(entry.key, DeletePayload(ids: chunk));
          }
          handled.addAll(entry.value);
        }
        for (final chunk in _chunks(handled)) {
          await (db.delete(db.pendingDeletes)..where((p) => p.messageId.isIn(chunk))).go();
        }
      });

  /// Chats with deletions that still have to be relayed.
  Future<Set<String>> pendingDeletePeers() async =>
      {for (final r in await db.select(db.pendingDeletes).get()) r.chatId};

  Future<void> dropPendingDeletes(String peerId) =>
      (db.delete(db.pendingDeletes)..where((p) => p.chatId.equals(peerId))).go();

  /// Re-pins [peer]'s identity keys when the directory shows new ones (the
  /// peer reinstalled or moved phones) and leaves a notice in the chat.
  /// Returns true when the keys changed.
  Future<bool> refreshPeerIdentity(PeerKeys peer) => db.transaction(() async {
        final chat = await db.chatById(peer.userId);
        if (chat == null || chat.peerIdentityKey == peer.identityKey) return false;
        final now = clock.nowMs();
        await _updateChat(
          peer.userId,
          ChatsCompanion(peerIdentityKey: Value(peer.identityKey), peerSigningKey: Value(peer.signingKey)),
        );
        await _notice(peer.userId, 'Your security code with ${chat.peerUsername} changed.', now);
        return true;
      });

  /// Content-free message that sets up (or repairs) the Olm session.
  Future<void> sendHello(String peerId) =>
      db.transaction(() => outbound.enqueue(peerId, const HelloPayload()));

  // ---------------------------------------------------------------------------
  // Own profile (picture + username) for the people this user chats with
  // ---------------------------------------------------------------------------

  Future<int> profileVersion() async => int.tryParse(await db.read(_profileVersionKey) ?? '') ?? 0;

  /// Call after the own picture or username changed: every accepted chat gets
  /// the new profile on the next sync.
  Future<void> bumpProfileVersion() async => db.write(_profileVersionKey, '${await profileVersion() + 1}');

  /// Sends the own profile picture to accepted, unblocked chats that have not
  /// seen the current version (also covers chats started later).
  Future<void> shareProfile() async {
    final version = await profileVersion();
    if (version == 0) return;
    final avatar = await db.avatarOf(selfAvatarId);
    final encoded = avatar == null ? null : base64Encode(avatar);
    final targets = await (db.select(db.chats)
          ..where((c) =>
              c.accepted.equals(true) & c.blocked.equals(false) & c.profileSentVersion.isSmallerThanValue(version)))
        .get();
    for (final chat in targets) {
      if (!await crypto.hasSession(chat.peerId)) continue;
      await db.transaction(() async {
        await outbound.enqueue(chat.peerId, ProfilePayload(version: version, avatarBase64: encoded));
        await _updateChat(chat.peerId, ChatsCompanion(profileSentVersion: Value(version)));
      });
    }
  }

  /// Chats whose peer username should be re-read from the directory: after a
  /// profile announcement, and otherwise once a day.
  Future<List<Chat>> chatsDueForDirectoryCheck() {
    final threshold = clock.nowMs() - _directoryCheckInterval.inMilliseconds;
    return (db.select(db.chats)
          ..where((c) => c.refreshProfile.equals(true) | c.directoryCheckedAt.isSmallerThanValue(threshold))
          ..limit(20))
        .get();
  }

  /// Applies the directory's current entry for a chat peer: a changed
  /// username is shown with a notice. Usernames are only ever taken from the
  /// directory, never from a peer's own message.
  Future<void> applyDirectoryEntry(Chat chat, PeerKeys? entry) => db.transaction(() async {
        final now = clock.nowMs();
        if (entry != null && entry.username != chat.peerUsername) {
          await _updateChat(chat.peerId, ChatsCompanion(peerUsername: Value(entry.username)));
          await _notice(chat.peerId, '${chat.peerUsername} is now ${entry.username}.', now);
        }
        await _updateChat(
          chat.peerId,
          ChatsCompanion(directoryCheckedAt: Value(now), refreshProfile: const Value(false)),
        );
      });

  // ---------------------------------------------------------------------------
  // Session repair bookkeeping
  // ---------------------------------------------------------------------------

  static String _repairKey(String peerId) => 'repair.$peerId';
  static String _repairLastKey(String peerId) => 'repair.last.$peerId';

  Future<void> _requestRepair(String peerId, int now) async {
    final last = int.tryParse(await db.read(_repairLastKey(peerId)) ?? '') ?? 0;
    if (now - last < _repairInterval.inMilliseconds) return;
    await db.write(_repairKey(peerId), '$now');
  }

  /// Peers whose messages could not be decrypted and need a fresh session.
  Future<List<String>> peersNeedingRepair() async {
    final rows = await db.valuesWithPrefix('repair.');
    return [
      for (final r in rows)
        if (!r.key.startsWith('repair.last.')) r.key.substring('repair.'.length),
    ];
  }

  Future<void> repairDone(String peerId) async {
    await db.remove(_repairKey(peerId));
    await db.write(_repairLastKey(peerId), '${clock.nowMs()}');
  }

  // ---------------------------------------------------------------------------
  // Receiving
  // ---------------------------------------------------------------------------

  /// Whether the sender's directory entry is needed to process [env]: for a
  /// pre-key message (new session, possibly a new identity) or a new chat.
  Future<bool> needsDirectory(IncomingEnvelope env) async {
    final wire = WireEnvelope.tryParse(env.ciphertext);
    if (wire == null) return false;
    return wire.olmType == 0 || await db.chatById(env.senderId) == null;
  }

  /// Decrypts and applies one envelope. Idempotent per relay id. [sender] is
  /// the sender's current directory entry when [needsDirectory] said so.
  Future<IncomingOutcome> handleIncoming(IncomingEnvelope env, {PeerKeys? sender}) =>
      db.transaction(() async {
        if (await db.wasProcessed(env.id)) return const IncomingOutcome.skipped();
        final now = clock.nowMs();
        Future<IncomingOutcome> finish(IncomingOutcome outcome) async {
          await db.markProcessed(env.id, now);
          return outcome;
        }

        final wire = WireEnvelope.tryParse(env.ciphertext);
        if (wire == null) return finish(const IncomingOutcome.skipped());

        var chat = await db.chatById(env.senderId);
        final identityKey = sender?.identityKey ?? chat?.peerIdentityKey;

        final String plaintext;
        try {
          plaintext = await crypto.decrypt(env.senderId, identityKey, wire);
        } on Object {
          if (chat != null && !chat.blocked && env.type == 'message') {
            await _notice(chat.peerId, 'A message could not be decrypted.', now);
          }
          await _requestRepair(env.senderId, now);
          return finish(const IncomingOutcome.skipped());
        }

        final payload = Payload.decode(plaintext);
        if (payload is HelloPayload || payload is UnknownPayload) {
          return finish(const IncomingOutcome.skipped());
        }

        if (chat == null) {
          // Only content starts a chat; a stray receipt or delete does not.
          if (payload is! TextPayload && payload is! ImagePartPayload) {
            return finish(const IncomingOutcome.skipped());
          }
          if (sender == null || sender.userId != env.senderId) {
            return finish(const IncomingOutcome.skipped());
          }
          // Someone new: a message request until this user accepts or replies.
          await db.into(db.chats).insert(
                ChatsCompanion.insert(
                  peerId: sender.userId,
                  peerUsername: sender.username,
                  peerIdentityKey: sender.identityKey,
                  peerSigningKey: sender.signingKey,
                  createdAt: now,
                  lastActivityAt: now,
                  accepted: const Value(false),
                  directoryCheckedAt: Value(now),
                ),
              );
          chat = (await db.chatById(sender.userId))!;
        } else if (sender != null && wire.olmType == 0 && sender.identityKey != chat.peerIdentityKey) {
          // The new session was set up with a new identity key: the peer
          // reinstalled the app or signed in on another phone.
          await _updateChat(
            env.senderId,
            ChatsCompanion(peerIdentityKey: Value(sender.identityKey), peerSigningKey: Value(sender.signingKey)),
          );
          await _notice(chat.peerId, 'Your security code with ${chat.peerUsername} changed.', now);
        }

        if (chat.blocked && payload is! DeletePayload && payload is! WipePayload) {
          // The server drops their envelopes after a block; this covers
          // anything fetched before.
          return finish(const IncomingOutcome.skipped());
        }

        final outcome = await _apply(chat, payload, now);
        return finish(outcome);
      });

  /// Expiry of an incoming message: countdown from the moment it was sent
  /// (never later than "now"). Null = keeps.
  int? _incomingExpiry(int sentAt, int? ttlSeconds, int now) {
    if (ttlSeconds == null) return null;
    return min(sentAt, now) + min(ttlSeconds, maxTimerSeconds) * 1000;
  }

  Future<IncomingOutcome> _apply(Chat chat, Payload payload, int now) async {
    switch (payload) {
      case TextPayload(:final id, :final body, :final sentAt, :final ttlSeconds, :final replyTo):
        final wipedBefore = chat.wipedBefore;
        if (wipedBefore != null && sentAt <= wipedBefore) return const IncomingOutcome.skipped();
        final expiresAt = _incomingExpiry(sentAt, ttlSeconds, now);
        if (expiresAt != null && expiresAt <= now) return const IncomingOutcome.skipped();
        final text = body.length > maxBodyLength ? body.substring(0, maxBodyLength) : body;
        await db.into(db.messages).insert(
              MessagesCompanion.insert(
                id: id,
                chatId: chat.peerId,
                fromMe: false,
                kind: MessageKind.text.name,
                body: text,
                sentAt: sentAt,
                localAt: now,
                expiresAt: Value(expiresAt),
                status: MessageStatus.received.name,
                replyTo: Value(replyTo),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await db.touchChat(chat.peerId, now);
        return IncomingOutcome.delivered(chat.peerId, id);

      case ImagePartPayload():
        return _applyImagePart(chat, payload, now);

      case ProfilePayload(:final avatarBase64):
        if (avatarBase64 == null) {
          await db.removeAvatar(chat.peerId);
        } else {
          try {
            final bytes = base64Decode(avatarBase64);
            if (bytes.length <= maxAvatarBytes && _isJpeg(bytes)) await db.setAvatar(chat.peerId, bytes, now);
          } on FormatException {
            // Ignore a malformed picture.
          }
        }
        await _updateChat(chat.peerId, const ChatsCompanion(refreshProfile: Value(true)));
        return const IncomingOutcome.skipped();

      case ReceiptPayload(ids: final receiptIds, :final read):
        final target = read ? MessageStatus.read : MessageStatus.delivered;
        for (final chunk in _chunks(receiptIds)) {
          final rows = await (db.select(db.messages)
                ..where((m) => m.chatId.equals(chat.peerId) & m.fromMe.equals(true) & m.id.isIn(chunk)))
              .get();
          for (final row in rows) {
            if (parseStatus(row.status).rank < target.rank) await db.setStatus(row.id, target);
          }
        }
        return const IncomingOutcome.skipped();

      case DeletePayload(ids: final deleteIds):
        // The author deletes their own messages only (timer expiry or
        // "delete for everyone").
        for (final chunk in _chunks(deleteIds)) {
          await (db.delete(db.messages)
                ..where((m) => m.chatId.equals(chat.peerId) & m.fromMe.equals(false) & m.id.isIn(chunk)))
              .go();
          await (db.delete(db.mediaParts)..where((p) => p.chatId.equals(chat.peerId) & p.messageId.isIn(chunk))).go();
        }
        return const IncomingOutcome.skipped();

      case WipePayload(:final before):
        // Silent: the conversation disappears exactly as on the sender's phone.
        await db.deleteAllMessagesOf(chat.peerId);
        await db.deletePartsOfChat(chat.peerId);
        await (db.delete(db.pendingDeletes)..where((p) => p.chatId.equals(chat.peerId))).go();
        await db.dropOutboxFor(chat.peerId, const ['message', 'delete']);
        final previous = chat.wipedBefore ?? 0;
        await _updateChat(chat.peerId, ChatsCompanion(wipedBefore: Value(max(previous, before))));
        return const IncomingOutcome.skipped();

      case TimerPayload(:final seconds, :final changedAt):
        if (!isAcceptableTimer(seconds) || changedAt <= chat.timerChangedAt) {
          return const IncomingOutcome.skipped();
        }
        // A peer's choice is always applied, even beyond this device's free
        // limit: refusing it would keep their messages longer than they asked.
        await _updateChat(chat.peerId, ChatsCompanion(timerSeconds: Value(seconds), timerChangedAt: Value(changedAt)));
        await _notice(
          chat.peerId,
          seconds == null
              ? '${chat.peerUsername} turned off the auto-delete timer.'
              : '${chat.peerUsername} set the auto-delete timer to ${timerLabel(seconds)}.',
          now,
        );
        return const IncomingOutcome.skipped();

      case HelloPayload():
      case UnknownPayload():
        return const IncomingOutcome.skipped();
    }
  }

  /// Stores one photo part; once all parts are there, joins them, checks the
  /// hash and stores the photo message.
  Future<IncomingOutcome> _applyImagePart(Chat chat, ImagePartPayload p, int now) async {
    final wipedBefore = chat.wipedBefore;
    if (wipedBefore != null && p.sentAt <= wipedBefore) return const IncomingOutcome.skipped();
    final expiresAt = _incomingExpiry(p.sentAt, p.ttlSeconds, now);
    if (expiresAt != null && expiresAt <= now) return const IncomingOutcome.skipped();
    if (p.width <= 0 || p.height <= 0 || p.width > 8192 || p.height > 8192) return const IncomingOutcome.skipped();
    if (await db.messageById(p.id) != null) return const IncomingOutcome.skipped();

    final Uint8List data;
    try {
      data = base64Decode(p.data);
    } on FormatException {
      return const IncomingOutcome.skipped();
    }
    if (data.isEmpty || data.length > ImagePartPayload.partBytes) return const IncomingOutcome.skipped();

    await db.into(db.mediaParts).insert(
          MediaPartsCompanion.insert(
            messageId: p.id,
            part: p.part,
            chatId: chat.peerId,
            total: p.total,
            data: data,
            sentAt: p.sentAt,
            ttlSeconds: Value(p.ttlSeconds),
            width: p.width,
            height: p.height,
            sha256: p.sha256,
            replyTo: Value(p.replyTo),
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );

    final partsQuery = db.select(db.mediaParts)
      ..where((r) => r.messageId.equals(p.id) & r.chatId.equals(chat.peerId))
      ..orderBy([(r) => OrderingTerm.asc(r.part)]);
    final parts = await partsQuery.get();
    final first = parts.first;
    if (parts.length < first.total) return const IncomingOutcome.skipped();

    Future<void> dropParts() =>
        (db.delete(db.mediaParts)..where((r) => r.messageId.equals(p.id) & r.chatId.equals(chat.peerId))).go();

    var consistent = parts.length == first.total;
    for (var i = 0; consistent && i < parts.length; i++) {
      final r = parts[i];
      consistent = r.part == i && r.total == first.total && r.sha256 == first.sha256;
    }
    final jpeg = Uint8List(parts.fold<int>(0, (sum, r) => sum + r.data.length));
    var offset = 0;
    for (final r in parts) {
      jpeg.setRange(offset, offset + r.data.length, r.data);
      offset += r.data.length;
    }
    if (!consistent || !_isJpeg(jpeg) || sha256.convert(jpeg).hex() != first.sha256) {
      await dropParts();
      return const IncomingOutcome.skipped();
    }

    await db.into(db.messages).insert(
          MessagesCompanion.insert(
            id: p.id,
            chatId: chat.peerId,
            fromMe: false,
            kind: MessageKind.image.name,
            body: '',
            sentAt: first.sentAt,
            localAt: now,
            expiresAt: Value(_incomingExpiry(first.sentAt, first.ttlSeconds, now)),
            status: MessageStatus.received.name,
            replyTo: Value(first.replyTo),
          ),
        );
    await db.into(db.media).insert(
          MediaCompanion.insert(messageId: p.id, bytes: jpeg, width: first.width, height: first.height),
        );
    await dropParts();
    await db.touchChat(chat.peerId, now);
    return IncomingOutcome.delivered(chat.peerId, p.id);
  }

  static bool _isJpeg(List<int> bytes) => bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;

  static Iterable<List<String>> _chunks(List<String> items) sync* {
    for (var i = 0; i < items.length; i += _idsPerEnvelope) {
      yield items.sublist(i, min(i + _idsPerEnvelope, items.length));
    }
  }
}
