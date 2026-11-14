import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/log.dart';
import '../data/background/background_sweep.dart';
import '../domain/ports.dart';
import 'app_services.dart';

/// Long-running work once the account is set up: the auto-delete sweep, the
/// Realtime subscription, periodic sync, key upkeep and push registration.
///
/// It runs whether or not the app is unlocked, so incoming wipe commands and
/// timer expiries are applied as soon as the app process is alive.
///
/// When the server reports that the account moved to another phone, the
/// runtime drops to local-only mode: auto-delete keeps running, all network
/// work stops (see [AccountService.takeOverAccount] to come back).
class AppRuntime {
  AppRuntime(this._s);

  final AppServices _s;

  bool _started = false;
  bool _foreground = true;
  bool _replaced = false;
  Timer? _sweepTimer;
  Timer? _syncTimer;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;

  bool get deviceReplaced => _replaced;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    // New messages while the app is in the background: generic notification.
    _s.sync.onNewMessages = (count) {
      if (!_foreground) unawaited(_s.notifications.show(count));
    };
    _sweepTimer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_sweep()));
    try {
      await scheduleBackgroundSweep();
    } on Object {
      logDebug('background sweep: scheduling failed');
    }
    await _sweep();
    _replaced = await _s.account.isDeviceReplaced();
    if (_replaced) return;

    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground) unawaited(syncNow());
    });
    _authSub = _s.backend.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn || event.event == AuthChangeEvent.tokenRefreshed) {
        _subscribe();
      }
    });
    _subscribe();
    await syncNow();
    try {
      await _s.account.maintainKeys();
      await _s.account.ensureInboxToken();
    } on DeviceReplacedException {
      await _enterReplacedMode();
    } on Object {
      logDebug('inbox token: registration failed');
    }
    if (_replaced) return;
    await _s.push.start(
      onToken: (token) async {
        try {
          await _s.backend.setPushToken(token);
        } on DeviceReplacedException {
          await _enterReplacedMode();
        } on Object {
          logDebug('push: token upload failed');
        }
      },
      onWake: () => unawaited(syncNow()),
    );
  }

  void _subscribe() {
    if (_channel != null || _replaced || _s.backend.userId == null) return;
    try {
      _channel = _s.backend.subscribeToRelay(() => unawaited(syncNow()));
    } on Object {
      logDebug('realtime: subscribe failed');
    }
  }

  Future<void> _unsubscribe() async {
    final channel = _channel;
    _channel = null;
    if (channel == null) return;
    try {
      await _s.backend.unsubscribe(channel);
    } on Object {
      logDebug('realtime: unsubscribe failed');
    }
  }

  Future<void> _sweep() async {
    try {
      final deleted = await _s.sweeper.sweep();
      if (deleted > 0) unawaited(syncNow());
    } on Object {
      logDebug('sweep failed');
    }
  }

  /// One sync pass (pull, process, acknowledge, flush the outbox).
  Future<void> syncNow() async {
    if (!_started || _replaced || _s.backend.userId == null) return;
    try {
      await _s.sync.sync();
    } on DeviceReplacedException {
      await _enterReplacedMode();
    } on Object {
      logDebug('sync failed');
    }
  }

  Future<void> _enterReplacedMode() async {
    if (_replaced) return;
    _replaced = true;
    _syncTimer?.cancel();
    await _s.account.markDeviceReplaced();
    await _unsubscribe();
    await _s.push.stop();
  }

  void onForeground() {
    _foreground = true;
    unawaited(_s.notifications.clear());
    unawaited(_sweep());
    unawaited(syncNow());
  }

  void onBackground() {
    _foreground = false;
  }

  /// Restarts everything, for example after signing in again.
  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> stop() async {
    _sweepTimer?.cancel();
    _syncTimer?.cancel();
    await _authSub?.cancel();
    _authSub = null;
    await _unsubscribe();
    _started = false;
    _replaced = false;
  }
}
