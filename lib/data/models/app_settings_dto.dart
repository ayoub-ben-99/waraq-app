import 'dart:convert';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/reader_settings.dart';
import 'json_utils.dart';

/// JSON mapping for [AppSettings], isolated from the entity so the domain stays
/// free of storage concerns.
class AppSettingsDto {
  const AppSettingsDto._();

  static AppSettings fromJsonString(String raw) {
    final Object? decoded = jsonDecode(raw);
    return fromMap(readMap(decoded));
  }

  static String toJsonString(AppSettings settings) => jsonEncode(toMap(settings));

  static AppSettings fromMap(Map<String, Object?> map) {
    final Map<String, Object?> reader = readMap(map['reader']);
    return AppSettings(
      themeMode: readEnum(AppThemeMode.values, map['themeMode'], AppThemeMode.system),
      useDynamicColor: readBool(map['useDynamicColor'], true),
      accentSeed: readEnum(AccentSeed.values, map['accentSeed'], AccentSeed.indigo),
      language: readEnum(AppLanguage.values, map['language'], AppLanguage.system),
      reader: ReaderSettings(
        scrollMode:
            readEnum(ScrollMode.values, reader['scrollMode'], ScrollMode.vertical),
        pageFilter: readEnum(PageFilter.values, reader['pageFilter'], PageFilter.none),
        autoScrollSpeed: readDouble(reader['autoScrollSpeed'], 0.32).clamp(0.0, 1.0).toDouble(),
        pageBrightness: readDouble(reader['pageBrightness'], 0.0).clamp(0.0, 0.75).toDouble(),
      ),
    );
  }

  static Map<String, Object?> toMap(AppSettings settings) {
    return <String, Object?>{
      'themeMode': settings.themeMode.name,
      'useDynamicColor': settings.useDynamicColor,
      'accentSeed': settings.accentSeed.name,
      'language': settings.language.name,
      'reader': <String, Object?>{
        'scrollMode': settings.reader.scrollMode.name,
        'pageFilter': settings.reader.pageFilter.name,
        'autoScrollSpeed': settings.reader.autoScrollSpeed,
        'pageBrightness': settings.reader.pageBrightness,
      },
    };
  }
}
