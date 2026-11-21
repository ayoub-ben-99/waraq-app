import 'package:flutter/material.dart';

import '../../domain/entities/app_settings.dart';
import 'tokens.dart';

/// Corner scale for the selected [ShapeStyle].
///
/// Lives in the theme so a single setting reshapes cards, sheets, dialogs and
/// the reader chrome at once. Values interpolate with the theme animation, so
/// switching between styles eases instead of snapping.
@immutable
class WaraqShape extends ThemeExtension<WaraqShape> {
  const WaraqShape({
    required this.style,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  /// Calm, Material 3 default-ish corners.
  static const WaraqShape soft = WaraqShape(
    style: ShapeStyle.soft,
    xs: Radii.xs,
    sm: Radii.sm,
    md: Radii.md,
    lg: Radii.lg,
    xl: Radii.xl,
  );

  /// Generous corners, closer to the Material 3 expressive scale.
  static const WaraqShape rounded = WaraqShape(
    style: ShapeStyle.rounded,
    xs: 10,
    sm: 16,
    md: 22,
    lg: 28,
    xl: 34,
  );

  /// Paper-like, nearly square corners.
  static const WaraqShape square = WaraqShape(
    style: ShapeStyle.square,
    xs: 2,
    sm: 4,
    md: 6,
    lg: 8,
    xl: 12,
  );

  final ShapeStyle style;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  static WaraqShape forStyle(ShapeStyle style) {
    return switch (style) {
      ShapeStyle.soft => soft,
      ShapeStyle.rounded => rounded,
      ShapeStyle.square => square,
    };
  }

  static WaraqShape of(BuildContext context) {
    return Theme.of(context).extension<WaraqShape>() ?? soft;
  }

  /// Pills stay pills unless the user asked for square corners.
  double get pill => style == ShapeStyle.square ? sm : Radii.pill;

  Radius get topXl => Radius.circular(xl);

  BorderRadius get allSm => BorderRadius.circular(sm);
  BorderRadius get allMd => BorderRadius.circular(md);
  BorderRadius get allLg => BorderRadius.circular(lg);
  BorderRadius get allXl => BorderRadius.circular(xl);
  BorderRadius get allPill => BorderRadius.circular(pill);

  @override
  WaraqShape copyWith({
    ShapeStyle? style,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return WaraqShape(
      style: style ?? this.style,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  WaraqShape lerp(ThemeExtension<WaraqShape>? other, double t) {
    if (other is! WaraqShape) {
      return this;
    }
    return WaraqShape(
      style: t < 0.5 ? style : other.style,
      xs: _lerp(xs, other.xs, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Motion budget for the selected [MotionStyle].
///
/// Widgets ask this instead of using [Motion] directly, so "reduced" and "off"
/// are honoured everywhere at once.
@immutable
class WaraqMotion extends ThemeExtension<WaraqMotion> {
  const WaraqMotion({
    required this.style,
    required this.scale,
    required this.stagger,
  });

  static const WaraqMotion full = WaraqMotion(
    style: MotionStyle.full,
    scale: 1,
    stagger: Motion.stagger,
  );

  static const WaraqMotion reduced = WaraqMotion(
    style: MotionStyle.reduced,
    scale: 0.5,
    stagger: Duration.zero,
  );

  static const WaraqMotion off = WaraqMotion(
    style: MotionStyle.off,
    scale: 0,
    stagger: Duration.zero,
  );

  final MotionStyle style;
  final double scale;
  final Duration stagger;

  static WaraqMotion forStyle(MotionStyle style) {
    return switch (style) {
      MotionStyle.full => full,
      MotionStyle.reduced => reduced,
      MotionStyle.off => off,
    };
  }

  static WaraqMotion of(BuildContext context) {
    return Theme.of(context).extension<WaraqMotion>() ?? full;
  }

  bool get enabled => scale > 0;

  /// Scales [base] by the user's motion setting (`Duration.zero` when off).
  Duration scaled(Duration base) {
    if (scale <= 0) {
      return Duration.zero;
    }
    return Duration(microseconds: (base.inMicroseconds * scale).round());
  }

  Duration get tap => scaled(Motion.tap);
  Duration get fast => scaled(Motion.fast);
  Duration get base => scaled(Motion.base);
  Duration get slow => scaled(Motion.slow);
  Duration get theme => scaled(Motion.theme);

  @override
  WaraqMotion copyWith({
    MotionStyle? style,
    double? scale,
    Duration? stagger,
  }) {
    return WaraqMotion(
      style: style ?? this.style,
      scale: scale ?? this.scale,
      stagger: stagger ?? this.stagger,
    );
  }

  @override
  WaraqMotion lerp(ThemeExtension<WaraqMotion>? other, double t) {
    if (other is! WaraqMotion) {
      return this;
    }
    return WaraqMotion(
      style: t < 0.5 ? style : other.style,
      scale: scale + (other.scale - scale) * t,
      stagger: Duration(
        microseconds:
            (stagger.inMicroseconds + (other.stagger.inMicroseconds - stagger.inMicroseconds) * t).round(),
      ),
    );
  }
}
