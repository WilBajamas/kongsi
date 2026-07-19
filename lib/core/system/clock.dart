abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}
