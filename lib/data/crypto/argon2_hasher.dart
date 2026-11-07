import 'dart:convert';
import 'dart:isolate';

import 'package:hashlib/codecs.dart' show fromCrypt;
import 'package:hashlib/hashlib.dart' show Argon2, Argon2Type, Argon2Version;

import '../../core/ids.dart';
import '../../domain/ports.dart';

/// Argon2id password verifiers via `hashlib` (pure Dart, RFC 9106 test
/// vectors). Output is a standard PHC string:
/// `$argon2id$v=19$m=19456,t=2,p=1$<salt>$<hash>`.
///
/// Defaults follow the OWASP recommendation (19 MiB, 2 passes, 1 lane). The
/// parameters are stored inside each PHC string, so they can be raised later
/// without breaking existing verifiers. Work runs on a separate isolate.
class Argon2idHasher implements PasswordHasher {
  const Argon2idHasher({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  @override
  Future<String> hash(String password) {
    final salt = secureRandomBytes(16);
    final m = memoryKiB;
    final t = iterations;
    final p = parallelism;
    return Isolate.run(
      () => Argon2(
        type: Argon2Type.argon2id,
        version: Argon2Version.v13,
        parallelism: p,
        memorySizeKB: m,
        iterations: t,
        hashLength: 32,
        salt: salt,
      ).encode(utf8.encode(password)),
    );
  }

  @override
  Future<bool> verify(String encoded, String password) =>
      Isolate.run(() => verifySync(encoded, password));

  /// Recomputes the hash with the stored salt and parameters and compares in
  /// constant time.
  static bool verifySync(String encoded, String password) {
    try {
      final data = fromCrypt(encoded);
      if (data.id != 'argon2id') return false;
      final expected = data.hashBytes();
      if (expected == null || expected.isEmpty) return false;
      final actual = Argon2.fromEncoded(data).convert(utf8.encode(password)).bytes;
      return constantTimeEquals(expected, actual);
    } on Object {
      return false;
    }
  }
}
