import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/app_settings_dto.dart';
import 'prefs_keys.dart';

class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppSettings> load() async {
    final String? raw = _prefs.getString(PrefsKeys.settings);
    if (raw == null || raw.isEmpty) {
      return const AppSettings();
    }
    try {
      return AppSettingsDto.fromJsonString(raw);
    } catch (_) {
      // Corrupted settings fall back to defaults rather than blocking startup.
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(PrefsKeys.settings, AppSettingsDto.toJsonString(settings));
  }
}
