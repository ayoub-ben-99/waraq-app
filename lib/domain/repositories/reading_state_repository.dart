import '../entities/bookmark.dart';
import '../entities/reading_position.dart';

/// Persists where the reader stopped and which pages were marked.
abstract interface class ReadingStateRepository {
  Future<Map<String, ReadingPosition>> loadPositions();

  Future<void> savePosition(ReadingPosition position);

  Future<List<Bookmark>> loadBookmarks();

  Future<void> saveBookmark(Bookmark bookmark);

  Future<void> removeBookmark(String bookmarkId);

  /// Drops the position and every bookmark that belongs to one document.
  Future<void> forget(String documentId);

  Future<void> clearAll();
}
