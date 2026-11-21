import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/data_providers.dart';
import 'data/local/prefs_settings_repository.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load settings before the first frame so the app never flashes the wrong
  // theme when it is launched in AMOLED or dark mode.
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final AppSettings settings = await PrefsSettingsRepository(preferences).load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const WaraqApp(),
    ),
  );
}
