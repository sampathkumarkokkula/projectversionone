import 'package:bvm/data/crypto/argon2_hasher.dart';
import 'package:bvm/domain/lock_service.dart';
import 'package:bvm/domain/models.dart';
import 'package:bvm/domain/ports.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Real Argon2id with test-sized parameters, counting every verification.
class CountingHasher implements PasswordHasher {
  final _inner = const Argon2idHasher(memoryKiB: 256, iterations: 1);
  int verifications = 0;

  @override
  Future<String> hash(String password) => _inner.hash(password);

  @override
  Future<bool> verify(String encoded, String password) {
    verifications++;
    return _inner.verify(encoded, password);
  }
}

class MemorySettings implements LocalSettings {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late MemorySettings settings;
  late CountingHasher hasher;
  late FakeClock clock;
  late LockService lock;

  const mainPw = 'correct horse battery';
  const secondaryPw = 'under duress 123';

  setUp(() {
    settings = MemorySettings();
    hasher = CountingHasher();
    clock = FakeClock(1_000_000);
    lock = LockService(settings: settings, hasher: hasher, clock: clock);
  });

  group('password verifier branch', () {
    test('main password unlocks normally, secondary password unlocks in duress mode', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);

      expect(await lock.verify(mainPw), UnlockResult.normal);
      expect(await lock.verify(secondaryPw), UnlockResult.duress);
      expect(await lock.verify('not my password'), UnlockResult.invalid);
      expect(await lock.verify(''), UnlockResult.invalid);
    });

    test('every attempt evaluates both verifiers, whatever the outcome', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);
      for (final attempt in [mainPw, secondaryPw, 'wrong password']) {
        hasher.verifications = 0;
        await lock.verify(attempt);
        expect(hasher.verifications, 2, reason: 'attempt "$attempt" must cost two hashes');
      }
    });

    test('without a secondary password both slots still hold Argon2id verifiers', () async {
      await lock.configure(main: mainPw);

      final mainVerifier = settings.values['lock.main']!;
      final secondaryVerifier = settings.values['lock.secondary']!;
      expect(mainVerifier, startsWith(r'$argon2id$v=19$'));
      expect(secondaryVerifier, startsWith(r'$argon2id$v=19$'));
      expect(secondaryVerifier.length, mainVerifier.length);
      expect(await lock.verify(mainPw), UnlockResult.normal);
      expect(await lock.verify(secondaryPw), UnlockResult.invalid);
    });

    test('verifiers are salted: the same password gives different PHC strings', () async {
      final a = await hasher.hash(mainPw);
      final b = await hasher.hash(mainPw);
      expect(a, isNot(b));
      expect(await hasher.verify(a, mainPw), isTrue);
      expect(await hasher.verify(b, mainPw), isTrue);
      expect(await hasher.verify(a, '$mainPw!'), isFalse);
      expect(await hasher.verify('not-a-phc-string', mainPw), isFalse);
    });

    test('rejects a secondary password equal to the main one and short passwords', () async {
      await expectLater(lock.configure(main: mainPw, secondary: mainPw), throwsA(isA<PasswordPolicyException>()));
      await expectLater(lock.configure(main: 'short'), throwsA(isA<PasswordPolicyException>()));
    });
  });

  group('throttling', () {
    test('locks out after repeated failures, even for the right password', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);
      for (var i = 0; i < LockService.freeAttempts; i++) {
        expect(await lock.attemptUnlock('wrong $i'), UnlockResult.invalid);
      }
      expect(await lock.remainingLockout(), greaterThan(Duration.zero));
      expect(await lock.attemptUnlock(mainPw), UnlockResult.invalid);

      clock.advance(const Duration(seconds: 31));
      expect(await lock.attemptUnlock(secondaryPw), UnlockResult.duress);
      expect(await lock.remainingLockout(), Duration.zero);
    });
  });

  group('settings behave the same in both modes', () {
    test('change password: normal session changes the main password', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);
      expect(await lock.changePassword(mode: UnlockMode.normal, current: mainPw, next: 'new main password'), isTrue);
      expect(await lock.verify('new main password'), UnlockResult.normal);
      expect(await lock.verify(mainPw), UnlockResult.invalid);
      expect(await lock.verify(secondaryPw), UnlockResult.duress);
    });

    test('change password: duress session changes the secondary password, main keeps working', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);
      expect(await lock.changePassword(mode: UnlockMode.duress, current: secondaryPw, next: 'attacker choice'), isTrue);
      expect(await lock.verify('attacker choice'), UnlockResult.duress);
      expect(await lock.verify(secondaryPw), UnlockResult.invalid);
      expect(await lock.verify(mainPw), UnlockResult.normal);
    });

    test('wrong current password is refused in both modes', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);
      expect(await lock.changePassword(mode: UnlockMode.normal, current: secondaryPw, next: 'whatever123'), isFalse);
      expect(await lock.changePassword(mode: UnlockMode.duress, current: mainPw, next: 'whatever123'), isFalse);
    });

    test('removing the secondary password', () async {
      await lock.configure(main: mainPw, secondary: secondaryPw);
      expect(await lock.setSecondary(mode: UnlockMode.normal, current: mainPw, next: ''), isTrue);
      expect(await lock.verify(secondaryPw), UnlockResult.invalid);
      expect(await lock.verify(mainPw), UnlockResult.normal);
      expect(settings.values['lock.secondary'], startsWith(r'$argon2id$'));
    });
  });
}
