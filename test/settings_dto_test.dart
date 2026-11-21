import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/data/models/app_settings_dto.dart';
import 'package:waraq/domain/entities/app_settings.dart';
import 'package:waraq/domain/entities/reader_settings.dart';

void main() {
  group('AppSettingsDto', () {
    test('round-trips every field', () {
      const AppSettings settings = AppSettings(
        themeMode: AppThemeMode.amoled,
        useDynamicColor: false,
        accentSeed: AccentSeed.plum,
        language: AppLanguage.arabic,
        reader: ReaderSettings(
          scrollMode: ScrollMode.horizontal,
          pageFilter: PageFilter.sepia,
          autoScrollSpeed: 0.61,
          pageBrightness: 0.25,
        ),
      );

      final AppSettings restored =
          AppSettingsDto.fromJsonString(AppSettingsDto.toJsonString(settings));

      expect(restored, settings);
      expect(restored.isAmoled, isTrue);
      expect(restored.prefersDark, isTrue);
    });

    test('defaults when storage is empty or unknown', () {
      const AppSettings defaults = AppSettings();
      expect(AppSettingsDto.fromMap(<String, Object?>{}), defaults);

      final AppSettings unknown = AppSettingsDto.fromMap(<String, Object?>{
        'themeMode': 'neon',
        'accentSeed': 42,
        'language': 'klingon',
        'useDynamicColor': 'yes please',
        'reader': <String, Object?>{
          'scrollMode': 'sideways',
          'pageFilter': 'vaporwave',
        },
      });
      expect(unknown.themeMode, AppThemeMode.system);
      expect(unknown.accentSeed, AccentSeed.indigo);
      expect(unknown.language, AppLanguage.system);
      expect(unknown.useDynamicColor, isTrue);
      expect(unknown.reader.scrollMode, ScrollMode.vertical);
      expect(unknown.reader.pageFilter, PageFilter.none);
    });

    test('clamps reader values into a usable range', () {
      final AppSettings settings = AppSettingsDto.fromMap(<String, Object?>{
        'reader': <String, Object?>{
          'autoScrollSpeed': 9.5,
          'pageBrightness': -3,
        },
      });
      expect(settings.reader.autoScrollSpeed, 1.0);
      expect(settings.reader.pageBrightness, 0.0);
    });
  });

  group('AppSettings.copyWith', () {
    test('keeps untouched fields', () {
      const AppSettings base = AppSettings(themeMode: AppThemeMode.dark);
      final AppSettings next = base.copyWith(accentSeed: AccentSeed.jade);
      expect(next.themeMode, AppThemeMode.dark);
      expect(next.accentSeed, AccentSeed.jade);
      expect(next.reader, base.reader);
    });
  });

  group('ReaderSettings', () {
    test('compares by value and ignores float noise', () {
      const ReaderSettings a = ReaderSettings(autoScrollSpeed: 0.4);
      const ReaderSettings b = ReaderSettings(autoScrollSpeed: 0.40001);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(pageFilter: PageFilter.night), isFalse);
    });
  });
}
