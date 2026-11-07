import '../core/log.dart';
import '../data/background/background_sweep.dart';
import '../data/local/database_opener.dart';
import 'app_runtime.dart';
import 'app_services.dart';

/// "Delete my account": the server side first (directory entry, keys, push
/// token, encrypted phone, pending envelopes, auth user with the e-mail).
/// Only when that succeeded is every local trace removed: database file,
/// Keystore secrets, session, scheduled work.
Future<void> deleteAccountEverywhere(AppServices services, AppRuntime runtime) async {
  await services.backend.deleteAccount();
  await runtime.stop();
  await services.push.stop();
  try {
    await cancelBackgroundSweep();
  } on Object {
    logDebug('delete: background task not cancelled');
  }
  try {
    await services.backend.signOutLocally();
  } on Object {
    logDebug('delete: local sign-out failed');
  }
  await services.db.close();
  await deleteDatabaseFiles();
  await services.keyStore.wipe();
}
