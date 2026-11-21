import 'package:flutter/animation.dart';

/// Spacing scale on a 4dp grid.
abstract final class Gap {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii. Soft surfaces are a core part of the visual language.
abstract final class Radii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

/// Durations and curves shared by every animation in the app.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration theme = Duration(milliseconds: 480);

  /// How long the floating page indicator lingers after a scroll.
  static const Duration idle = Duration(milliseconds: 1400);

  /// Reveal / press feedback duration.
  static const Duration tap = Duration(milliseconds: 120);

  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve accelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Stagger between list items on first paint.
  static const Duration stagger = Duration(milliseconds: 40);
}

/// Fixed layout metrics for the reader and the library.
abstract final class Sizes {
  /// Pages never stretch beyond this width, which keeps line lengths readable
  /// on tablets and foldables while leaving generous side margins.
  static const double readerPageMaxWidth = 720;

  /// Horizontal gutter around the page canvas.
  static const double readerGutter = 16;

  /// Vertical air between two pages in continuous mode.
  static const double readerPageSpacing = 12;

  /// Height of the floating chrome that holds the scrubber and the tools.
  static const double readerDockMargin = 12;

  static const double thumbnailWidth = 58;
  static const double thumbnailHeight = 78;
  static const double thumbnailRadius = 10;

  static const double maxContentWidth = 880;
}
