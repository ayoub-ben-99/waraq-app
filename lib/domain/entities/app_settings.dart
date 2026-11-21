import 'reader_settings.dart';

/// Light, dark, true-black AMOLED, or follow the system.
enum AppThemeMode { system, light, dark, amoled }

/// Fallback palettes used when dynamic colour is unavailable or disabled.
enum AccentSeed { indigo, jade, clay, plum, sand }

/// Interface language. Arabic renders right-to-left.
enum AppLanguage { system, english, arabic }

/// Everything the settings screen owns.
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.useDynamicColor = true,
    this.accentSeed = AccentSeed.indigo,
    this.language = AppLanguage.system,
    this.reader = const ReaderSettings(),
  });

  final AppThemeMode themeMode;
  final bool useDynamicColor;
  final AccentSeed accentSeed;
  final AppLanguage language;
  final ReaderSettings reader;

  bool get isAmoled => themeMode == AppThemeMode.amoled;

  /// True when the theme should render dark surfaces.
  bool get prefersDark => themeMode == AppThemeMode.dark || isAmoled;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? useDynamicColor,
    AccentSeed? accentSeed,
    AppLanguage? language,
    ReaderSettings? reader,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      accentSeed: accentSeed ?? this.accentSeed,
      language: language ?? this.language,
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
        other.reader == reader;
  }

  @override
  int get hashCode =>
      Object.hash(themeMode, useDynamicColor, accentSeed, language, reader);
}
