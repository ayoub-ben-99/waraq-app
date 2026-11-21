import 'package:flutter/material.dart';

import '../../domain/entities/app_settings.dart';
import '../theme/tokens.dart';
import 'waraq_palette.dart';

/// Opacity helper that avoids the deprecated `withOpacity` while staying
/// compatible with older Flutter releases.
extension WaraqColorX on Color {
  Color withFraction(double opacity) {
    final int alpha = (255 * opacity.clamp(0.0, 1.0)).round();
    return withAlpha(alpha);
  }
}

Color seedColorOf(AccentSeed seed) {
  return switch (seed) {
    AccentSeed.indigo => const Color(0xFF5B5BD6),
    AccentSeed.jade => const Color(0xFF2F7D6B),
    AccentSeed.clay => const Color(0xFFB4593A),
    AccentSeed.plum => const Color(0xFF8A4CBF),
    AccentSeed.sand => const Color(0xFF9C7B45),
  };
}

/// Builds every theme variant the app can show: light, dark, true-black AMOLED,
/// seeded from the chosen accent or from the wallpaper palette when dynamic
/// colour is available.
abstract final class WaraqTheme {
  static ThemeData lightTheme({
    required AppSettings settings,
    ColorScheme? dynamicScheme,
  }) {
    final ColorScheme scheme = _resolveScheme(
      settings: settings,
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
    );
    return _material(
      scheme: scheme,
      isArabic: _isArabic(settings),
      palette: WaraqPalette.light.copyWith(
        readerBackdrop: scheme.surfaceContainerLow,
        chromeSurface: scheme.surfaceContainerLowest.withFraction(0.94),
      ),
    );
  }

  static ThemeData darkTheme({
    required AppSettings settings,
    ColorScheme? dynamicScheme,
  }) {
    final bool amoled = settings.themeMode == AppThemeMode.amoled;
    ColorScheme scheme = _resolveScheme(
      settings: settings,
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
    );
    if (amoled) {
      scheme = amoledScheme(scheme);
    }
    final WaraqPalette palette = amoled
        ? WaraqPalette.amoled
        : WaraqPalette.dark.copyWith(
            readerBackdrop: scheme.surfaceContainerLowest,
            chromeSurface: scheme.surfaceContainerLow.withFraction(0.94),
          );
    return _material(
      scheme: scheme,
      palette: palette,
      amoled: amoled,
      isArabic: _isArabic(settings),
    );
  }

  /// True-black surfaces for OLED panels. Only the surfaces change; accent,
  /// container and outline roles keep their contrast from the seeded scheme.
  static ColorScheme amoledScheme(ColorScheme base) {
    return base.copyWith(
      surface: Colors.black,
      onSurface: const Color(0xFFE8E5F0),
      surfaceDim: Colors.black,
      surfaceBright: const Color(0xFF2B2833),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0B0A0E),
      surfaceContainer: const Color(0xFF111015),
      surfaceContainerHigh: const Color(0xFF17161C),
      surfaceContainerHighest: const Color(0xFF1E1D25),
      outline: const Color(0xFF8F8C9A),
      outlineVariant: const Color(0xFF2D2B36),
    );
  }

  static ColorScheme _resolveScheme({
    required AppSettings settings,
    required Brightness brightness,
    ColorScheme? dynamicScheme,
  }) {
    if (settings.useDynamicColor && dynamicScheme != null) {
      return dynamicScheme;
    }
    return ColorScheme.fromSeed(
      seedColor: seedColorOf(settings.accentSeed),
      brightness: brightness,
    );
  }

  /// Latin tracking (negative for display sizes) has no place in Arabic, where
  /// letter spacing visually breaks the joins of the script.
  static bool _isArabic(AppSettings settings) {
    return switch (settings.language) {
      AppLanguage.arabic => true,
      AppLanguage.english => false,
      AppLanguage.system =>
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar',
    };
  }

  static ThemeData _material({
    required ColorScheme scheme,
    required WaraqPalette palette,
    required bool isArabic,
    bool amoled = false,
  }) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: amoled ? Colors.black : scheme.surface,
    );
    final TextTheme text = _textTheme(base.textTheme, isArabic: isArabic);

    return base.copyWith(
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[palette],
      canvasColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withFraction(0.6),
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return text.labelSmall?.copyWith(
              letterSpacing: 0.2,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            final bool selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 22,
              color: selected
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            );
          },
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withFraction(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        insetPadding: const EdgeInsets.all(Gap.l),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.xl,
            vertical: Gap.m,
          ),
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 3,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, {required bool isArabic}) {
    double track(double value) => isArabic ? 0 : value;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: track(-1.0),
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 27,
        height: 1.18,
        fontWeight: FontWeight.w600,
        letterSpacing: track(-0.6),
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: track(-0.3),
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: track(-0.2),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.35),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: track(0.3),
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: track(1.1),
      ),
    );
  }

  /// One-off theme used while a document is prepared (never shown to the user
  /// for long, but keeps the loading screen inside the same palette).
  static ThemeData loadingTheme(ColorScheme scheme) {
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
