import 'package:flutter/animation.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  AppRadius._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

/// Motion and timing tokens per Emil Design Engineering specifications.
class AppDurations {
  AppDurations._();
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
}

class AppCurves {
  AppCurves._();
  /// Emil Kowalski custom ease-out: cubic-bezier(0.23, 1.0, 0.32, 1.0)
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);
}
