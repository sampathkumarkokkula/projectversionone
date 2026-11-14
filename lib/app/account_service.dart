import 'dart:convert';
import 'dart:typed_data';

import '../core/ids.dart';
import '../core/log.dart';
import '../data/local/app_database.dart';
import '../data/local/device_key_store.dart';
import '../data/remote/supabase_backend.dart';
import '../domain/lock_service.dart';
import '../domain/message_service.dart';
import '../domain/ports.dart';
import '../domain/wipe_service.dart';

/// Registration, new-device sign-in, password reset, profile (username and
/// picture), and key upkeep.
class AccountService {
  AccountService({
    required this.backend,
    required this.crypto,
    required this.lock,
    required this.wipe,
    required this.db,
    required this.keyStore,
    required this.messages,
  });

  final SupabaseBackend backend;
  final E2eCrypto crypto;
  final LockService lock;
  final WipeService wipe;
  final AppDatabase db;
  final DeviceKeyStore keyStore;
  final MessageService messages;

  static const _selfId = 'self.id';
  static const _selfUsername = 'self.username';
  static const _selfEmail = 'self.email';
  static const _setupComplete = 'setup.complete';

  static const int _oneTimeKeyTarget = 50;
  static const int _oneTimeKeyLowWater = 20;

  static final RegExp usernamePattern = RegExp(r'^[a-z0-9_]{3,24}$');
  static final RegExp phonePattern = RegExp(r'^\+[1-9][0-9]{6,14}$');
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String normalizeEmail(String email) => email.trim().toLowerCase();
  static String normalizeUsername(String username) => username.trim().toLowerCase();
  static String normalizePhone(String phone) => phone.replaceAll(RegExp(r'[\s()-]'), '');

  Future<bool> isSetUp() async => await db.read(_setupComplete) == '1' && await lock.isConfigured();

  Future<String?> username() => db.read(_selfUsername);
  Future<String?> userId() => db.read(_selfId);

  /// E-mail with the local part masked, for the reset screen.
  Future<String?> maskedEmail() async {
    final email = await db.read(_selfEmail);
    if (email == null) return null;
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email[0]}${'*' * (at - 1)}${email.substring(at)}';
  }

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  Future<void> sendSignInCode(String email) =>
      backend.sendEmailCode(normalizeEmail(email), createUser: true);

  /// Verifies the code and returns the existing profile (new device) or null
  /// (a username still has to be chosen).
  Future<MyProfile?> verifySignInCode(String email, String code) async {
    final normalized = normalizeEmail(email);
    await backend.verifyEmailCode(normalized, code.trim());
    await db.write(_selfEmail, normalized);
    return backend.myProfile();
  }

  Future<bool> usernameAvailable(String username) =>
      backend.usernameAvailable(normalizeUsername(username));

  /// First registration: identity keys, directory entry, passwords.
  Future<void> register({
    required String username,
    required String phone,
    required String mainPassword,
    String? secondaryPassword,
  }) async {
    final name = normalizeUsername(username);
    final number = normalizePhone(phone);
    if (!usernamePattern.hasMatch(name)) throw ArgumentError('invalid username');
    if (!phonePattern.hasMatch(number)) throw ArgumentError('invalid phone number');
    await lock.configure(main: mainPassword, secondary: secondaryPassword);
    final keys = await crypto.createIdentity(oneTimeKeys: _oneTimeKeyTarget);
    await backend.createAccount(username: name, phone: number, keys: keys);
    await crypto.markPublished();
    await _finishSetup(name);
  }

  /// Existing account, new (or reinstalled) phone: fresh identity keys. Chat
  /// history never moves between phones. The previous phone is signed out and
  /// the server refuses its relay calls from now on (one phone per account).
  Future<void> continueOnThisDevice({
    required MyProfile profile,
    required String mainPassword,
    String? secondaryPassword,
  }) async {
    await lock.configure(main: mainPassword, secondary: secondaryPassword);
    await _becomeCurrentDevice();
    await _finishSetup(profile.username);
  }

  Future<void> _becomeCurrentDevice() async {
    final keys = await crypto.createIdentity(oneTimeKeys: _oneTimeKeyTarget);
    await backend.replaceDeviceKeys(keys);
    await crypto.markPublished();
    await db.remove(deviceReplacedKey);
    try {
      await backend.signOutOtherSessions();
    } on Object {
      // The other phone is cut off by the key check anyway.
      logDebug('account: could not revoke other sessions');
    }
  }

  // ---------------------------------------------------------------------------
  // One phone per account
  // ---------------------------------------------------------------------------

  /// Set when the server reported that another phone took over the account.
  static const deviceReplacedKey = 'device.replaced';

  Stream<bool> watchDeviceReplaced() => db.watchValue(deviceReplacedKey).map((v) => v == '1');

  Future<bool> isDeviceReplaced() async => await db.read(deviceReplacedKey) == '1';

  Future<void> markDeviceReplaced() => db.write(deviceReplacedKey, '1');

  /// The account moved to another phone and the owner wants it back here:
  /// verify the e-mail code, then register fresh keys for this phone. Local
  /// chats stay; new sessions are set up as messages are sent.
  Future<void> takeOverAccount(String code) async {
    await reconnect(code);
    await _becomeCurrentDevice();
  }

  Future<void> _finishSetup(String username) async {
    final id = backend.userId;
    if (id == null) throw StateError('not signed in');
    await db.write(_selfId, id);
    await db.write(_selfUsername, username);
    await db.write(_setupComplete, '1');
  }

  // ---------------------------------------------------------------------------
  // Forgot password
  // ---------------------------------------------------------------------------

  /// Step 1, before anything else: delete every timer-enabled chat on this
  /// phone so a reset can never be used to get around the secondary password.
  Future<void> beginPasswordReset() => wipe.wipeBeforePasswordReset();

  /// Step 2: e-mail code to the account's address.
  Future<void> sendResetCode() async {
    final email = await db.read(_selfEmail);
    if (email == null) throw StateError('no e-mail on record');
    await backend.sendEmailCode(email, createUser: false);
  }

  /// Signs this phone in again after the server session was lost, without
  /// touching local data. Uses the account's own e-mail address only.
  Future<void> reconnect(String code) async {
    final email = await db.read(_selfEmail);
    if (email == null) throw StateError('no e-mail on record');
    await backend.verifyEmailCode(email, code.trim());
    if (backend.userId != await db.read(_selfId)) {
      await backend.signOutLocally();
      throw StateError('the code belongs to a different account');
    }
  }

  /// Step 3: verify the code and set new passwords.
  Future<void> completePasswordReset({
    required String code,
    required String mainPassword,
    String? secondaryPassword,
  }) async {
    final email = await db.read(_selfEmail);
    if (email == null) throw StateError('no e-mail on record');
    LockService.validate(mainPassword);
    await backend.verifyEmailCode(email, code.trim());
    if (backend.userId != await db.read(_selfId)) {
      throw StateError('the code belongs to a different account');
    }
    await lock.configure(main: mainPassword, secondary: secondaryPassword);
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Changes the public username (at most once every 24 hours). People you
  /// chat with see the new name on their next sync.
  Future<void> changeUsername(String username) async {
    final name = normalizeUsername(username);
    if (!usernamePattern.hasMatch(name)) throw ArgumentError('invalid username');
    if (name == await this.username()) return;
    await backend.changeUsername(name);
    await db.write(_selfUsername, name);
    await messages.bumpProfileVersion();
  }

  /// Sets the profile picture (a small JPEG from ImageProcessor). It is sent,
  /// end-to-end encrypted, only to accepted chats; the server never stores it.
  Future<void> setAvatar(Uint8List jpeg) async {
    await db.setAvatar(selfAvatarId, jpeg, DateTime.now().millisecondsSinceEpoch);
    await messages.bumpProfileVersion();
  }

  Future<void> removeAvatar() async {
    await db.removeAvatar(selfAvatarId);
    await messages.bumpProfileVersion();
  }

  // ---------------------------------------------------------------------------
  // Upkeep
  // ---------------------------------------------------------------------------

  /// Registers a random token so the background task can ask the server
  /// whether new messages wait (notifications without Firebase). Done once
  /// per phone and account.
  Future<void> ensureInboxToken() async {
    final uid = backend.userId;
    if (uid == null) return;
    final deviceKey = await crypto.identityKey();
    final existing = await keyStore.inboxCredentials();
    if (existing != null && existing.userId == uid && existing.deviceKey == deviceKey) return;
    final token = base64Url.encode(secureRandomBytes(32)).replaceAll('=', '');
    await backend.setInboxToken(token);
    await keyStore.saveInboxCredentials(InboxCredentials(userId: uid, token: token, deviceKey: deviceKey));
  }

  /// Keeps enough signed one-time keys on the server for new contacts.
  /// Throws [DeviceReplacedException] when another phone owns the account.
  Future<void> maintainKeys() async {
    try {
      final profile = await backend.myProfile();
      if (profile == null) return;
      if (profile.identityKey != await crypto.identityKey()) throw const DeviceReplacedException();
      if (profile.oneTimeKeyCount >= _oneTimeKeyLowWater) return;
      final upload = await crypto.generateKeys(count: _oneTimeKeyTarget - profile.oneTimeKeyCount);
      await backend.uploadKeys(upload.oneTimeKeys, fallbackKey: upload.fallbackKey);
      await crypto.markPublished();
    } on DeviceReplacedException {
      rethrow;
    } on Object catch (e) {
      logDebug('keys: upkeep skipped (${e.runtimeType})');
    }
  }
}
