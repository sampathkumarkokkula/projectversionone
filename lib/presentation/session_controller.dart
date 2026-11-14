import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'providers.dart';

enum AppPhase { onboarding, locked, unlocked, deleted }

@immutable
class SessionState {
  const SessionState(this.phase, [this.mode = UnlockMode.normal]);

  final AppPhase phase;

  /// Which password unlocked this session. Kept in memory only and never
  /// shown anywhere.
  final UnlockMode mode;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// App lock state: password on every launch, 60-second grace period when
/// switching apps, no biometrics.
class SessionController extends Notifier<SessionState> {
  static const Duration gracePeriod = Duration(seconds: 60);

  int? _hiddenAt;
  Timer? _graceTimer;

  @override
  SessionState build() {
    ref.onDispose(() => _graceTimer?.cancel());
    final setUp = ref.watch(setupCompleteProvider);
    return SessionState(setUp ? AppPhase.locked : AppPhase.onboarding);
  }

  /// Verifies the password. A secondary-password unlock first wipes every
  /// timer-enabled chat (and queues wipe commands to the peers), then unlocks
  /// exactly like the main password: same screens, same timing, no message.
  Future<UnlockResult> unlock(String password) async {
    final services = ref.read(servicesProvider);
    final result = await services.lock.attemptUnlock(password);
    switch (result) {
      case UnlockResult.normal:
        state = const SessionState(AppPhase.unlocked, UnlockMode.normal);
      case UnlockResult.duress:
        try {
          await services.wipe.duressWipe();
        } on Object {
          // Never reveal the protected chats. A failed wipe looks exactly like
          // a mistyped password, so the next attempt simply tries again.
          return UnlockResult.invalid;
        }
        state = const SessionState(AppPhase.unlocked, UnlockMode.duress);
      case UnlockResult.invalid:
        return result;
    }
    unawaited(ref.read(runtimeProvider).syncNow());
    // Android 13+: ask once for permission to show new-message alerts.
    unawaited(services.notifications.requestPermission());
    return result;
  }

  /// Registration or new-device sign-in finished: unlocked with the main
  /// password that was just chosen.
  void finishOnboarding() {
    state = const SessionState(AppPhase.unlocked, UnlockMode.normal);
    unawaited(ref.read(runtimeProvider).start());
    unawaited(ref.read(servicesProvider).notifications.requestPermission());
  }

  /// Password reset finished: new passwords are set. The reset signed this
  /// phone in again, so the runtime restarts its server connection.
  void finishPasswordReset() {
    state = const SessionState(AppPhase.unlocked, UnlockMode.normal);
    unawaited(ref.read(runtimeProvider).restart());
  }

  void lock() {
    _graceTimer?.cancel();
    if (state.phase == AppPhase.unlocked) state = const SessionState(AppPhase.locked);
  }

  /// The account and all local data are gone; only "close the app" remains.
  void markDeleted() {
    _graceTimer?.cancel();
    state = const SessionState(AppPhase.deleted);
  }

  void appHidden() {
    _hiddenAt = ref.read(servicesProvider).clock.nowMs();
    _graceTimer?.cancel();
    if (state.phase == AppPhase.unlocked) _graceTimer = Timer(gracePeriod, lock);
  }

  void appShown() {
    _graceTimer?.cancel();
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null) return;
    final away = ref.read(servicesProvider).clock.nowMs() - hiddenAt;
    if (away >= gracePeriod.inMilliseconds) lock();
  }
}
