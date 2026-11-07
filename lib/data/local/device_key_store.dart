import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/ids.dart';

/// Device secrets in Android Keystore-backed storage (iOS: Keychain, this
/// device only). Nothing here is ever sent anywhere.
///
/// * database key: random 256-bit SQLCipher key
/// * pickle key:   random 256-bit key that additionally encrypts the pickled
///                 Olm account and sessions inside the database
/// * Supabase session (see SecureSessionStorage)
class DeviceKeyStore {
  DeviceKeyStore([FlutterSecureStorage? storage]) : storage = storage ?? _defaultStorage;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  final FlutterSecureStorage storage;

  static const _dbKey = 'bvm.db_key.v1';
  static const _pickleKey = 'bvm.pickle_key.v1';

  /// Existing database key, or null on a fresh install.
  Future<String?> existingDatabaseKey() async {
    final value = await storage.read(key: _dbKey);
    return value != null && _isHexKey(value) ? value : null;
  }

  /// Database key; generated on first use.
  Future<String> databaseKey() async {
    final existing = await existingDatabaseKey();
    if (existing != null) return existing;
    final created = _hex(secureRandomBytes(32));
    await storage.write(key: _dbKey, value: created);
    return created;
  }

  /// Olm pickle key; generated on first use.
  Future<Uint8List> pickleKey() async {
    final existing = await storage.read(key: _pickleKey);
    if (existing != null) {
      final bytes = base64Decode(existing);
      if (bytes.length == 32) return Uint8List.fromList(bytes);
    }
    final created = secureRandomBytes(32);
    await storage.write(key: _pickleKey, value: base64Encode(created));
    return created;
  }

  /// Removes every secret this app stored (account deletion / reset).
  Future<void> wipe() => storage.deleteAll();

  static bool _isHexKey(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

  static String _hex(Uint8List bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
