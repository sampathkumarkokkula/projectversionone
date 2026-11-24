import '../core/log.dart';
import '../data/background/background_sweep.dart';
import '../data/local/database_opener.dart';
import '../domain/ports.dart';
import 'app_runtime.dart';
import 'app_services.dart';

/// The contact list could not be saved to the server before signing out.
class BackupNotSavedException implements Exception {
  const BackupNotSavedException();
}

/// "Sign out": the account stays on the server, this phone is erased.
///
/// Chat history exists only on the phones, so signing out deletes it here.
/// Before that, unsent messages are sent if possible and the encrypted
/// account backup is brought up to date, so signing in again (here or on
/// another phone) restores passwords, profile and contacts. Unless [force] is
/// set, a failed backup upload stops the sign-out with
/// [BackupNotSavedException] and nothing is erased.
Future<void> signOutAndErase(AppServices services, AppRuntime runtime, {bool force = false}) async {
  try {
    await runtime.syncNow();
    await services.backup.uploadIfChanged();
  } on DeviceReplacedException {
    // The account already lives on another phone; nothing to save from here.
  } on Object catch (e) {
    logDebug('sign-out: backup not saved (${e.runtimeType})');
    if (!force) throw const BackupNotSavedException();
  }
  try {
    // This phone should no longer be woken for the account.
    await services.backend.setPushToken(null);
  } on Object {
    logDebug('sign-out: push address not removed');
  }
  await runtime.stop();
  await services.push.stop();
  try {
    await cancelBackgroundSweep();
  } on Object {
    logDebug('sign-out: background task not cancelled');
  }
  try {
    await services.backend.signOutLocally();
  } on Object {
    logDebug('sign-out: local sign-out failed');
  }
  await services.db.close();
  await deleteDatabaseFiles();
  await services.keyStore.wipe();
}
