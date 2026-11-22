import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/reader_settings.dart';

/// Seed value loaded synchronously before `runApp`, so the first frame already
/// uses the user's theme (no flash of the wrong palette).
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> _commit(AppSettings next) async {
    if (next == state) {
      return;
    }
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) {
    return _commit(state.copyWith(themeMode: mode));
  }

  Future<void> setDynamicColor({required bool enabled}) {
    return _commit(state.copyWith(useDynamicColor: enabled));
  }

  Future<void> setAccent(AccentSeed seed) {
    return _commit(state.copyWith(accentSeed: seed));
  }

  Future<void> setLanguage(AppLanguage language) {
    return _commit(state.copyWith(language: language));
  }

  /// Re-reads what is on disk (used after restoring a backup).
  Future<void> reload() async {
    state = await ref.read(settingsRepositoryProvider).load();
  }

  Future<void> setShapeStyle(ShapeStyle style) {
    return _commit(state.copyWith(shapeStyle: style));
  }

  Future<void> setMotionStyle(MotionStyle style) {
    return _commit(state.copyWith(motionStyle: style));
  }

  Future<void> updateReader(ReaderSettings Function(ReaderSettings) transform) {
    return _commit(state.copyWith(reader: transform(state.reader)));
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Material [ThemeMode] for the current setting. AMOLED is a dark theme with
/// pure black surfaces, so it maps to [ThemeMode.dark].
final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(settingsProvider).themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.amoled => ThemeMode.dark,
  };
});

/// `null` means "follow the device language".
final localeProvider = Provider<Locale?>((ref) {
  return switch (ref.watch(settingsProvider).language) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.arabic => const Locale('ar'),
    AppLanguage.french => const Locale('fr'),
    AppLanguage.spanish => const Locale('es'),
  };
});
