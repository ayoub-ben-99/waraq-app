import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/review_repository.dart';
import '../../domain/review_scheduler.dart';
import '../models/json_utils.dart';
import '../models/review_schedule_dto.dart';
import 'prefs_keys.dart';

/// Keeps the whole ladder map in one JSON blob; it is a few bytes per note.
class LocalReviewRepository implements ReviewRepository {
  LocalReviewRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Map<String, ReviewSchedule>> load() async {
    final String? raw = _prefs.getString(PrefsKeys.review);
    if (raw == null || raw.isEmpty) {
      return <String, ReviewSchedule>{};
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, ReviewSchedule>{};
      }
      return <String, ReviewSchedule>{
        for (final MapEntry<Object?, Object?> entry in decoded.entries)
          if (entry.value is Map)
            '${entry.key}': ReviewScheduleDto.fromMap(readMap(entry.value)),
      };
    } catch (_) {
      return <String, ReviewSchedule>{};
    }
  }

  @override
  Future<void> save(Map<String, ReviewSchedule> schedules) async {
    await _prefs.setString(
      PrefsKeys.review,
      jsonEncode(<String, Object?>{
        for (final MapEntry<String, ReviewSchedule> entry in schedules.entries)
          entry.key: ReviewScheduleDto.toMap(entry.value),
      }),
    );
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(PrefsKeys.review);
  }
}
