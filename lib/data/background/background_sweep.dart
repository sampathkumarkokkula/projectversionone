import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/clock.dart';
import '../../domain/expiry_sweeper.dart';
import '../local/database_opener.dart';
import '../local/device_key_store.dart';

const String _uniqueName = 'bvm-expiry-sweep';
const String _taskName = 'bvm.expirySweep';

/// WorkManager entry point: deletes expired messages while the app is closed.
/// Local only: no network, no decryption, no notification.
@pragma('vm:entry-point')
void bvmBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final key = await DeviceKeyStore().existingDatabaseKey();
      if (key == null) return true;
      final file = await databaseFile();
      if (!await file.exists()) return true;
      final db = await openEncryptedDatabase(key, file: file);
      try {
        await ExpirySweeper(db: db, clock: const SystemClock()).sweep();
      } finally {
        await db.close();
      }
    } on Object {
      // Never crash the worker; the next run or the app will sweep.
    }
    return true;
  });
}

/// Schedules the periodic sweep (Android minimum interval: 15 minutes).
Future<void> scheduleBackgroundSweep() async {
  await Workmanager().initialize(bvmBackgroundDispatcher);
  await Workmanager().registerPeriodicTask(
    _uniqueName,
    _taskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

Future<void> cancelBackgroundSweep() => Workmanager().cancelByUniqueName(_uniqueName);
