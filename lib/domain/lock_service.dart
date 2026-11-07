import 'dart:convert';
import 'dart:math';

import '../core/clock.dart';
import '../core/ids.dart';
import 'models.dart';
import 'ports.dart';

class PasswordPolicyException implements Exception {
  const PasswordPolicyException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The local app lock: a main password and an optional secondary (duress)
/// password, verified offline against Argon2id verifiers in the encrypted
/// database. The server knows nothing about either.
///
/// Both verifier slots always exist. When no secondary password is set, its
/// slot holds the verifier of a random 256-bit password nobody knows, so the
/// stored data looks the same either way, and every unlock attempt computes
/// both hashes, so main, secondary and wrong passwords cost the same time.
class LockService {
  LockService({required this.settings, required this.hasher, required this.clock});

  final LocalSettings settings;
  final PasswordHasher hasher;
  final Clock clock;

  static const int minLength = 8;
  static const int maxLength = 128;

  static const _main = 'lock.main';
  static const _secondary = 'lock.secondary';
  static const _failures = 'lock.failures';
  static const _until = 'lock.until';

  /// Failed attempts allowed before a growing wait (30 s, 60 s, 120 s, ...).
  static const int freeAttempts = 5;

  Future<bool> isConfigured() async =>
      await settings.read(_main) != null && await settings.read(_secondary) != null;

  static void validate(String password) {
    if (password.length < minLength) {
      throw const PasswordPolicyException('Use at least $minLength characters.');
    }
    if (password.length > maxLength) {
      throw const PasswordPolicyException('Use at most $maxLength characters.');
    }
  }

  static String _decoy() => base64Encode(secureRandomBytes(32));

  /// Sets both passwords (registration and the "forgot password" reset).
  Future<void> configure({required String main, String? secondary}) async {
    validate(main);
    final String secondarySecret;
    if (secondary != null && secondary.isNotEmpty) {
      validate(secondary);
      if (secondary == main) {
        throw const PasswordPolicyException('The secondary password must differ from the main password.');
      }
      secondarySecret = secondary;
    } else {
      secondarySecret = _decoy();
    }
    final verifiers = await Future.wait([
      hasher.hash(main),
      hasher.hash(secondarySecret),
    ]);
    await settings.write(_main, verifiers[0]);
    await settings.write(_secondary, verifiers[1]);
    await _clearFailures();
  }

  /// Checks [password] against both slots. Always evaluates both.
  Future<UnlockResult> verify(String password) async {
    final main = await settings.read(_main);
    final secondary = await settings.read(_secondary);
    if (main == null || secondary == null) return UnlockResult.invalid;
    final matches = await Future.wait([
      hasher.verify(main, password),
      hasher.verify(secondary, password),
    ]);
    if (matches[0]) return UnlockResult.normal;
    if (matches[1]) return UnlockResult.duress;
    return UnlockResult.invalid;
  }

  /// Lock-screen entry point: applies attempt throttling around [verify].
  Future<UnlockResult> attemptUnlock(String password) async {
    if (await remainingLockout() > Duration.zero) return UnlockResult.invalid;
    final result = await verify(password);
    if (result == UnlockResult.invalid) {
      await _registerFailure();
    } else {
      await _clearFailures();
    }
    return result;
  }

  Future<Duration> remainingLockout() async {
    final until = int.tryParse(await settings.read(_until) ?? '') ?? 0;
    final left = until - clock.nowMs();
    return left > 0 ? Duration(milliseconds: left) : Duration.zero;
  }

  Future<void> _registerFailure() async {
    final failures = (int.tryParse(await settings.read(_failures) ?? '') ?? 0) + 1;
    await settings.write(_failures, '$failures');
    if (failures >= freeAttempts) {
      final seconds = 30 * (1 << min(failures - freeAttempts, 10));
      await settings.write(_until, '${clock.nowMs() + seconds * 1000}');
    }
  }

  Future<void> _clearFailures() async {
    await settings.remove(_failures);
    await settings.remove(_until);
  }

  static UnlockResult _expected(UnlockMode mode) =>
      mode == UnlockMode.normal ? UnlockResult.normal : UnlockResult.duress;

  /// "Change password": replaces the password this session was unlocked
  /// with. Returns false when [current] is wrong.
  ///
  /// In a session unlocked with the secondary password, the secondary
  /// password is what the person in front of the screen believes is "the"
  /// password, so it is the one that changes. The UI behaves identically.
  Future<bool> changePassword({
    required UnlockMode mode,
    required String current,
    required String next,
  }) async {
    validate(next);
    if (await verify(current) != _expected(mode)) return false;
    if (mode == UnlockMode.normal) {
      final secondary = await settings.read(_secondary);
      if (secondary != null && await hasher.verify(secondary, next)) {
        throw const PasswordPolicyException('Choose a different password.');
      }
    }
    await settings.write(mode == UnlockMode.normal ? _main : _secondary, await hasher.hash(next));
    return true;
  }

  /// "Secondary password": sets, changes or (with an empty [next]) removes
  /// the other password slot. Returns false when [current] is wrong.
  ///
  /// In a session unlocked with the secondary password the "other" slot is
  /// the main one, so the flow stays indistinguishable (see SECURITY.md).
  Future<bool> setSecondary({
    required UnlockMode mode,
    required String current,
    String? next,
  }) async {
    final String? newSecret = (next == null || next.isEmpty) ? null : next;
    if (newSecret != null) validate(newSecret);
    if (await verify(current) != _expected(mode)) return false;
    if (newSecret != null && mode == UnlockMode.normal) {
      final main = await settings.read(_main);
      if (main != null && await hasher.verify(main, newSecret)) {
        throw const PasswordPolicyException('The secondary password must differ from the main password.');
      }
    }
    final slot = mode == UnlockMode.normal ? _secondary : _main;
    await settings.write(slot, await hasher.hash(newSecret ?? _decoy()));
    return true;
  }
}
