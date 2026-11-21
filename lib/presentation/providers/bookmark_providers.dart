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
