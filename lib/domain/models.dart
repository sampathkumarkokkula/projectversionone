/// Outcome of checking a typed password against the two local verifiers.
enum UnlockResult {
  /// Main password: normal unlock.
  normal,

  /// Secondary (duress) password: unlock that looks identical, but wipes
  /// every chat that has an auto-delete timer (here and on the peer's phone).
  duress,

  /// Neither verifier matched.
  invalid,
}

/// Which password the current (in-memory only) session was unlocked with.
enum UnlockMode { normal, duress }

/// Kind of a locally stored chat item.
enum MessageKind { text, system }

/// Delivery state.
///
/// Outgoing: pending -> sent -> delivered -> read (or failed).
/// Incoming: received -> read.
enum MessageStatus { pending, sent, delivered, read, received, failed }

extension MessageStatusRank on MessageStatus {
  /// Ordering used so a late "delivered" receipt never downgrades "read".
  int get rank => switch (this) {
        MessageStatus.pending => 0,
        MessageStatus.failed => 0,
        MessageStatus.sent => 1,
        MessageStatus.delivered => 2,
        MessageStatus.received => 2,
        MessageStatus.read => 3,
      };
}

MessageStatus parseStatus(String value) => MessageStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MessageStatus.pending,
    );

/// Public directory entry of another user, as returned by the server.
class PeerKeys {
  const PeerKeys({
    required this.userId,
    required this.username,
    required this.identityKey,
    required this.signingKey,
  });

  final String userId;
  final String username;

  /// Curve25519 identity key (base64).
  final String identityKey;

  /// Ed25519 identity key (base64).
  final String signingKey;
}

/// A one-time key (or the fallback key) handed out by the server.
class ClaimedKey {
  const ClaimedKey({
    required this.keyId,
    required this.publicKey,
    required this.signature,
    required this.isFallback,
  });

  final String keyId;
  final String publicKey;
  final String signature;
  final bool isFallback;
}

/// A public key signed with this device's Ed25519 identity key.
class SignedKey {
  const SignedKey({required this.id, required this.key, required this.signature});

  final String id;
  final String key;
  final String signature;

  Map<String, String> toJson() => {'id': id, 'key': key, 'sig': signature};
}

/// Public key material to publish for this device.
class KeyUpload {
  const KeyUpload({
    required this.identityKey,
    required this.signingKey,
    required this.oneTimeKeys,
    this.fallbackKey,
  });

  final String identityKey;
  final String signingKey;
  final List<SignedKey> oneTimeKeys;
  final SignedKey? fallbackKey;
}

/// The signed-key message format shared by uploader and claimer.
String signedKeyMessage(String publicKey) => 'bvm-key-v1:$publicKey';
