import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/bookmark.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/repositories/reading_state_repository.dart';
import '../models/bookmark_dto.dart';
import '../models/json_utils.dart';
import '../models/reading_position_dto.dart';
import 'prefs_keys.dart';

/// Stores positions and bookmarks as JSON in [SharedPreferences]. The payloads
/// stay small (a few hundred bytes per document), so no database is needed.
class LocalReadingStateRepository implements ReadingStateRepository {
  LocalReadingStateRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Map<String, ReadingPosition>> loadPositions() async {
    final List<ReadingPosition> positions = _readPositions();
    return <String, ReadingPosition>{
      for (final ReadingPosition position in positions) position.documentId: position,
    };
  }

  @override
  Future<void> savePosition(ReadingPosition position) async {
    final Map<String, ReadingPosition> positions = await loadPositions();
    positions[position.documentId] = position;
    final List<Map<String, Object?>> payload = positions.values
        .map(ReadingPositionDto.toMap)
        .toList(growable: false);
    await _prefs.setString(PrefsKeys.positions, jsonEncode(payload));
  }

  @override
  Future<List<Bookmark>> loadBookmarks() async {
    final String? raw = _prefs.getString(PrefsKeys.bookmarks);
    final List<Bookmark> bookmarks = <Bookmark>[];
    for (final Map<String, Object?> map in _decodeList(raw)) {
      final Bookmark bookmark = BookmarkDto.fromMap(map);
      if (bookmark.documentId.isNotEmpty) {
        bookmarks.add(bookmark);
      }
    }
    bookmarks.sort((Bookmark a, Bookmark b) => a.createdAt.compareTo(b.createdAt));
    return bookmarks;
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    final List<Bookmark> bookmarks = await loadBookmarks();
    final bool exists = bookmarks.any((Bookmark item) => item.id == bookmark.id);
    if (!exists) {
      bookmarks.add(bookmark);
    }
    await _writeBookmarks(bookmarks);
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    final List<Bookmark> bookmarks = await loadBookmarks();
    bookmarks.removeWhere((Bookmark item) => item.id == bookmarkId);
    await _writeBookmarks(bookmarks);
  }

  @override
  Future<void> forget(String documentId) async {
    final Map<String, ReadingPosition> positions = await loadPositions();
    if (positions.remove(documentId) != null) {
      final List<Map<String, Object?>> payload =
          positions.values.map(ReadingPositionDto.toMap).toList(growable: false);
      await _prefs.setString(PrefsKeys.positions, jsonEncode(payload));
    }
    final List<Bookmark> bookmarks = await loadBookmarks();
    final int before = bookmarks.length;
    bookmarks.removeWhere((Bookmark item) => item.documentId == documentId);
    if (bookmarks.length != before) {
      await _writeBookmarks(bookmarks);
    }
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(PrefsKeys.positions);
    await _prefs.remove(PrefsKeys.bookmarks);
  }

  List<ReadingPosition> _readPositions() {
    final String? raw = _prefs.getString(PrefsKeys.positions);
    final List<ReadingPosition> positions = <ReadingPosition>[];
    for (final Map<String, Object?> map in _decodeList(raw)) {
      final ReadingPosition position = ReadingPositionDto.fromMap(map);
      if (position.documentId.isNotEmpty) {
        positions.add(position);
      }
    }
    return positions;
  }

  List<Map<String, Object?>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Map<String, Object?>>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(readMap)
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, Object?>>[];
    }
  }

  Future<void> _writeBookmarks(List<Bookmark> bookmarks) async {
    final List<Map<String, Object?>> payload =
        bookmarks.map(BookmarkDto.toMap).toList(growable: false);
    await _prefs.setString(PrefsKeys.bookmarks, jsonEncode(payload));
  }
}
