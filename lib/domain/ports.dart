import 'models.dart';
import 'payload.dart';

/// Argon2id password verifiers (PHC strings with a random salt each).
abstract interface class PasswordHasher {
  Future<String> hash(String password);

  /// `true` when [password] matches [encoded]. Never throws.
  Future<bool> verify(String encoded, String password);
}

/// Small key/value store for local settings (backed by the encrypted DB).
abstract interface class LocalSettings {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// End-to-end session crypto. Production: vodozemac (Olm / Double Ratchet).
///
/// All state lives in the encrypted local database and is loaded and saved
/// inside the caller's database transaction, so a crash can never leave a
/// ratchet half-advanced.
abstract interface class E2eCrypto {
  /// Creates a new device identity with [oneTimeKeys] signed one-time keys and
  /// a signed fallback key. Keys stay "unpublished" until [markPublished].
  Future<KeyUpload> createIdentity({required int oneTimeKeys});

  /// Generates [count] more signed one-time keys (and, optionally, a fresh
  /// fallback key) for upload.
  Future<KeyUpload> generateKeys({required int count, bool rotateFallback = false});

  /// Marks every generated key as uploaded to the server.
  Future<void> markPublished();

  /// Ed25519 identity key of this device (base64).
  Future<String> signingKey();

  /// Curve25519 identity key of this device (base64). The server uses it to
  /// tell the account's current phone from a replaced one.
  Future<String> identityKey();

  Future<bool> hasSession(String peerId);

  /// Verifies the signature on [key] with the peer's Ed25519 key and creates
  /// a new outbound session (X3DH-style handshake). Throws on a bad signature.
  Future<void> startSession(PeerKeys peer, ClaimedKey key);

  /// Encrypts for the most recently used session with [peerId].
  /// Throws [NoSessionException] when there is none.
  Future<WireEnvelope> encrypt(String peerId, String plaintext);

  /// Decrypts with an existing session, or creates an inbound session from a
  /// pre-key message using [peerIdentityKey]. Throws on failure; failed
  /// attempts never change stored state.
  Future<String> decrypt(String peerId, String? peerIdentityKey, WireEnvelope envelope);
}

class NoSessionException implements Exception {
  const NoSessionException();
}

/// An encrypted envelope waiting on the relay.
class IncomingEnvelope {
  const IncomingEnvelope({
    required this.id,
    required this.senderId,
    required this.type,
    required this.ciphertext,
  });

  final String id;
  final String senderId;
  final String type;
  final String ciphertext;
}

class OutgoingEnvelope {
  const OutgoingEnvelope({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.ciphertext,
    this.expiresAtMs,
  });

  final String id;
  final String recipientId;
  final String type;
  final String ciphertext;
  final int? expiresAtMs;
}

/// The recipient no longer exists on the server (account deleted).
class RecipientGoneException implements Exception {
  const RecipientGoneException();
}

/// The account registered new keys on another phone; this phone may no longer
/// send or receive (one phone per account).
class DeviceReplacedException implements Exception {
  const DeviceReplacedException();
}

/// Transient encrypted relay (Supabase table `relay`).
abstract interface class RelayApi {
  Future<List<IncomingEnvelope>> fetchPending({int limit = 100});

  /// Deletes delivered envelopes from the server.
  Future<void> acknowledge(List<String> ids);

  /// Idempotent: re-sending an id that is already queued is a no-op.
  Future<void> send(OutgoingEnvelope envelope);

  /// Best effort content-free wake-up push for the given envelopes.
  Future<void> requestPush(List<String> relayIds);
}

/// Username directory and public-key store.
abstract interface class DirectoryApi {
  Future<PeerKeys?> lookupUsername(String username);
  Future<PeerKeys?> getUser(String userId);
  Future<ClaimedKey?> claimOneTimeKey(String userId);

  /// Uploads keys; returns how many one-time keys the server now holds.
  Future<int> uploadKeys(List<SignedKey> oneTimeKeys, {SignedKey? fallbackKey});
}
