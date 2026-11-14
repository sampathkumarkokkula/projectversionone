import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/env.dart';
import '../../core/log.dart';
import 'notifications.dart';

/// FCM background entry point. The push carries no content (`{"t":"wake"}`);
/// the phone only shows a generic "New message" notification. Nothing is
/// fetched or decrypted here, the app does that when it is opened.
@pragma('vm:entry-point')
Future<void> bvmFirebaseBackgroundHandler(RemoteMessage message) async {
  await showNewMessageNotification();
}

/// Where instant push stands on this phone (shown in Settings).
enum PushState {
  /// The APK was built without the FIREBASE_* values in .env.
  notInBuild,
  starting,

  /// Firebase gave this phone a push address and the server has it.
  registered,

  /// Firebase or the server registration failed; see [PushService.lastError].
  failed,
}

/// Optional instant push: active only when the build was configured with a
/// Firebase project (README section 3). Without it, notifications still come
/// from the background check every ~15 minutes.
class PushService {
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  bool _initialized = false;

  final ValueNotifier<PushState> state =
      ValueNotifier(Env.pushConfigured ? PushState.starting : PushState.notInBuild);

  /// Short technical reason when [state] is [PushState.failed] (no secrets).
  String? lastError;

  bool get available => Env.pushConfigured && defaultTargetPlatform == TargetPlatform.android;

  void _fail(String reason) {
    lastError = reason;
    state.value = PushState.failed;
    logDebug('push: $reason');
  }

  /// Initializes FCM, hands the Firebase Installation ID (the push address of
  /// this app instance) to [onToken] and calls [onWake] for pushes received
  /// while the app is in the foreground. [onToken] returns false when the
  /// server did not accept the address.
  Future<void> start({
    required Future<bool> Function(String? token) onToken,
    required void Function() onWake,
  }) async {
    if (!available || _initialized) return;
    state.value = PushState.starting;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(bvmFirebaseBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: false, sound: true);
      _messageSub = FirebaseMessaging.onMessage.listen((_) => onWake());
      // FID-based registration (FCM's replacement for registration tokens).
      // Auto-init is disabled in the manifest, so register explicitly.
      _tokenSub = messaging.onRegistered.listen((fid) {
        unawaited(() async {
          if (await onToken(fid)) {
            lastError = null;
            state.value = PushState.registered;
          } else {
            _fail('the server did not accept the push address');
          }
        }());
      });
      await messaging.register();
      _initialized = true;
      // register() normally reports through onRegistered within seconds.
      Timer(const Duration(seconds: 30), () {
        if (state.value == PushState.starting) {
          _fail('Firebase did not return a push address (Google Play services missing or blocked?)');
        }
      });
    } on Object catch (e) {
      _fail('Firebase start failed (${e.runtimeType})');
    }
  }

  /// Stops push for this device (account deletion, account moved).
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
