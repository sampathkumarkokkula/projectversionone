import 'dart:async';

import '../core/clock.dart';
import '../core/log.dart';
import '../data/local/app_database.dart';
import 'message_service.dart';
import 'models.dart';
import 'ports.dart';
import 'session_establisher.dart';
import 'wipe_service.dart';

/// Moves encrypted envelopes between the local outbox/inbox and the relay.
///
/// One sync pass: set up missing sessions for queued wipe/delete commands ->
/// queue those commands -> pull and process incoming envelopes (then
/// acknowledge, which deletes them from the server) -> repair broken
/// sessions -> flush the outbox. Passes never overlap.
///
/// Throws [DeviceReplacedException] when the account now lives on another
/// phone; every other failure just ends the pass (the next one retries).
class SyncEngine {
  SyncEngine({
    required this.db,
    required this.relay,
    required this.directory,
    required this.messages,
    required this.sessions,
    required this.wipe,
    required this.clock,
  });

  final AppDatabase db;
  final RelayApi relay;
  final DirectoryApi directory;
  final MessageService messages;
  final SessionEstablisher sessions;
  final WipeService wipe;
  final Clock clock;

  Future<void>? _running;
  bool _again = false;

  /// Runs a sync pass; if one is running, schedules exactly one more.
  Future<void> sync() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final pass = _loop();
    _running = pass;
    return pass;
  }

  Future<void> _loop() async {
    try {
      do {
        _again = false;
        await _passOnce();
      } while (_again);
    } finally {
      _running = null;
    }
  }

  Future<void> _passOnce() async {
    try {
      await _deliverPendingCommands();
      await _pull();
      await _repairSessions();
    } on DeviceReplacedException {
      rethrow;
    } on Object catch (e) {
      logDebug('sync: receive step failed (${e.runtimeType})');
    }
    await flushOutbox();
  }

  /// Wipe and delete commands can only be encrypted once a session exists.
  /// Set up the missing ones (network), then queue the commands.
  Future<void> _deliverPendingCommands() async {
    final pendingWipes = await wipe.pendingWipes();
    final peers = {...pendingWipes.keys, ...await messages.pendingDeletePeers()};
    for (final peerId in peers) {
      try {
        await sessions.ensure(peerId);
      } on PeerGoneException {
        // Nobody left to tell; the commands are dropped below.
        await wipe.forgetPendingWipe(peerId);
        await messages.dropPendingDeletes(peerId);
      } on PeerUnavailableException {
        // Retry on a later pass.
      } on DeviceReplacedException {
        rethrow;
      } on Object catch (e) {
        // Offline or a server error: retry on a later pass, and never let one
        // peer block receiving for everyone else.
        logDebug('sync: session setup for a pending command failed (${e.runtimeType})');
      }
    }
    await wipe.queuePendingWipes();
    await messages.relayPendingDeletes();
  }

  Future<void> _pull() async {
    for (var round = 0; round < 20; round++) {
      final batch = await relay.fetchPending(limit: 100);
      if (batch.isEmpty) return;
      final handled = <String>[];
      final delivered = <String, List<String>>{};
      final senders = <String, PeerKeys?>{};
      try {
        for (final env in batch) {
          PeerKeys? sender;
          if (await messages.needsDirectory(env)) {
            if (!senders.containsKey(env.senderId)) {
              senders[env.senderId] = await directory.getUser(env.senderId);
            }
            sender = senders[env.senderId];
          }
          final outcome = await messages.handleIncoming(env, sender: sender);
          handled.add(env.id);
          final chatId = outcome.chatId;
          final messageId = outcome.deliveredMessageId;
          if (chatId != null && messageId != null) {
            delivered.putIfAbsent(chatId, () => []).add(messageId);
          }
        }
      } finally {
        if (delivered.isNotEmpty) await messages.sendDeliveryReceipts(delivered);
        // Delete from the server only what is safely stored on this phone.
        if (handled.isNotEmpty) await relay.acknowledge(handled);
      }
      if (batch.length < 100) return;
    }
  }

  /// A peer whose messages could not be decrypted gets a fresh session and a
  /// content-free hello, so their next messages decrypt again.
  Future<void> _repairSessions() async {
    for (final peerId in await messages.peersNeedingRepair()) {
      try {
        await sessions.ensure(peerId, force: true);
        await messages.sendHello(peerId);
        await messages.repairDone(peerId);
      } on PeerGoneException {
        await messages.repairDone(peerId);
      } on PeerUnavailableException {
        // Retry on a later pass.
      }
    }
  }

  /// Hands queued envelopes to the relay, oldest first. Stops at the first
  /// network failure so ordering is preserved; the rest stays queued.
  Future<void> flushOutbox() async {
    final pushIds = <String>[];
    try {
      final entries = await db.outboxInOrder();
      for (final entry in entries) {
        final expiresAt = entry.expiresAt;
        if (expiresAt != null && expiresAt <= clock.nowMs()) {
          // Already expired on this phone: never deliver it.
          await db.removeOutbox(entry.id);
          continue;
        }
        try {
          await relay.send(
            OutgoingEnvelope(
              id: entry.id,
              recipientId: entry.recipientId,
              type: entry.type,
              ciphertext: entry.envelope,
              expiresAtMs: expiresAt,
            ),
          );
        } on RecipientGoneException {
          await db.removeOutbox(entry.id);
          final messageId = entry.messageId;
          if (messageId != null) await db.setStatus(messageId, MessageStatus.failed);
          continue;
        }
        await db.transaction(() async {
          await db.removeOutbox(entry.id);
          final messageId = entry.messageId;
          if (messageId != null) {
            final row = await (db.select(db.messages)..where((m) => m.id.equals(messageId))).getSingleOrNull();
            if (row != null && parseStatus(row.status) == MessageStatus.pending) {
              await db.setStatus(messageId, MessageStatus.sent);
            }
          }
        });
        if (entry.push) pushIds.add(entry.id);
      }
    } on DeviceReplacedException {
      rethrow;
    } on Object catch (e) {
      logDebug('sync: outbox flush stopped (${e.runtimeType})');
    } finally {
      if (pushIds.isNotEmpty) {
        try {
          await relay.requestPush(pushIds);
        } on Object {
          logDebug('sync: push request failed');
        }
      }
    }
  }
}
