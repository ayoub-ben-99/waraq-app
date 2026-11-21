import 'reader_settings.dart';

/// Light, dark, true-black AMOLED, or follow the system.
enum AppThemeMode { system, light, dark, amoled }

/// Fallback palettes used when dynamic colour is unavailable or disabled.
enum AccentSeed { indigo, jade, clay, plum, sand }

/// Interface language. Arabic renders right-to-left.
enum AppLanguage { system, english, arabic }

/// Corner language of the interface, in the spirit of Material 3 shape scales.
enum ShapeStyle {
  /// Calm 10–16 dp corners. Default.
  soft,

  /// Generous 20–32 dp corners, closer to the Material 3 "expressive" scale.
  rounded,

  /// Near-square corners for a document, paper-like feel.
  square,
}

/// How much the interface moves.
enum MotionStyle {
  /// Full motion: staggered reveals, sliding chrome, cross-faded themes.
  full,

  /// Shorter, straighter transitions with no staggering.
  reduced,

  /// Instant state changes. Also what "remove animations" accessibility users want.
  off,
}

/// Everything the settings screen owns.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.useDynamicColor = true,
    this.accentSeed = AccentSeed.indigo,
    this.language = AppLanguage.system,
    this.shapeStyle = ShapeStyle.soft,
    this.motionStyle = MotionStyle.full,
    this.reader = const ReaderSettings(),
  });

  final AppThemeMode themeMode;
  final bool useDynamicColor;
  final AccentSeed accentSeed;
  final AppLanguage language;
  final ShapeStyle shapeStyle;
  final MotionStyle motionStyle;
  final ReaderSettings reader;

  bool get isAmoled => themeMode == AppThemeMode.amoled;

  /// True when the theme should render dark surfaces.
  bool get prefersDark => themeMode == AppThemeMode.dark || isAmoled;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? useDynamicColor,
    AccentSeed? accentSeed,
    AppLanguage? language,
    ShapeStyle? shapeStyle,
    MotionStyle? motionStyle,
    ReaderSettings? reader,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      accentSeed: accentSeed ?? this.accentSeed,
      language: language ?? this.language,
      shapeStyle: shapeStyle ?? this.shapeStyle,
      motionStyle: motionStyle ?? this.motionStyle,
      reader: reader ?? this.reader,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.useDynamicColor == useDynamicColor &&
        other.accentSeed == accentSeed &&
        other.language == language &&
        other.shapeStyle == shapeStyle &&
        other.motionStyle == motionStyle &&
        other.reader == reader;
  }

  @override
  int get hashCode =>
      Object.hash(
        themeMode,
        useDynamicColor,
        accentSeed,
        language,
        shapeStyle,
        motionStyle,
        reader,
      );
}
