import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/reading_state_repository.dart';

class BookmarksNotifier extends AsyncNotifier<List<Bookmark>> {
  @override
  Future<List<Bookmark>> build() {
    return ref.watch(readingStateRepositoryProvider).loadBookmarks();
  }

  /// Adds the bookmark for [page] when missing, removes it otherwise.
  /// Returns `true` when a bookmark now exists.
  Future<bool> toggle({required String documentId, required int page}) async {
    final ReadingStateRepository repository =
        ref.read(readingStateRepositoryProvider);
    final List<Bookmark> current =
        state.valueOrNull ?? await repository.loadBookmarks();

    Bookmark? existing;
    for (final Bookmark bookmark in current) {
      if (bookmark.documentId == documentId && bookmark.page == page) {
        existing = bookmark;
        break;
      }
    }

    if (existing != null) {
      await repository.removeBookmark(existing.id);
      state = AsyncData<List<Bookmark>>(<Bookmark>[
        for (final Bookmark bookmark in current)
          if (bookmark.id != existing.id) bookmark,
      ]);
      return false;
    }

    final Bookmark created = Bookmark(
      id: '${documentId}_$page',
      documentId: documentId,
      page: page,
      createdAt: DateTime.now(),
    );
    await repository.saveBookmark(created);
    state = AsyncData<List<Bookmark>>(
      List<Bookmark>.of(<Bookmark>[...current, created])
        ..sort((Bookmark a, Bookmark b) => a.page.compareTo(b.page)),
    );
    return true;
  }

  /// Writes [note] onto the bookmark of [page], creating the bookmark when the
  /// page is not marked yet. An empty [note] keeps the marker but clears the
  /// text, and removes a bookmark that only existed for its note.
  Future<Bookmark?> setNote({
    required String documentId,
    required int page,
    required String note,
  }) async {
    final ReadingStateRepository repository =
        ref.read(readingStateRepositoryProvider);
    final List<Bookmark> current =
        state.valueOrNull ?? await repository.loadBookmarks();
    final String trimmed = note.trim();
    Bookmark? existing;
    for (final Bookmark bookmark in current) {
      if (bookmark.documentId == documentId && bookmark.page == page) {
        existing = bookmark;
        break;
      }
    }

    if (existing == null) {
      if (trimmed.isEmpty) {
        return null;
      }
      final DateTime now = DateTime.now();
      final Bookmark created = Bookmark(
        id: '${documentId}_$page',
        documentId: documentId,
        page: page,
        createdAt: now,
        note: trimmed,
        updatedAt: now,
      );
      await repository.saveBookmark(created);
      state = AsyncData<List<Bookmark>>(
        <Bookmark>[...current, created]
          ..sort((Bookmark a, Bookmark b) => a.page.compareTo(b.page)),
      );
      return created;
    }

    final Bookmark updated = existing.copyWith(
      note: trimmed.isEmpty ? null : trimmed,
      clearNote: trimmed.isEmpty,
      updatedAt: DateTime.now(),
    );
    await repository.saveBookmark(updated);
    state = AsyncData<List<Bookmark>>(<Bookmark>[
      for (final Bookmark bookmark in current)
        if (bookmark.id == updated.id) updated else bookmark,
    ]);
    return updated;
  }

  /// Removes the note text but keeps the page marked.
  Future<void> clearNote(Bookmark bookmark) async {
    final ReadingStateRepository repository =
        ref.read(readingStateRepositoryProvider);
    final Bookmark updated = bookmark.copyWith(
      clearNote: true,
      updatedAt: DateTime.now(),
    );
    await repository.saveBookmark(updated);
    final List<Bookmark> current = state.valueOrNull ?? const <Bookmark>[];
    state = AsyncData<List<Bookmark>>(<Bookmark>[
      for (final Bookmark item in current)
        if (item.id == updated.id) updated else item,
    ]);
  }

  Future<void> remove(Bookmark bookmark) async {
    final ReadingStateRepository repository =
        ref.read(readingStateRepositoryProvider);
    await repository.removeBookmark(bookmark.id);
    final List<Bookmark> current = state.valueOrNull ?? const <Bookmark>[];
    state = AsyncData<List<Bookmark>>(<Bookmark>[
      for (final Bookmark item in current)
        if (item.id != bookmark.id) item,
    ]);
  }
}

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, List<Bookmark>>(
  BookmarksNotifier.new,
);

/// Bookmarks for one document, ordered by page.
final documentBookmarksProvider =
    Provider.family<List<Bookmark>, String>((ref, String documentId) {
  final List<Bookmark> all =
      ref.watch(bookmarksProvider).valueOrNull ?? const <Bookmark>[];
  return <Bookmark>[
    for (final Bookmark bookmark in all)
      if (bookmark.documentId == documentId) bookmark,
  ]..sort((Bookmark a, Bookmark b) => a.page.compareTo(b.page));
});

/// Every written note, newest first, across the whole library.
final notesProvider = Provider<List<Bookmark>>((ref) {
  final List<Bookmark> all =
      ref.watch(bookmarksProvider).valueOrNull ?? const <Bookmark>[];
  return <Bookmark>[
    for (final Bookmark bookmark in all)
      if (bookmark.hasNote) bookmark,
  ]..sort((Bookmark a, Bookmark b) => b.touchedAt.compareTo(a.touchedAt));
});
