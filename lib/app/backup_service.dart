import 'dart:convert';
import 'dart:typed_data';

import '../core/log.dart';
import '../data/crypto/account_backup.dart';
import '../data/local/app_database.dart';
import '../data/remote/supabase_backend.dart';
import '../domain/lock_service.dart';
import '../domain/message_service.dart';
import '../domain/models.dart';
import '../domain/ports.dart';

/// What a backup restores on a new phone. Never contains messages.
class RestoredAccount {
  const RestoredAccount({
    required this.mainVerifier,
    required this.secondaryVerifier,
    required this.mainKey,
    required this.secondaryKey,
    required this.displayName,
    required this.avatar,
    required this.chats,
  });

  final String mainVerifier;
  final String secondaryVerifier;
  final SlotKey mainKey;
  final SlotKey secondaryKey;
  final String? displayName;
  final Uint8List? avatar;
  final List<BackupChat> chats;
}

/// Password-protected account backup, so signing in on a new or reinstalled
/// phone keeps the app passwords, profile and contact list (chats come back
/// empty: history never leaves the phones).
///
/// Two copies are stored, one per password slot, each encrypted with a key
/// derived from that slot's password (or a random key when the slot has no
/// password). Both always exist and look alike, so neither the server nor
/// anyone holding one password learns whether a secondary password exists.
class BackupService implements SlotKeyListener {
  BackupService({required this.db, required this.backend, required this.messages});

  final AppDatabase db;
  final SupabaseBackend backend;
  final MessageService messages;

  /// Set right after construction (the lock service needs this as listener).
  late final LockService lock;

  static const _keyMain = 'backup.key.main';
  static const _keySecondary = 'backup.key.secondary';
  static const _lastHash = 'backup.hash';

  String _slotKeyName(PasswordSlot slot) => slot == PasswordSlot.main ? _keyMain : _keySecondary;

  Future<SlotKey?> _slotKey(PasswordSlot slot) async {
    final raw = await db.read(_slotKeyName(slot));
    if (raw == null) return null;
    try {
      return SlotKey.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<void> _storeSlotKey(PasswordSlot slot, SlotKey key) =>
      db.write(_slotKeyName(slot), jsonEncode(key.toJson()));

  @override
  Future<void> slotChanged(PasswordSlot slot, String? password) async {
    await _storeSlotKey(slot, password == null ? SlotKey.random() : await BackupCipher.newSlotKey(password));
  }

  /// Fills in the backup key of the slot that was just unlocked when it is
  /// missing (passwords set before backups existed). Runs after unlocking.
  Future<void> onUnlocked(String password, UnlockMode mode) async {
    try {
      final slot = mode == UnlockMode.normal ? PasswordSlot.main : PasswordSlot.secondary;
      if (await _slotKey(slot) == null) await slotChanged(slot, password);
      // Older installs: without a known secondary key the secondary copy gets
      // a random key until the secondary password is used or set again.
      if (mode == UnlockMode.normal && await _slotKey(PasswordSlot.secondary) == null) {
        await _storeSlotKey(PasswordSlot.secondary, SlotKey.random());
      }
    } on Object catch (e) {
      logDebug('backup: slot key update failed (${e.runtimeType})');
    }
  }

  Future<String?> _content() async {
    final verifiers = await lock.exportVerifiers();
    final main = await _slotKey(PasswordSlot.main);
    final secondary = await _slotKey(PasswordSlot.secondary);
    if (verifiers == null || main == null || secondary == null) return null;
    final avatar = await db.avatarOf(selfAvatarId);
    return jsonEncode({
      'v': 1,
      'lock': {'m': verifiers.main, 's': verifiers.secondary},
      'keys': {'m': main.toJson(), 's': secondary.toJson()},
      'profile': {
        'dn': cleanDisplayName(await db.read(selfDisplayNameKey)),
        'a': avatar == null ? null : base64Encode(avatar),
      },
      'chats': [for (final c in await messages.backupChats()) c.toJson()],
    });
  }

  /// Encrypts and uploads the backup when its content changed since the last
  /// upload. Cheap when nothing changed.
  Future<void> uploadIfChanged() async {
    if (await db.read('setup.complete') != '1' || backend.userId == null) return;
    final content = await _content();
    if (content == null) return;
    final hash = BackupCipher.hash(content);
    if (await db.read(_lastHash) == hash) return;
    final copyMain = await BackupCipher.encrypt(content, (await _slotKey(PasswordSlot.main))!);
    final copySecondary = await BackupCipher.encrypt(content, (await _slotKey(PasswordSlot.secondary))!);
    final copies = BackupCipher.shuffle(copyMain, copySecondary);
    await backend.putAccountBackup(copies[0], copies[1]);
    await db.write(_lastHash, hash);
  }

  Future<List<String>?> fetchRemote() => backend.getAccountBackup();

  /// Opens [copies] with [password]; null when the password opens neither.
  Future<RestoredAccount?> open(List<String> copies, String password) async {
    final opened = await BackupCipher.open(copies, password);
    if (opened == null) return null;
    final j = jsonDecode(opened.content);
    if (j is! Map<String, dynamic> || j['v'] != 1) return null;
    final lockJson = j['lock'] as Map<String, dynamic>;
    final keys = j['keys'] as Map<String, dynamic>;
    final main = SlotKey.fromJson(keys['m']);
    final secondary = SlotKey.fromJson(keys['s']);
    if (main == null || secondary == null) return null;
    final profile = (j['profile'] as Map<String, dynamic>?) ?? const {};
    Uint8List? avatar;
    final a = profile['a'];
    if (a is String) {
      try {
        avatar = base64Decode(a);
      } on FormatException {
        avatar = null;
      }
    }
    final dn = profile['dn'];
    return RestoredAccount(
      mainVerifier: lockJson['m'] as String,
      secondaryVerifier: lockJson['s'] as String,
      mainKey: main,
      secondaryKey: secondary,
      displayName: dn is String ? dn : null,
      avatar: avatar,
      chats: [
        for (final c in (j['chats'] as List<dynamic>? ?? const []))
          ?BackupChat.fromJson(c),
      ],
    );
  }

  Future<void> importKeys(RestoredAccount restored) async {
    await _storeSlotKey(PasswordSlot.main, restored.mainKey);
    await _storeSlotKey(PasswordSlot.secondary, restored.secondaryKey);
  }

  /// Contacts and own profile from the backup. Peers are looked up in the
  /// directory (they may have changed username or phone); deleted accounts
  /// are skipped. Each restored contact gets a fresh session and a
  /// content-free hello on the next sync, so their next message reaches this
  /// phone instead of being encrypted for the old one.
  Future<void> restoreContent(RestoredAccount restored, DirectoryApi directory) async {
    final name = cleanDisplayName(restored.displayName);
    if (name != null) await db.write(selfDisplayNameKey, name);
    final avatar = restored.avatar;
    if (avatar != null && avatar.length <= MessageService.maxAvatarBytes) {
      await db.setAvatar(selfAvatarId, avatar, DateTime.now().millisecondsSinceEpoch);
    }
    for (final saved in restored.chats) {
      try {
        final peer = await directory.getUser(saved.peerId);
        if (peer == null) continue;
        await messages.restoreChat(saved, peer);
        if (!saved.blocked) await messages.requestSessionRepair(saved.peerId);
      } on Object catch (e) {
        logDebug('backup: contact not restored (${e.runtimeType})');
      }
    }
    await messages.bumpProfileVersion();
  }
}
