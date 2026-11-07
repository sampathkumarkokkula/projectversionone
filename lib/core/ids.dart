import 'dart:math';
import 'dart:typed_data';

/// Generates identifiers for messages, envelopes and relay rows.
abstract interface class IdGenerator {
  String newId();
}

/// Random (version 4) UUIDs from the platform CSPRNG.
final class UuidV4Generator implements IdGenerator {
  UuidV4Generator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String newId() {
    final b = Uint8List(16);
    for (var i = 0; i < b.length; i++) {
      b[i] = _random.nextInt(256);
    }
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Cryptographically secure random bytes from the platform CSPRNG.
Uint8List secureRandomBytes(int length) {
  final random = Random.secure();
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = random.nextInt(256);
  }
  return out;
}

/// Constant-time comparison of two byte sequences.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
