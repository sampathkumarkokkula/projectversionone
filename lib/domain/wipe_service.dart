import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/log.dart';
import '../data/local/app_database.dart';
import 'models.dart';
import 'outbound.dart';
import 'payload.dart';
import 'ports.dart';

/// Deletes the conversations the user selected (Settings > Chats erased by
/// the secondary password).
///
/// * [duressWipe] runs right after an unlock with the secondary password:
///   local deletion plus an authenticated (end-to-end-encrypted) wipe command
///   to each affected peer, queued in the outbox and relayed when online. The
///   server holds it until the peer's app collects it. If no Olm session with
///   a peer exists yet (for example right after this phone got new keys), the
///   command is remembered and the sync engine sends it as soon as it has set
///   up a session.
/// * [wipeBeforePasswordReset] runs before any "forgot password" reset so a
///   reset cannot be used to get around the secondary password.
///
/// The chat entries stay, only the conversations go.
///
/// The selection screen never shows the real selection inside a session that
/// was unlocked with the secondary password: there it shows (and edits) a
/// separate decoy selection that has no effect, so the person holding the
/// phone cannot see which chats were protected.
class WipeService {
  WipeService({required this.db, required this.outbound, required this.clock});

  final AppDatabase db;
  final Outbound outbound;
  final Clock clock;

  static const _pendingPrefix = 'wipe.pending.';
  static const _decoyKey = 'wipe.decoy';

  /// Ids of the chats shown as selected in a session unlocked with [mode].
  Future<Set<String>> selectedChats(UnlockMode mode) async {
    if (mode == UnlockMode.duress) {
      final raw = await db.read(_decoyKey);
      if (raw == null) return {};
      try {
        return {for (final v in jsonDecode(raw) as List<dynamic>) if (v is String) v};
      } on FormatException {
        return {};
      }
    }
    return {for (final c in await db.chatsErasedWithSecondary()) c.peerId};
  }

  Future<void> setSelected(String peerId, {required bool selected, required UnlockMode mode}) async {
    if (mode == UnlockMode.duress) {
      final ids = await selectedChats(mode);
      selected ? ids.add(peerId) : ids.remove(peerId);
      await db.write(_decoyKey, jsonEncode(ids.toList()));
      return;
    }
    await db.setEraseWithSecondary(peerId, selected);
  }

  Future<int> duressWipe() => _wipeAndCheckpoint(relayToPeers: true);

  Future<int> wipeBeforePasswordReset() => _wipeAndCheckpoint(relayToPeers: false);

  Future<int> _wipeAndCheckpoint({required bool relayToPeers}) async {
    final count = await _wipeSelectedChats(relayToPeers: relayToPeers);
    try {
      // Make sure deleted pages are not left behind in the write-ahead log.
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } on Object {
      logDebug('wipe: checkpoint skipped');
    }
    return count;
  }

  Future<int> _wipeSelectedChats({required bool relayToPeers}) => db.transaction(() async {
        final now = clock.nowMs();
        final chats = await db.chatsErasedWithSecondary();
        for (final chat in chats) {
          // Photos are deleted with their messages; half-received ones too.
          await db.deleteAllMessagesOf(chat.peerId);
          await db.deletePartsOfChat(chat.peerId);
          await (db.delete(db.pendingDeletes)..where((p) => p.chatId.equals(chat.peerId))).go();
          // Unsent messages of this chat must not leave the device any more.
          await db.dropOutboxFor(chat.peerId, const ['message', 'delete']);
          final previous = chat.wipedBefore ?? 0;
          await (db.update(db.chats)..where((c) => c.peerId.equals(chat.peerId)))
              .write(ChatsCompanion(wipedBefore: Value(max(now, previous))));
          if (relayToPeers) {
            try {
              await outbound.enqueue(chat.peerId, WipePayload(before: now));
            } on NoSessionException {
              await db.write('$_pendingPrefix${chat.peerId}', '$now');
            }
          }
        }
        return chats.length;
      });

  /// Wipe commands waiting for a session: peer id -> wipe time.
  Future<Map<String, int>> pendingWipes() async {
    final rows = await db.valuesWithPrefix(_pendingPrefix);
    return {
      for (final r in rows) r.key.substring(_pendingPrefix.length): int.tryParse(r.value) ?? clock.nowMs(),
    };
  }

  Future<void> forgetPendingWipe(String peerId) => db.remove('$_pendingPrefix$peerId');

  /// Queues every remembered wipe command whose session now exists.
  Future<void> queuePendingWipes() async {
    for (final entry in (await pendingWipes()).entries) {
      try {
        await db.transaction(() async {
          await outbound.enqueue(entry.key, WipePayload(before: entry.value));
          await db.remove('$_pendingPrefix${entry.key}');
        });
      } on NoSessionException {
        // Still no session; the sync engine keeps trying.
      }
    }
  }
}
