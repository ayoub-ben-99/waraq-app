import 'package:flutter/material.dart';

/// Semantic colors that the Material [ColorScheme] does not express:
/// the paper-like page surface, the dimmed reader backdrop and the floating
/// chrome used by the reader. Registered as a [ThemeExtension] so widgets read
/// them from the theme instead of hardcoding values.
@immutable
class WaraqPalette extends ThemeExtension<WaraqPalette> {
  const WaraqPalette({
    required this.readerBackdrop,
    required this.pageSurface,
    required this.pageBorder,
    required this.pageShadow,
    required this.chromeSurface,
    required this.chromeBorder,
    required this.immersiveHairline,
  });

  /// The surface behind PDF pages.
  final Color readerBackdrop;

  /// The paper of a rendered PDF page (white in light mode, deep grey in dark).
  final Color pageSurface;

  final Color pageBorder;
  final Color pageShadow;

  /// Frosted-looking (but cheap) surface used by the floating toolbars.
  final Color chromeSurface;
  final Color chromeBorder;

  /// Thin progress line shown while the chrome is hidden.
  final Color immersiveHairline;

  static const WaraqPalette light = WaraqPalette(
    readerBackdrop: Color(0xFFEFEDF4),
    pageSurface: Color(0xFFFFFFFF),
    pageBorder: Color(0x14000000),
    pageShadow: Color(0x1A2B2440),
    chromeSurface: Color(0xF7FBF8FF),
    chromeBorder: Color(0x14000000),
    immersiveHairline: Color(0x33000000),
  );

  static const WaraqPalette dark = WaraqPalette(
    readerBackdrop: Color(0xFF121116),
    pageSurface: Color(0xFF1C1B20),
    pageBorder: Color(0x1FFFFFFF),
    pageShadow: Color(0x66000000),
    chromeSurface: Color(0xF71A1920),
    chromeBorder: Color(0x1FFFFFFF),
    immersiveHairline: Color(0x33FFFFFF),
  );

  /// Pure black variant used by the AMOLED theme.
  static const WaraqPalette amoled = WaraqPalette(
    readerBackdrop: Color(0xFF000000),
    pageSurface: Color(0xFF08080A),
    pageBorder: Color(0x24FFFFFF),
    pageShadow: Color(0x00000000),
    chromeSurface: Color(0xFF070709),
    chromeBorder: Color(0x1FFFFFFF),
    immersiveHairline: Color(0x40FFFFFF),
  );

  @override
  WaraqPalette copyWith({
    Color? readerBackdrop,
    Color? pageSurface,
    Color? pageBorder,
    Color? pageShadow,
    Color? chromeSurface,
    Color? chromeBorder,
    Color? immersiveHairline,
  }) {
    return WaraqPalette(
      readerBackdrop: readerBackdrop ?? this.readerBackdrop,
      pageSurface: pageSurface ?? this.pageSurface,
      pageBorder: pageBorder ?? this.pageBorder,
      pageShadow: pageShadow ?? this.pageShadow,
      chromeSurface: chromeSurface ?? this.chromeSurface,
      chromeBorder: chromeBorder ?? this.chromeBorder,
      immersiveHairline: immersiveHairline ?? this.immersiveHairline,
    );
  }

  @override
  WaraqPalette lerp(ThemeExtension<WaraqPalette>? other, double t) {
    if (other is! WaraqPalette) {
      return this;
    }
    return WaraqPalette(
      readerBackdrop: Color.lerp(readerBackdrop, other.readerBackdrop, t)!,
      pageSurface: Color.lerp(pageSurface, other.pageSurface, t)!,
      pageBorder: Color.lerp(pageBorder, other.pageBorder, t)!,
      pageShadow: Color.lerp(pageShadow, other.pageShadow, t)!,
      chromeSurface: Color.lerp(chromeSurface, other.chromeSurface, t)!,
      chromeBorder: Color.lerp(chromeBorder, other.chromeBorder, t)!,
      immersiveHairline:
          Color.lerp(immersiveHairline, other.immersiveHairline, t)!,
    );
  }

  static WaraqPalette of(BuildContext context) {
    return Theme.of(context).extension<WaraqPalette>() ?? light;
  }
}
