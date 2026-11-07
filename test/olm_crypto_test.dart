import 'dart:io';

import 'package:bvm/core/ids.dart';
import 'package:bvm/data/crypto/olm_crypto.dart';
import 'package:bvm/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vodozemac/vodozemac.dart' as vod;

import 'support/fakes.dart';

/// The E2E handshake against the real vodozemac library.
///
/// Needs a host build of the Rust bindings (the Android build compiles them
/// for the phone only). `scripts/test.ps1` builds it and sets
/// BVM_VODOZEMAC_LIB_DIR; without it these tests are skipped.
void main() {
  final libDir = Platform.environment['BVM_VODOZEMAC_LIB_DIR'];
  final libFile = libDir == null
      ? null
      : File(p.join(libDir, Platform.isWindows ? 'vodozemac_bindings_dart.dll' : 'libvodozemac_bindings_dart.so'));
  final available = libFile != null && libFile.existsSync();

  group('OlmCrypto (vodozemac)', skip: available ? false : 'BVM_VODOZEMAC_LIB_DIR not set', () {
    late FakeClock clock;

    setUpAll(() async {
      // flutter_rust_bridge resolves this against the working directory as a
      // URI, so pass an absolute file URI rather than a Windows path.
      await vod.init(libraryPath: Uri.directory(libDir!).toString());
    });

    setUp(() => clock = FakeClock(DateTime.utc(2026, 10, 31).millisecondsSinceEpoch));

    OlmCrypto device() => OlmCrypto(db: memoryDatabase(), pickleKey: secureRandomBytes(32), clock: clock);

    PeerKeys peerOf(String id, KeyUpload keys) =>
        PeerKeys(userId: id, username: id, identityKey: keys.identityKey, signingKey: keys.signingKey);

    ClaimedKey claim(SignedKey k, {bool fallback = false}) =>
        ClaimedKey(keyId: k.id, publicKey: k.key, signature: k.signature, isFallback: fallback);

    test('handshake and ratchet in both directions, state survives in the database', () async {
      final alice = device();
      final bob = device();
      final aliceKeys = await alice.createIdentity(oneTimeKeys: 5);
      final bobKeys = await bob.createIdentity(oneTimeKeys: 5);
      await alice.markPublished();
      await bob.markPublished();
      expect(bobKeys.oneTimeKeys, hasLength(5));
      expect(bobKeys.fallbackKey, isNotNull);

      await alice.startSession(peerOf('bob', bobKeys), claim(bobKeys.oneTimeKeys.first));
      final first = await alice.encrypt('bob', 'hello bob');
      expect(first.olmType, 0, reason: 'the first message sets up the session');
      expect(await bob.decrypt('alice', aliceKeys.identityKey, first), 'hello bob');

      final reply = await bob.encrypt('alice', 'hi alice');
      expect(reply.olmType, 1);
      expect(await alice.decrypt('bob', null, reply), 'hi alice');

      for (var i = 0; i < 3; i++) {
        final m = await alice.encrypt('bob', 'message $i');
        expect(m.olmType, 1);
        expect(await bob.decrypt('alice', null, m), 'message $i');
      }
    });

    test('a replayed message is rejected and does not break the session', () async {
      final alice = device();
      final bob = device();
      final aliceKeys = await alice.createIdentity(oneTimeKeys: 2);
      final bobKeys = await bob.createIdentity(oneTimeKeys: 2);
      await alice.startSession(peerOf('bob', bobKeys), claim(bobKeys.oneTimeKeys.first));
      final m = await alice.encrypt('bob', 'once');
      expect(await bob.decrypt('alice', aliceKeys.identityKey, m), 'once');
      await expectLater(bob.decrypt('alice', aliceKeys.identityKey, m), throwsA(anything));
      final next = await alice.encrypt('bob', 'still works');
      expect(await bob.decrypt('alice', aliceKeys.identityKey, next), 'still works');
    });

    test('a one-time key with a forged signature is refused', () async {
      final alice = device();
      final bob = device();
      final mallory = device();
      await alice.createIdentity(oneTimeKeys: 1);
      final bobKeys = await bob.createIdentity(oneTimeKeys: 1);
      final malloryKeys = await mallory.createIdentity(oneTimeKeys: 1);
      // The server hands out Mallory's key in Bob's name.
      final forged = ClaimedKey(
        keyId: 'x',
        publicKey: malloryKeys.oneTimeKeys.first.key,
        signature: malloryKeys.oneTimeKeys.first.signature,
        isFallback: false,
      );
      await expectLater(alice.startSession(peerOf('bob', bobKeys), forged), throwsA(anything));
      expect(await alice.hasSession('bob'), isFalse);
    });

    test('the signed fallback key works when one-time keys are exhausted', () async {
      final alice = device();
      final bob = device();
      final aliceKeys = await alice.createIdentity(oneTimeKeys: 1);
      final bobKeys = await bob.createIdentity(oneTimeKeys: 1);
      await alice.startSession(peerOf('bob', bobKeys), claim(bobKeys.fallbackKey!, fallback: true));
      final m = await alice.encrypt('bob', 'via fallback');
      expect(await bob.decrypt('alice', aliceKeys.identityKey, m), 'via fallback');
    });

    test('the pickled account is unreadable with another pickle key', () async {
      final db = memoryDatabase();
      final owner = OlmCrypto(db: db, pickleKey: secureRandomBytes(32), clock: clock);
      await owner.createIdentity(oneTimeKeys: 1);
      final intruder = OlmCrypto(db: db, pickleKey: secureRandomBytes(32), clock: clock);
      await expectLater(intruder.signingKey(), throwsA(anything));
      expect(await owner.signingKey(), isNotEmpty);
    });
  });
}
