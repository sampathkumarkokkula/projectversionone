import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/log.dart';

const _channelId = 'bvm_messages';
const _notificationId = 1;

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_bvm'),
    ),
  );
  _initialized = true;
}

/// "BVM - New message". Never shows who wrote or what, and is hidden on a
/// secure lock screen. Works from any isolate (app, FCM handler, WorkManager).
Future<void> showNewMessageNotification({int count = 1}) async {
  try {
    await _ensureInitialized();
    await _plugin.show(
      id: _notificationId,
      title: 'BVM',
      body: count > 1 ? 'New messages' : 'New message',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Messages',
          channelDescription: 'New-message alerts. They never contain message content.',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.secret,
          category: AndroidNotificationCategory.message,
          icon: '@drawable/ic_stat_bvm',
        ),
      ),
    );
  } on Object catch (e) {
    logDebug('notifications: show failed (${e.runtimeType})');
  }
}

/// Local new-message notifications. They need no server and no Firebase: the
/// running app shows them when messages arrive while it is in the background,
/// and a background task (every ~15 minutes) when it is closed. Firebase push,
/// if configured, makes the closed-app case instant.
class Notifications {
  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Android 13+ asks the user once; afterwards this is a no-op.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      await _ensureInitialized();
      return await _android?.requestNotificationsPermission() ?? false;
    } on Object {
      return false;
    }
  }

  Future<bool> enabled() async {
    if (!_supported) return false;
    try {
      await _ensureInitialized();
      return await _android?.areNotificationsEnabled() ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> show(int count) => showNewMessageNotification(count: count);

  Future<void> clear() async {
    try {
      await _ensureInitialized();
      await _plugin.cancelAll();
    } on Object {
      // Nothing to clear.
    }
  }
}
