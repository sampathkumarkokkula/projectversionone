import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/env.dart';
import '../../core/log.dart';

const _channelId = 'bvm_messages';
const _notificationId = 1;

/// FCM background entry point. The push carries no content (`{"t":"wake"}`);
/// the phone only shows a generic "New message" notification. Nothing is
/// fetched or decrypted here, the app does that when it is opened.
@pragma('vm:entry-point')
Future<void> bvmFirebaseBackgroundHandler(RemoteMessage message) async {
  await showGenericMessageNotification();
}

/// "BVM - New message". No sender, no preview, hidden on the lock screen.
Future<void> showGenericMessageNotification() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_bvm'),
    ),
  );
  await plugin.show(
    id: _notificationId,
    title: 'BVM',
    body: 'New message',
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
}

/// Optional push: active only when the build was configured with a Firebase
/// project (see README). Without it, messages still arrive over Realtime
/// while the app runs and on every launch.
class PushService {
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  bool _initialized = false;

  bool get available => Env.pushConfigured && defaultTargetPlatform == TargetPlatform.android;

  /// Initializes FCM, hands the Firebase Installation ID (the push address of
  /// this app instance) to [onToken] and calls [onWake] for pushes received
  /// while the app is in the foreground.
  Future<void> start({
    required Future<void> Function(String? token) onToken,
    required void Function() onWake,
  }) async {
    if (!available || _initialized) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(bvmFirebaseBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: false, sound: true);
      _messageSub = FirebaseMessaging.onMessage.listen((_) => onWake());
      // FID-based registration (FCM's replacement for registration tokens).
      // Auto-init is disabled in the manifest, so register explicitly.
      _tokenSub = messaging.onRegistered.listen((fid) => unawaited(onToken(fid)));
      await messaging.register();
      _initialized = true;
    } on Object catch (e) {
      logDebug('push: unavailable (${e.runtimeType})');
    }
  }

  Future<void> clearNotifications() async {
    try {
      await FlutterLocalNotificationsPlugin().cancelAll();
    } on Object {
      // Not initialized yet: nothing to clear.
    }
  }

  /// Stops push for this device (account deletion).
  Future<void> stop() async {
    await _tokenSub?.cancel();
    await _messageSub?.cancel();
    if (_initialized) {
      try {
        await FirebaseMessaging.instance.unregister();
      } on Object {
        logDebug('push: unregister failed');
      }
    }
    _initialized = false;
  }
}
