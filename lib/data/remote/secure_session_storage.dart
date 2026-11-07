import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session (refresh token) in Keystore-backed storage
/// instead of the plaintext SharedPreferences default.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'bvm.supabase_session.v1';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _storage.read(key: _key) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}

/// PKCE verifier storage, also kept out of SharedPreferences.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _prefix = 'bvm.supabase_pkce.';

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: '$_prefix$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: '$_prefix$key');
}
