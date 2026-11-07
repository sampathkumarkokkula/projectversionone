/// Wall-clock source, injectable so the timer sweep can be tested.
abstract interface class Clock {
  /// Milliseconds since the Unix epoch.
  int nowMs();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}
