import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import '../../core/clock.dart';
import '../../core/env.dart';
import '../../domain/expiry_sweeper.dart';
import '../local/app_database.dart';
import '../local/database_opener.dart';
import '../local/device_key_store.dart';
import '../push/notifications.dart';

const String _uniqueName = 'bvm-expiry-sweep';
const String _taskName = 'bvm.expirySweep';
const String _lastNotifiedKey = 'inbox.notified';

/// WorkManager entry point, every ~15 minutes while the app is closed:
/// 1. deletes expired messages (local only), and
/// 2. asks the server whether message envelopes are waiting and, if so,
///    shows the generic "New message" notification. Nothing is fetched or
///    decrypted here; the app does that when it is opened.
@pragma('vm:entry-point')
void bvmBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final keys = DeviceKeyStore();
      final dbKey = await keys.existingDatabaseKey();
      if (dbKey == null) return true;
      final file = await databaseFile();
      if (!await file.exists()) return true;
      final db = await openEncryptedDatabase(dbKey, file: file);
      try {
        await ExpirySweeper(db: db, clock: const SystemClock()).sweep();
        await _checkInbox(db, keys);
      } finally {
        await db.close();
      }
    } on Object {
      // Never crash the worker; the next run or the app will catch up.
    }
    return true;
  });
}

Future<void> _checkInbox(AppDatabase db, DeviceKeyStore keys) async {
  if (!Env.isConfigured) return;
  final credentials = await keys.inboxCredentials();
  if (credentials == null) return;
  final count = await fetchInboxCount(credentials);
  if (count == null) return;
  final last = int.tryParse(await db.read(_lastNotifiedKey) ?? '') ?? 0;
  if (count > 0 && count != last) await showNewMessageNotification(count: count);
  await db.write(_lastNotifiedKey, '$count');
}

/// Number of message envelopes waiting (photo parts count individually), or
/// null when the server could not be asked. Uses only the publishable key
/// and the inbox token: no login session is touched in the background.
Future<int?> fetchInboxCount(InboxCredentials credentials) async {
  final key = Env.supabasePublishableKey;
  final headers = <String, String>{'apikey': key, 'Content-Type': 'application/json'};
  // Legacy anon keys are JWTs and also go in the Authorization header.
  if (key.startsWith('eyJ')) headers['Authorization'] = 'Bearer $key';
  try {
    final response = await http
        .post(
          Uri.parse('${Env.supabaseUrl}/rest/v1/rpc/inbox_pending'),
          headers: headers,
          body: jsonEncode({'p_user': credentials.userId, 'p_token': credentials.token}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return null;
    final value = jsonDecode(response.body);
    return value is num ? value.toInt() : null;
  } on Object {
    return null;
  }
}

/// Schedules the periodic task (Android minimum interval: 15 minutes).
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
