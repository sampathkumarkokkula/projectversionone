import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../data/local/app_database.dart';
import 'payload.dart';
import 'ports.dart';

/// Encrypts payloads for a peer and queues them in the local outbox.
///
/// Encryption happens at enqueue time inside the caller's transaction, so the
/// ratchet step and the queued ciphertext are committed together and retries
/// re-send the exact same bytes. The outbox is flushed by the sync engine
/// whenever the relay is reachable (offline queue).
class Outbound {
  Outbound({required this.db, required this.crypto, required this.clock, required this.ids});

  final AppDatabase db;
  final E2eCrypto crypto;
  final Clock clock;
  final IdGenerator ids;

  /// Returns the relay id of the queued envelope.
  Future<String> enqueue(
    String peerId,
    Payload payload, {
    String? messageId,
    int? expiresAtMs,
  }) async {
    final wire = await crypto.encrypt(peerId, payload.encode());
    final id = ids.newId();
    await db.into(db.outbox).insert(
          OutboxCompanion.insert(
            id: id,
            recipientId: peerId,
            type: payload.relayType,
            envelope: wire.encode(),
            push: payload.wantsPush,
            createdAt: clock.nowMs(),
            messageId: Value(messageId),
            expiresAt: Value(expiresAtMs),
          ),
        );
    return id;
  }
}
