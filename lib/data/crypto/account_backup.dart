import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:hashlib/hashlib.dart' show Argon2, Argon2Type, Argon2Version, sha256;

import '../../core/ids.dart';

/// Argon2id parameters for the backup keys. Stronger than the unlock
/// verifiers because the encrypted backup sits on a server.
class BackupKdfParams {
  const BackupKdfParams({this.memoryKiB = 32768, this.iterations = 3, this.parallelism = 1});

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, Object?> toJson() => {'m': memoryKiB, 't': iterations, 'p': parallelism};

  static BackupKdfParams? fromJson(Map<String, dynamic> j) {
    final m = j['m'];
    final t = j['t'];
    final p = j['p'];
    if (m is! int || t is! int || p is! int) return null;
    // Refuse absurd values from a tampered header (memory / CPU exhaustion).
    if (m < 8192 || m > 262144 || t < 1 || t > 10 || p < 1 || p > 4) return null;
    return BackupKdfParams(memoryKiB: m, iterations: t, parallelism: p);
  }
}

/// A 256-bit key for one backup copy, plus the salt it was derived with.
class SlotKey {
  const SlotKey({required this.salt, required this.key});

  final Uint8List salt;
  final Uint8List key;

  Map<String, Object?> toJson() => {'s': base64Encode(salt), 'k': base64Encode(key)};

  static SlotKey? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    try {
      final salt = base64Decode(value['s'] as String);
      final key = base64Decode(value['k'] as String);
      if (salt.length != 16 || key.length != 32) return null;
      return SlotKey(salt: salt, key: key);
    } on Object {
      return null;
    }
  }

  /// Random key nobody can derive (slot without a password).
  static SlotKey random() => SlotKey(salt: secureRandomBytes(16), key: secureRandomBytes(32));
}

/// Password-protected encryption of the account backup.
///
/// Each copy = public header (salt, Argon2id parameters, nonce) + AES-256-GCM
/// ciphertext of the padded JSON content. The key is Argon2id(password,
/// salt). Uses only the high-level AEAD API of package:cryptography and the
/// Argon2id implementation of package:hashlib; no primitives are built here.
abstract final class BackupCipher {
  static const BackupKdfParams params = BackupKdfParams();
  static final List<int> _aad = utf8.encode('bvm-account-backup-v1');
  static const int _padBlock = 8192;

  static Future<Uint8List> deriveKey(String password, Uint8List salt, BackupKdfParams p) {
    final pw = utf8.encode(password);
    return Isolate.run(() => Uint8List.fromList(Argon2(
          type: Argon2Type.argon2id,
          version: Argon2Version.v13,
          parallelism: p.parallelism,
          memorySizeKB: p.memoryKiB,
          iterations: p.iterations,
          hashLength: 32,
          salt: salt,
        ).convert(pw).bytes));
  }

  static Future<SlotKey> newSlotKey(String password) async {
    final salt = secureRandomBytes(16);
    return SlotKey(salt: salt, key: await deriveKey(password, salt, params));
  }

  /// Pads [content] to a multiple of 8 KB so the copy size reveals little.
  static Uint8List _pad(String content) {
    final bytes = utf8.encode(content);
    final total = ((bytes.length + 4) / _padBlock).ceil() * _padBlock;
    final out = Uint8List(total);
    ByteData.sublistView(out).setUint32(0, bytes.length);
    out.setRange(4, 4 + bytes.length, bytes);
    return out;
  }

  static String? _unpad(List<int> padded) {
    if (padded.length < 4) return null;
    final length = ByteData.sublistView(Uint8List.fromList(padded.sublist(0, 4))).getUint32(0);
    if (length > padded.length - 4) return null;
    return utf8.decode(padded.sublist(4, 4 + length));
  }

  static Future<String> encrypt(String content, SlotKey key) async {
    final algorithm = AesGcm.with256bits();
    final box = await algorithm.encrypt(
      _pad(content),
      secretKey: SecretKey(key.key),
      nonce: algorithm.newNonce(),
      aad: _aad,
    );
    return jsonEncode({
      'v': 1,
      's': base64Encode(key.salt),
      'kdf': params.toJson(),
      'n': base64Encode(box.nonce),
      'c': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  /// The header of a copy, or null when it is not a BVM backup copy.
  static ({Uint8List salt, BackupKdfParams params, Uint8List nonce, Uint8List cipher, Uint8List mac})? _parse(
      String copy) {
    try {
      final j = jsonDecode(copy);
      if (j is! Map<String, dynamic> || j['v'] != 1) return null;
      final p = BackupKdfParams.fromJson(j['kdf'] as Map<String, dynamic>);
      if (p == null) return null;
      return (
        salt: base64Decode(j['s'] as String),
        params: p,
        nonce: base64Decode(j['n'] as String),
        cipher: base64Decode(j['c'] as String),
        mac: base64Decode(j['mac'] as String),
      );
    } on Object {
      return null;
    }
  }

  /// Tries [password] on every copy (always deriving a key for each, so the
  /// time does not depend on which copy matches). Returns the content and the
  /// key of the copy that opened, or null.
  static Future<({String content, SlotKey key})?> open(List<String> copies, String password) async {
    ({String content, SlotKey key})? result;
    for (final copy in copies) {
      final h = _parse(copy);
      if (h == null) continue;
      final key = await deriveKey(password, h.salt, h.params);
      if (result != null) continue;
      try {
        final clear = await AesGcm.with256bits().decrypt(
          SecretBox(h.cipher, nonce: h.nonce, mac: Mac(h.mac)),
          secretKey: SecretKey(key),
          aad: _aad,
        );
        final content = _unpad(clear);
        if (content != null) result = (content: content, key: SlotKey(salt: h.salt, key: key));
      } on SecretBoxAuthenticationError {
        // Wrong password for this copy.
      }
    }
    return result;
  }

  /// Puts the two copies in random order, so their position says nothing.
  static List<String> shuffle(String a, String b) => Random.secure().nextBool() ? [a, b] : [b, a];

  static String hash(String content) => sha256.convert(utf8.encode(content)).hex();
}
