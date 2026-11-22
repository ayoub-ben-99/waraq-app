import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/reading_session.dart';
import '../models/json_utils.dart';
import '../models/reading_session_dto.dart';
import 'prefs_keys.dart';

/// Reading history, newest last. Capped so the preference file stays small.
class LocalSessionRepository {
  LocalSessionRepository(this._prefs);

  static const int maxSessions = 800;

  final SharedPreferences _prefs;

  Future<List<ReadingSession>> load() async {
    final String? raw = _prefs.getString(PrefsKeys.sessions);
    if (raw == null || raw.isEmpty) {
      return const <ReadingSession>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ReadingSession>[];
      }
      final List<ReadingSession> sessions = <ReadingSession>[];
      for (final Object? item in decoded) {
        if (item is! Map) {
          continue;
        }
        final ReadingSession session = ReadingSessionDto.fromMap(readMap(item));
        if (session.id.isNotEmpty && session.documentId.isNotEmpty) {
          sessions.add(session);
        }
      }
      sessions.sort(
        (ReadingSession a, ReadingSession b) =>
            a.startedAt.compareTo(b.startedAt),
      );
      return sessions;
    } catch (_) {
      return const <ReadingSession>[];
    }
  }

  Future<void> add(ReadingSession session) async {
    final List<ReadingSession> sessions = <ReadingSession>[
      ...await load(),
      session,
    ];
    final List<ReadingSession> trimmed = sessions.length <= maxSessions
        ? sessions
        : sessions.sublist(sessions.length - maxSessions);
    await _prefs.setString(
      PrefsKeys.sessions,
      jsonEncode(<Object?>[
        for (final ReadingSession item in trimmed)
          ReadingSessionDto.toMap(item),
      ]),
    );
  }

  Future<void> clear() => _prefs.remove(PrefsKeys.sessions);
}
