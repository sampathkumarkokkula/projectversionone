import 'dart:convert';
import 'dart:io';

import 'package:bvm/core/clock.dart';
import 'package:bvm/core/ids.dart';
import 'package:bvm/data/local/app_database.dart';
import 'package:bvm/domain/message_service.dart';
import 'package:bvm/domain/models.dart';
import 'package:bvm/domain/outbound.dart';
import 'package:bvm/domain/payload.dart';
import 'package:bvm/domain/ports.dart';
import 'package:bvm/domain/session_establisher.dart';
import 'package:bvm/domain/sync_engine.dart';
import 'package:bvm/domain/wipe_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Settable wall clock.
class FakeClock implements Clock {
  FakeClock(this.now);

  int now;

  @override
  int nowMs() => now;

  void advance(Duration d) => now += d.inMilliseconds;
}

/// In-memory database (same schema and SQL as production). Tests simulate
/// several phones, each with its own database, which is intended here.
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Stand-in for Olm in tests that are about app logic, not cryptography.
/// The "ciphertext" records who it was addressed to, so a test can check that
/// a wipe command is end-to-end addressed to the right peer.
class FakeCrypto implements E2eCrypto {
  final Set<String> sessions = {};

  @override
  Future<KeyUpload> createIdentity({required int oneTimeKeys}) async =>
      const KeyUpload(identityKey: 'id-key', signingKey: 'sign-key', oneTimeKeys: []);

  @override
  Future<KeyUpload> generateKeys({required int count, bool rotateFallback = false}) async =>
      const KeyUpload(identityKey: 'id-key', signingKey: 'sign-key', oneTimeKeys: []);

  @override
  Future<void> markPublished() async {}

  @override
  Future<String> signingKey() async => 'sign-key';

  @override
  Future<String> identityKey() async => 'id-key';

  @override
  Future<bool> hasSession(String peerId) async => sessions.contains(peerId);

  @override
  Future<void> startSession(PeerKeys peer, ClaimedKey key) async => sessions.add(peer.userId);

  @override
  Future<WireEnvelope> encrypt(String peerId, String plaintext) async {
    if (!sessions.contains(peerId)) throw const NoSessionException();
    final body = base64Encode(utf8.encode(jsonEncode({'to': peerId, 'pt': plaintext})));
    return WireEnvelope(olmType: 1, body: body);
  }

  @override
  Future<String> decrypt(String peerId, String? peerIdentityKey, WireEnvelope envelope) async {
    final map = jsonDecode(utf8.decode(base64Decode(envelope.body))) as Map<String, dynamic>;
    sessions.add(peerId);
    return map['pt'] as String;
  }

  /// Test helper: the payload inside a queued envelope.
  static ({String to, Payload payload}) open(String wire) {
    final envelope = WireEnvelope.tryParse(wire)!;
    final map = jsonDecode(utf8.decode(base64Decode(envelope.body))) as Map<String, dynamic>;
    return (to: map['to'] as String, payload: Payload.decode(map['pt'] as String));
  }
}

class RelayRow {
  RelayRow(this.id, this.recipientId, this.senderId, this.type, this.ciphertext);

  final String id;
  final String recipientId;
  final String senderId;
  final String type;
  final String ciphertext;
}

/// In-memory version of the Supabase relay table, shared by several devices.
class FakeRelayServer {
  final List<RelayRow> rows = [];
  final List<String> pushRequests = [];
  bool online = true;

  RelayApi clientFor(String userId) => _RelayClient(this, userId);
}

class _RelayClient implements RelayApi {
  _RelayClient(this.server, this.userId);

  final FakeRelayServer server;
  final String userId;

  void _requireOnline() {
    if (!server.online) throw const SocketException('offline (test)');
  }

  @override
  Future<List<IncomingEnvelope>> fetchPending({int limit = 100}) async {
    _requireOnline();
    return [
      for (final r in server.rows.where((r) => r.recipientId == userId).take(limit))
        IncomingEnvelope(id: r.id, senderId: r.senderId, type: r.type, ciphertext: r.ciphertext),
    ];
  }

  @override
  Future<void> acknowledge(List<String> ids) async {
    _requireOnline();
    server.rows.removeWhere((r) => r.recipientId == userId && ids.contains(r.id));
  }

  @override
  Future<void> send(OutgoingEnvelope envelope) async {
    _requireOnline();
    if (server.rows.any((r) => r.id == envelope.id)) return;
    server.rows.add(RelayRow(envelope.id, envelope.recipientId, userId, envelope.type, envelope.ciphertext));
  }

  @override
  Future<void> requestPush(List<String> relayIds) async => server.pushRequests.addAll(relayIds);
}

/// In-memory directory. Shares the "online" switch of [server] when given.
class FakeDirectory implements DirectoryApi {
  FakeDirectory([this.server]);

  final FakeRelayServer? server;
  final Map<String, PeerKeys> users = {};

  void add(PeerKeys peer) => users[peer.userId] = peer;

  void _requireOnline() {
    if (server?.online == false) throw const SocketException('offline (test)');
  }

  @override
  Future<PeerKeys?> getUser(String userId) async {
    _requireOnline();
    return users[userId];
  }

  @override
  Future<PeerKeys?> lookupUsername(String username) async {
    _requireOnline();
    for (final u in users.values) {
      if (u.username == username) return u;
    }
    return null;
  }

  @override
  Future<ClaimedKey?> claimOneTimeKey(String userId) async {
    _requireOnline();
    return const ClaimedKey(keyId: 'k1', publicKey: 'otk', signature: 'sig', isFallback: false);
  }

  @override
  Future<int> uploadKeys(List<SignedKey> oneTimeKeys, {SignedKey? fallbackKey}) async {
    _requireOnline();
    return 50;
  }
}

PeerKeys peer(String id) => PeerKeys(userId: id, username: id, identityKey: 'ik-$id', signingKey: 'sk-$id');

/// One simulated phone: database, fake crypto and the real domain services.
class Device {
  Device(this.userId, FakeRelayServer server, FakeDirectory directory, this.clock) {
    db = memoryDatabase();
    crypto = FakeCrypto();
    final ids = UuidV4Generator();
    outbound = Outbound(db: db, crypto: crypto, clock: clock, ids: ids);
    messages = MessageService(db: db, crypto: crypto, outbound: outbound, clock: clock, ids: ids);
    wipe = WipeService(db: db, outbound: outbound, clock: clock);
    sessions = SessionEstablisher(db: db, directory: directory, crypto: crypto, messages: messages);
    sync = SyncEngine(
      db: db,
      relay: server.clientFor(userId),
      directory: directory,
      messages: messages,
      sessions: sessions,
      wipe: wipe,
      clock: clock,
    );
  }

  final String userId;
  final Clock clock;
  late final AppDatabase db;
  late final FakeCrypto crypto;
  late final Outbound outbound;
  late final MessageService messages;
  late final WipeService wipe;
  late final SessionEstablisher sessions;
  late final SyncEngine sync;

  /// Creates a chat with an established session.
  Future<void> connect(String peerId, {int? timerSeconds}) async {
    crypto.sessions.add(peerId);
    await messages.ensureChat(peer(peerId));
    if (timerSeconds != null) {
      await (db.update(db.chats)..where((c) => c.peerId.equals(peerId)))
          .write(ChatsCompanion(timerSeconds: Value(timerSeconds)));
    }
  }

  Future<List<Message>> messagesWith(String peerId) =>
      (db.select(db.messages)..where((m) => m.chatId.equals(peerId))).get();

  Future<List<OutboxEntry>> outbox() => db.select(db.outbox).get();

  Future<void> close() => db.close();
}
