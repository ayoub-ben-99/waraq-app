import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/document_repository.dart';
import '../domain/repositories/reading_state_repository.dart';
import '../domain/repositories/review_repository.dart';
import '../domain/repositories/settings_repository.dart';
import 'local/local_document_repository.dart';
import 'local/local_reading_state_repository.dart';
import 'local/local_review_repository.dart';
import 'local/prefs_settings_repository.dart';

/// Overridden in `main()` once [SharedPreferences] has been loaded.
final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  );
});

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) {
  return PrefsSettingsRepository(ref.watch(sharedPreferencesProvider));
});

final readingStateRepositoryProvider =
    Provider<ReadingStateRepository>((ref) {
  return LocalReadingStateRepository(ref.watch(sharedPreferencesProvider));
});

final documentRepositoryProvider =
    Provider<DocumentRepository>((ref) {
  return LocalDocumentRepository(ref.watch(sharedPreferencesProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return LocalReviewRepository(ref.watch(sharedPreferencesProvider));
});
