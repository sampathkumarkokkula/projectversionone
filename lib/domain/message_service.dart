import 'dart:math';

import 'package:drift/drift.dart';

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

/// 1-to-1 chat logic on top of the encrypted local database: sending,
/// receiving, receipts, auto-delete timers, relayed deletes and wipes.
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
  static const int _idsPerEnvelope = 200;
  static const Duration _repairInterval = Duration(minutes: 10);

  // ---------------------------------------------------------------------------
  // Chats
  // ---------------------------------------------------------------------------

  /// Creates the local chat entry for [peer] (pinning their identity keys).
  Future<Chat> ensureChat(PeerKeys peer) => db.transaction(() async {
        final existing = await db.chatById(peer.userId);
        if (existing != null) return existing;
        final now = clock.nowMs();
        await db.into(db.chats).insert(
              ChatsCompanion.insert(
                peerId: peer.userId,
                peerUsername: peer.username,
                peerIdentityKey: peer.identityKey,
                peerSigningKey: peer.signingKey,
                createdAt: now,
                lastActivityAt: now,
              ),
            );
        return (await db.chatById(peer.userId))!;
      });

  Future<Chat> _requireChat(String chatId) async {
    final chat = await db.chatById(chatId);
    if (chat == null) throw StateError('unknown chat');
    return chat;
  }

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

  // ---------------------------------------------------------------------------
  // Sending
  // ---------------------------------------------------------------------------

  /// Stores the message locally and queues it, encrypted, for the relay.
  ///
  /// The countdown of an auto-delete timer starts now, and only the timer
  /// that is active at this moment applies to this message.
  Future<String> sendText(String chatId, String text) {
    final body = text.trim();
    if (body.isEmpty) throw ArgumentError('empty message');
    if (body.length > maxBodyLength) throw ArgumentError('message too long');
    return db.transaction(() async {
      final chat = await _requireChat(chatId);
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
            ),
          );
      await outbound.enqueue(
        chatId,
        TextPayload(id: id, body: body, sentAt: now, ttlSeconds: ttl),
        messageId: id,
        // An undelivered timed message never outlives its timer on the server.
        expiresAtMs: expiresAt,
      );
      await db.touchChat(chatId, now);
      return id;
    });
  }

  /// Changes the auto-delete timer of a chat (either participant may).
  ///
  /// Throws [TimerLimitReached] when this would be a third timer chat on the
  /// free plan.
  Future<void> setTimer(String chatId, int? seconds) => db.transaction(() async {
        if (!isOfferedTimer(seconds)) throw ArgumentError.value(seconds, 'seconds');
        final chat = await _requireChat(chatId);
        if (chat.timerSeconds == seconds) return;
        final others = await db.countTimerChats(excluding: chatId);
        if (!TimerPolicy.canChange(current: chat.timerSeconds, next: seconds, otherTimerChats: others)) {
          throw const TimerLimitReached();
        }
        final now = clock.nowMs();
        await (db.update(db.chats)..where((c) => c.peerId.equals(chatId)))
            .write(ChatsCompanion(timerSeconds: Value(seconds), timerChangedAt: Value(now)));
        await _notice(
          chatId,
          seconds == null
              ? 'You turned off the auto-delete timer.'
              : 'You set the auto-delete timer to ${timerLabel(seconds)}.',
          now,
        );
        await outbound.enqueue(chatId, TimerPayload(seconds: seconds, changedAt: now));
      });

  /// Marks incoming messages as read and queues read receipts.
  Future<void> markRead(String chatId) => db.transaction(() async {
        final unread = await (db.select(db.messages)
              ..where((m) =>
                  m.chatId.equals(chatId) &
                  m.fromMe.equals(false) &
                  m.kind.equals(MessageKind.text.name) &
                  m.status.equals(MessageStatus.received.name)))
            .get();
        if (unread.isEmpty) return;
        final unreadIds = unread.map((m) => m.id).toList();
        for (final chunk in _chunks(unreadIds)) {
          await (db.update(db.messages)..where((m) => m.id.isIn(chunk)))
              .write(MessagesCompanion(status: Value(MessageStatus.read.name)));
        }
        if (!await crypto.hasSession(chatId)) return;
        for (final chunk in _chunks(unreadIds)) {
          await outbound.enqueue(chatId, ReceiptPayload(ids: chunk, read: true));
        }
      });

  Future<void> sendDeliveryReceipts(Map<String, List<String>> idsByChat) => db.transaction(() async {
        for (final entry in idsByChat.entries) {
          if (entry.value.isEmpty || !await crypto.hasSession(entry.key)) continue;
          for (final chunk in _chunks(entry.value)) {
            await outbound.enqueue(entry.key, ReceiptPayload(ids: chunk, read: false));
          }
        }
      });

  /// Turns ids collected by the expiry sweep into encrypted delete commands.
  /// Ids for a chat without a session stay queued until one exists.
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

  /// Chats with expired messages whose deletion still has to be relayed.
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
        await (db.update(db.chats)..where((c) => c.peerId.equals(peer.userId))).write(
          ChatsCompanion(
            peerIdentityKey: Value(peer.identityKey),
            peerSigningKey: Value(peer.signingKey),
          ),
        );
        await _notice(peer.userId, 'Your security code with ${chat.peerUsername} changed.', now);
        return true;
      });

  /// Content-free message that sets up (or repairs) the Olm session.
  Future<void> sendHello(String peerId) =>
      db.transaction(() => outbound.enqueue(peerId, const HelloPayload()));

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
          if (chat != null && env.type == 'message') {
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
          if (sender == null || sender.userId != env.senderId) {
            return finish(const IncomingOutcome.skipped());
          }
          await db.into(db.chats).insert(
                ChatsCompanion.insert(
                  peerId: sender.userId,
                  peerUsername: sender.username,
                  peerIdentityKey: sender.identityKey,
                  peerSigningKey: sender.signingKey,
                  createdAt: now,
                  lastActivityAt: now,
                ),
              );
          chat = (await db.chatById(sender.userId))!;
        } else if (sender != null &&
            wire.olmType == 0 &&
            sender.identityKey != chat.peerIdentityKey) {
          // The new session was set up with a new identity key: the peer
          // reinstalled the app or signed in on another phone.
          await (db.update(db.chats)..where((c) => c.peerId.equals(env.senderId))).write(
            ChatsCompanion(
              peerIdentityKey: Value(sender.identityKey),
              peerSigningKey: Value(sender.signingKey),
            ),
          );
          await _notice(chat.peerId, 'Your security code with ${chat.peerUsername} changed.', now);
        }

        final outcome = await _apply(chat, payload, now);
        return finish(outcome);
      });

  Future<IncomingOutcome> _apply(Chat chat, Payload payload, int now) async {
    switch (payload) {
      case TextPayload(:final id, :final body, :final sentAt, :final ttlSeconds):
        final wipedBefore = chat.wipedBefore;
        if (wipedBefore != null && sentAt <= wipedBefore) return const IncomingOutcome.skipped();
        final ttl = ttlSeconds == null ? null : min(ttlSeconds, maxTimerSeconds);
        // Countdown from the moment it was sent (never later than "now").
        final expiresAt = ttl == null ? null : min(sentAt, now) + ttl * 1000;
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
              ),
              mode: InsertMode.insertOrIgnore,
            );
        await db.touchChat(chat.peerId, now);
        return IncomingOutcome.delivered(chat.peerId, id);

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
        // The author relays deletions of their own expired messages only.
        for (final chunk in _chunks(deleteIds)) {
          await (db.delete(db.messages)
                ..where((m) => m.chatId.equals(chat.peerId) & m.fromMe.equals(false) & m.id.isIn(chunk)))
              .go();
        }
        return const IncomingOutcome.skipped();

      case WipePayload(:final before):
        // Silent: the conversation disappears exactly as on the sender's phone.
        await db.deleteAllMessagesOf(chat.peerId);
        await (db.delete(db.pendingDeletes)..where((p) => p.chatId.equals(chat.peerId))).go();
        await db.dropOutboxFor(chat.peerId, const ['message', 'delete']);
        final previous = chat.wipedBefore ?? 0;
        await (db.update(db.chats)..where((c) => c.peerId.equals(chat.peerId)))
            .write(ChatsCompanion(wipedBefore: Value(max(previous, before))));
        return const IncomingOutcome.skipped();

      case TimerPayload(:final seconds, :final changedAt):
        if (!isOfferedTimer(seconds) || changedAt <= chat.timerChangedAt) {
          return const IncomingOutcome.skipped();
        }
        // A peer's choice is always applied, even beyond this device's free
        // limit: refusing it would keep their messages longer than they asked.
        await (db.update(db.chats)..where((c) => c.peerId.equals(chat.peerId)))
            .write(ChatsCompanion(timerSeconds: Value(seconds), timerChangedAt: Value(changedAt)));
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

  static Iterable<List<String>> _chunks(List<String> items) sync* {
    for (var i = 0; i < items.length; i += _idsPerEnvelope) {
      yield items.sublist(i, min(i + _idsPerEnvelope, items.length));
    }
  }
}
