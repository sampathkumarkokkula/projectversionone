import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';
import '../../domain/ports.dart';

/// Profile row of the signed-in user.
class MyProfile {
  const MyProfile({
    required this.userId,
    required this.username,
    required this.identityKey,
    required this.oneTimeKeyCount,
  });

  final String userId;
  final String username;

  /// Curve25519 identity key of the account's current phone.
  final String identityKey;
  final int oneTimeKeyCount;
}

/// Thrown by [SupabaseBackend.createAccount] when the username is taken.
class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

/// All server access: e-mail OTP auth, directory, keys, relay, realtime,
/// push trigger and account deletion. The server only ever sees public keys,
/// the username, the encrypted phone number and end-to-end-encrypted
/// envelopes.
///
/// Relay and key calls carry this phone's identity key ([deviceKey]); the
/// server rejects them with SQLSTATE BVM01 once the account registered keys
/// on another phone, which surfaces here as [DeviceReplacedException].
class SupabaseBackend implements RelayApi, DirectoryApi {
  SupabaseBackend(this._client, {required this.deviceKey});

  final SupabaseClient _client;

  /// This phone's Curve25519 identity key.
  final Future<String> Function() deviceKey;

  Future<String> _deviceKey() => deviceKey();

  static const _deviceReplacedCode = 'BVM01';

  GoTrueClient get auth => _client.auth;

  String? get userId => _client.auth.currentUser?.id;

  /// Runs an RPC, translating the "replaced phone" error.
  Future<dynamic> _rpc(String name, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc<dynamic>(name, params: params);
    } on PostgrestException catch (e) {
      if (e.code == _deviceReplacedCode) throw const DeviceReplacedException();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Auth (e-mail OTP only)
  // ---------------------------------------------------------------------------

  Future<void> sendEmailCode(String email, {required bool createUser}) =>
      _client.auth.signInWithOtp(email: email, shouldCreateUser: createUser);

  Future<void> verifyEmailCode(String email, String code) async {
    final response = await _client.auth.verifyOTP(type: OtpType.email, email: email, token: code);
    if (response.session == null) throw const AuthException('Verification failed');
  }

  Future<void> signOutLocally() => _client.auth.signOut(scope: SignOutScope.local);

  /// Revokes the sessions of every other phone signed in to this account.
  Future<void> signOutOtherSessions() => _client.auth.signOut(scope: SignOutScope.others);

  // ---------------------------------------------------------------------------
  // Account
  // ---------------------------------------------------------------------------

  Future<MyProfile?> myProfile() async {
    final rows = _rows(await _rpc('my_profile'));
    if (rows.isEmpty) return null;
    final row = rows.first;
    return MyProfile(
      userId: row['id'] as String,
      username: row['username'] as String,
      identityKey: row['identity_key'] as String,
      oneTimeKeyCount: (row['one_time_key_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<bool> usernameAvailable(String username) async =>
      await _rpc('username_available', {'p_username': username}) == true;

  Future<void> createAccount({
    required String username,
    required String phone,
    required KeyUpload keys,
  }) async {
    try {
      await _rpc('create_account', {
        'p_username': username,
        'p_phone': phone,
        'p_identity_key': keys.identityKey,
        'p_signing_key': keys.signingKey,
        'p_fallback_key': keys.fallbackKey?.toJson(),
        'p_one_time_keys': [for (final k in keys.oneTimeKeys) k.toJson()],
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const UsernameTakenException();
      rethrow;
    }
  }

  /// Makes this phone the account's current phone (new keys on the server).
  Future<void> replaceDeviceKeys(KeyUpload keys) => _rpc('replace_device_keys', {
        'p_identity_key': keys.identityKey,
        'p_signing_key': keys.signingKey,
        'p_fallback_key': keys.fallbackKey?.toJson(),
        'p_one_time_keys': [for (final k in keys.oneTimeKeys) k.toJson()],
      });

  Future<void> setPushToken(String? token) async =>
      _rpc('set_push_token', {'p_device_key': await _deviceKey(), 'p_token': token});

  /// Deletes the directory entry, keys, push token, encrypted phone number,
  /// pending envelopes addressed to this user and the auth user itself.
  /// Only the account's current phone may do this.
  Future<void> deleteAccount() async {
    try {
      final response = await _client.functions.invoke(
        'delete-account',
        body: {'device_key': await _deviceKey()},
      );
      if (response.status != 200) throw StateError('account deletion failed (${response.status})');
    } on FunctionException catch (e) {
      if (e.status == 409) throw const DeviceReplacedException();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // DirectoryApi
  // ---------------------------------------------------------------------------

  @override
  Future<PeerKeys?> lookupUsername(String username) async {
    final rows = _rows(await _rpc('lookup_user', {'p_username': username}));
    return rows.isEmpty ? null : _peer(rows.first);
  }

  @override
  Future<PeerKeys?> getUser(String userId) async {
    final rows = _rows(await _rpc('get_user', {'p_user_id': userId}));
    return rows.isEmpty ? null : _peer(rows.first);
  }

  @override
  Future<ClaimedKey?> claimOneTimeKey(String userId) async {
    final rows = _rows(await _rpc('claim_one_time_key', {'p_user_id': userId}));
    if (rows.isEmpty) return null;
    final row = rows.first;
    final keyId = row['key_id'];
    final publicKey = row['public_key'];
    final signature = row['signature'];
    if (keyId is! String || publicKey is! String || signature is! String) return null;
    return ClaimedKey(
      keyId: keyId,
      publicKey: publicKey,
      signature: signature,
      isFallback: row['is_fallback'] == true,
    );
  }

  @override
  Future<int> uploadKeys(List<SignedKey> oneTimeKeys, {SignedKey? fallbackKey}) async {
    final result = await _rpc('upload_keys', {
      'p_device_key': await _deviceKey(),
      'p_one_time_keys': [for (final k in oneTimeKeys) k.toJson()],
      'p_fallback_key': fallbackKey?.toJson(),
    });
    return result is num ? result.toInt() : 0;
  }

  // ---------------------------------------------------------------------------
  // RelayApi
  // ---------------------------------------------------------------------------

  @override
  Future<List<IncomingEnvelope>> fetchPending({int limit = 100}) async {
    final rows = _rows(await _rpc('relay_fetch', {'p_device_key': await _deviceKey(), 'p_limit': limit}));
    return [
      for (final row in rows)
        IncomingEnvelope(
          id: row['id'] as String,
          senderId: row['sender_id'] as String,
          type: row['type'] as String,
          ciphertext: row['ciphertext'] as String,
        ),
    ];
  }

  @override
  Future<void> acknowledge(List<String> ids) async {
    final key = await _deviceKey();
    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      await _rpc('relay_ack', {'p_device_key': key, 'p_ids': chunk});
    }
  }

  @override
  Future<void> send(OutgoingEnvelope envelope) async {
    final expiresAt = envelope.expiresAtMs;
    try {
      // Idempotent on the server (same id = no-op), so retries are safe.
      await _rpc('relay_send', {
        'p_device_key': await _deviceKey(),
        'p_id': envelope.id,
        'p_recipient': envelope.recipientId,
        'p_type': envelope.type,
        'p_ciphertext': envelope.ciphertext,
        'p_expires_at':
            expiresAt == null ? null : DateTime.fromMillisecondsSinceEpoch(expiresAt, isUtc: true).toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23503') throw const RecipientGoneException();
      rethrow;
    }
  }

  @override
  Future<void> requestPush(List<String> relayIds) async {
    await _client.functions.invoke('push', body: {'relay_ids': relayIds});
  }

  // ---------------------------------------------------------------------------
  // Realtime
  // ---------------------------------------------------------------------------

  /// Calls [onEnvelope] whenever a new envelope for this user is inserted.
  /// Realtime applies the relay table's RLS policy per subscriber.
  RealtimeChannel subscribeToRelay(void Function() onEnvelope) {
    final uid = userId;
    if (uid == null) throw StateError('not signed in');
    return _client
        .channel('relay:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'relay',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'recipient_id', value: uid),
          callback: (_) => onEnvelope(),
        )
        .subscribe();
  }

  Future<void> unsubscribe(RealtimeChannel channel) => _client.removeChannel(channel);

  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> _rows(dynamic result) {
    if (result is List) {
      return [for (final r in result) if (r is Map<String, dynamic>) r];
    }
    if (result is Map<String, dynamic>) return [result];
    return const [];
  }

  static PeerKeys? _peer(Map<String, dynamic> row) {
    final id = row['id'];
    final username = row['username'];
    final identityKey = row['identity_key'];
    final signingKey = row['signing_key'];
    if (id is! String || username is! String || identityKey is! String || signingKey is! String) {
      return null;
    }
    return PeerKeys(userId: id, username: username, identityKey: identityKey, signingKey: signingKey);
  }
}
