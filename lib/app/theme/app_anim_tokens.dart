import 'package:flutter/animation.dart';

abstract final class AppMotion {
  // Durations.
  static const micro = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 240);
  static const emphasis = Duration(milliseconds: 320);
  static const signature = Duration(milliseconds: 520);

  // Easing curves.
  static const signatureOut = Cubic(0.16, 1, 0.3, 1);
  static const standard = Cubic(0.4, 0, 0.2, 1);
  static const exit = Cubic(0.4, 0, 1, 1);
}
