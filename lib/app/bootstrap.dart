import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vodozemac;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../core/log.dart';
import '../data/local/app_database.dart';
import '../data/local/database_opener.dart';
import '../data/local/device_key_store.dart';
import '../data/remote/secure_session_storage.dart';
import 'app_services.dart';

sealed class BootResult {
  const BootResult();
}

/// The build has no Supabase URL / publishable key (see README).
final class BootMisconfigured extends BootResult {
  const BootMisconfigured();
}

final class BootFailed extends BootResult {
  const BootFailed(this.reason);

  final String reason;
}

final class BootReady extends BootResult {
  const BootReady(this.services, {required this.setupComplete});

  final AppServices services;
  final bool setupComplete;
}

/// Opens the encrypted database, loads the crypto library and connects the
/// Supabase client. No network round-trip is needed to reach the lock screen.
Future<BootResult> bootstrap() async {
  if (!Env.isConfigured) return const BootMisconfigured();
  try {
    final keyStore = DeviceKeyStore();
    final db = await _openDatabase(keyStore);
    await vodozemac.init();
    final pickleKey = await keyStore.pickleKey();
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(keyStore.storage),
        pkceAsyncStorage: SecurePkceStorage(keyStore.storage),
        detectSessionInUri: false,
      ),
      debug: false,
    );
    final services = AppServices.create(
      keyStore: keyStore,
      db: db,
      client: Supabase.instance.client,
      pickleKey: pickleKey,
    );
    return BootReady(services, setupComplete: await services.account.isSetUp());
  } on Object catch (e) {
    logDebug('boot failed: ${e.runtimeType}');
    return BootFailed(e.runtimeType.toString());
  }
}

Future<AppDatabase> _openDatabase(DeviceKeyStore keyStore) async {
  final file = await databaseFile();
  if (await keyStore.existingDatabaseKey() == null && await file.exists()) {
    // The Keystore entry is gone, so this file can never be decrypted again.
    await deleteDatabaseFiles(file: file);
  }
  final key = await keyStore.databaseKey();
  try {
    return await openEncryptedDatabase(key, file: file);
  } on Object catch (e) {
    if (!_isUndecryptable(e)) rethrow;
    // Wrong key for this file: its content is unrecoverable. Start fresh
    // rather than leaving the app unusable.
    await deleteDatabaseFiles(file: file);
    return openEncryptedDatabase(key, file: file);
  }
}

/// True for "file is not a database" (SQLITE_NOTADB, code 26). Errors from
/// drift's background isolate arrive wrapped, so the message is checked too.
bool _isUndecryptable(Object error) {
  if (error is SqliteException) return error.resultCode == 26;
  return error.toString().contains('file is not a database');
}
