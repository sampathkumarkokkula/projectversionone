/// Auto-delete timer options and the free-plan limit.
class TimerOption {
  const TimerOption(this.seconds, this.label);

  /// `null` means Off.
  final int? seconds;
  final String label;
}

/// What the timer menu offers. Chats that still have a 1-hour or 5-hour timer
/// from an earlier version keep it until either person changes it.
const List<TimerOption> timerOptions = [
  TimerOption(null, 'Off'),
  TimerOption(24 * 3600, '1 day'),
  TimerOption(7 * 24 * 3600, '1 week'),
];

/// Longest timer the app offers; longer values from a peer are clamped.
const int maxTimerSeconds = 7 * 24 * 3600;

bool isOfferedTimer(int? seconds) => timerOptions.any((o) => o.seconds == seconds);

/// Values accepted from a peer (also older app versions with 1 h / 5 h).
bool isAcceptableTimer(int? seconds) => seconds == null || (seconds > 0 && seconds <= maxTimerSeconds);

String timerLabel(int? seconds) {
  for (final option in timerOptions) {
    if (option.seconds == seconds) return option.label;
  }
  if (seconds == null) return 'Off';
  if (seconds % 86400 == 0) return '${seconds ~/ 86400} days';
  if (seconds == 3600) return '1 hour';
  if (seconds % 3600 == 0) return '${seconds ~/ 3600} hours';
  return '${(seconds / 60).ceil()} minutes';
}

/// Thrown when enabling a timer would exceed the free-plan limit.
class TimerLimitReached implements Exception {
  const TimerLimitReached();

  @override
  String toString() => 'TimerLimitReached';
}

abstract final class TimerPolicy {
  /// Free version: at most this many chats may have a timer at the same time.
  static const int maxTimerChatsFree = 2;

  /// Whether this user may switch a chat from [current] to [next].
  ///
  /// Turning a timer off, or changing the duration of a chat that already has
  /// one, is always allowed. Turning one on is blocked when
  /// [otherTimerChats] already reaches the limit.
  static bool canChange({
    required int? current,
    required int? next,
    required int otherTimerChats,
  }) {
    if (next == null || current != null) return true;
    return otherTimerChats < maxTimerChatsFree;
  }
}
