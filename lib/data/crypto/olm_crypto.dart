import 'package:drift/drift.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../../core/clock.dart';
import '../../domain/models.dart';
import '../../domain/payload.dart';
import '../../domain/ports.dart';
import '../local/app_database.dart';

/// [E2eCrypto] backed by vodozemac, Matrix's audited Rust implementation of
/// Olm (Double Ratchet with a triple Diffie-Hellman handshake).
///
/// Only vodozemac's high-level API is used: Account, Session, signatures and
/// encrypted pickles. Every operation loads state from the encrypted database,
/// mutates it, and stores it back; callers wrap related work in a database
/// transaction so state changes are atomic with the messages they produce.
class OlmCrypto implements E2eCrypto {
  OlmCrypto({required this.db, required this.pickleKey, required this.clock});

  final AppDatabase db;
  final Clock clock;

  /// Encrypts the pickled account and sessions (inside the encrypted DB).
  final Uint8List pickleKey;

  static const _accountKey = 'olm.account';
  static const _maxSessionsPerPeer = 3;

  Future<vod.Account> _loadAccount() async {
    final pickle = await db.read(_accountKey);
    if (pickle == null) throw StateError('no Olm account on this device');
    return vod.Account.fromPickleEncrypted(pickle: pickle, pickleKey: pickleKey);
  }

  Future<void> _saveAccount(vod.Account account) =>
      db.write(_accountKey, account.toPickleEncrypted(pickleKey));

  SignedKey _sign(vod.Account account, String keyId, vod.Curve25519PublicKey key) {
    final b64 = key.toBase64();
    return SignedKey(id: keyId, key: b64, signature: account.sign(signedKeyMessage(b64)).toBase64());
  }

  List<SignedKey> _unpublishedOneTimeKeys(vod.Account account) => [
        for (final entry in account.oneTimeKeys.entries) _sign(account, entry.key, entry.value),
      ];

  SignedKey? _unpublishedFallback(vod.Account account) {
    final fallback = account.fallbackKey;
    if (fallback.isEmpty) return null;
    final entry = fallback.entries.first;
    return _sign(account, entry.key, entry.value);
  }

  @override
  Future<KeyUpload> createIdentity({required int oneTimeKeys}) async {
    final account = vod.Account();
    final count = oneTimeKeys.clamp(1, account.maxNumberOfOneTimeKeys);
    account.generateOneTimeKeys(count);
    account.generateFallbackKey();
    final upload = KeyUpload(
      identityKey: account.curve25519Key.toBase64(),
      signingKey: account.ed25519Key.toBase64(),
      oneTimeKeys: _unpublishedOneTimeKeys(account),
      fallbackKey: _unpublishedFallback(account),
    );
    await db.transaction(() async {
      await (db.delete(db.olmSessions)).go();
      await _saveAccount(account);
    });
    _identityKeyCache = upload.identityKey;
    return upload;
  }

  @override
  Future<KeyUpload> generateKeys({required int count, bool rotateFallback = false}) async {
    final account = await _loadAccount();
    if (count > 0) account.generateOneTimeKeys(count.clamp(1, account.maxNumberOfOneTimeKeys));
    if (rotateFallback) account.generateFallbackKey();
    await _saveAccount(account);
    return KeyUpload(
      identityKey: account.curve25519Key.toBase64(),
      signingKey: account.ed25519Key.toBase64(),
      oneTimeKeys: _unpublishedOneTimeKeys(account),
      fallbackKey: _unpublishedFallback(account),
    );
  }

  @override
  Future<void> markPublished() async {
    final account = await _loadAccount();
    account.markKeysAsPublished();
    await _saveAccount(account);
  }

  @override
  Future<String> signingKey() async => (await _loadAccount()).ed25519Key.toBase64();

  String? _identityKeyCache;

  @override
  Future<String> identityKey() async =>
      _identityKeyCache ??= (await _loadAccount()).curve25519Key.toBase64();

  Future<List<OlmSession>> _sessionsFor(String peerId) => (db.select(db.olmSessions)
        ..where((s) => s.peerId.equals(peerId))
        ..orderBy([(s) => OrderingTerm.desc(s.lastUsedAt)]))
      .get();

  Future<void> _storeSession(String peerId, vod.Session session) async {
    await db.into(db.olmSessions).insertOnConflictUpdate(
          OlmSessionsCompanion.insert(
            sessionId: session.sessionId,
            peerId: peerId,
            pickle: session.toPickleEncrypted(pickleKey),
            lastUsedAt: clock.nowMs(),
          ),
        );
    final all = await _sessionsFor(peerId);
    if (all.length > _maxSessionsPerPeer) {
      final stale = all.skip(_maxSessionsPerPeer).map((s) => s.sessionId).toList();
      await (db.delete(db.olmSessions)..where((s) => s.sessionId.isIn(stale))).go();
    }
  }

  @override
  Future<bool> hasSession(String peerId) async => (await _sessionsFor(peerId)).isNotEmpty;

  @override
  Future<void> startSession(PeerKeys peer, ClaimedKey key) async {
    // The server could hand out a key of its own; the signature binds the key
    // to the peer's Ed25519 identity (which is pinned on first contact).
    vod.Ed25519PublicKey.fromBase64(peer.signingKey).verify(
      message: signedKeyMessage(key.publicKey),
      signature: vod.Ed25519Signature.fromBase64(key.signature),
    );
    final account = await _loadAccount();
    final session = account.createOutboundSession(
      identityKey: vod.Curve25519PublicKey.fromBase64(peer.identityKey),
      oneTimeKey: vod.Curve25519PublicKey.fromBase64(key.publicKey),
    );
    await _storeSession(peer.userId, session);
  }

  @override
  Future<WireEnvelope> encrypt(String peerId, String plaintext) async {
    final rows = await _sessionsFor(peerId);
    if (rows.isEmpty) throw const NoSessionException();
    final session = vod.Session.fromPickleEncrypted(pickle: rows.first.pickle, pickleKey: pickleKey);
    final encrypted = session.encrypt(plaintext);
    await _storeSession(peerId, session);
    return WireEnvelope(olmType: encrypted.messageType, body: encrypted.ciphertext);
  }

  @override
  Future<String> decrypt(String peerId, String? peerIdentityKey, WireEnvelope envelope) async {
    // Existing sessions first (newest first). Each attempt works on a freshly
    // unpickled copy, so a failed attempt never touches stored state.
    for (final row in await _sessionsFor(peerId)) {
      final session = vod.Session.fromPickleEncrypted(pickle: row.pickle, pickleKey: pickleKey);
      try {
        final plaintext = session.decrypt(messageType: envelope.olmType, ciphertext: envelope.body);
        await _storeSession(peerId, session);
        return plaintext;
      } on Object {
        continue;
      }
    }
    if (envelope.olmType != 0 || peerIdentityKey == null) {
      throw StateError('no session can decrypt this message');
    }
    // A pre-key message that starts a new session. vodozemac checks that the
    // identity key inside the message matches [peerIdentityKey] and removes
    // the one-time key it used from the account.
    final account = await _loadAccount();
    final inbound = account.createInboundSession(
      theirIdentityKey: vod.Curve25519PublicKey.fromBase64(peerIdentityKey),
      preKeyMessageBase64: envelope.body,
    );
    await _storeSession(peerId, inbound.session);
    await _saveAccount(account);
    return inbound.plaintext;
  }
}
