import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/note_tag.dart';
import '../../domain/repositories/tag_repository.dart';
import 'bookmark_providers.dart';

/// The reader's tag vocabulary plus the notes that use it.
class TagsNotifier extends AsyncNotifier<List<NoteTag>> {
  @override
  Future<List<NoteTag>> build() {
    return ref.watch(tagRepositoryProvider).load();
  }

  Future<NoteTag> create(String name, {int? colorIndex}) async {
    final String trimmed = name.trim();
    final List<NoteTag> current = state.valueOrNull ?? const <NoteTag>[];
    for (final NoteTag tag in current) {
      if (tag.name.toLowerCase() == trimmed.toLowerCase()) {
        return tag;
      }
    }
    final NoteTag created = NoteTag(
      id: 'tag${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      name: trimmed,
      colorIndex: colorIndex ?? current.length % kTagColors.length,
    );
    final List<NoteTag> next = <NoteTag>[...current, created];
    await _commit(next);
    return created;
  }

  Future<void> rename(NoteTag tag, String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final List<NoteTag> current = state.valueOrNull ?? const <NoteTag>[];
    await _commit(<NoteTag>[
      for (final NoteTag item in current)
        if (item.id == tag.id) item.copyWith(name: trimmed) else item,
    ]);
  }

  /// Deletes a tag and strips it from every note that used it.
  Future<void> delete(NoteTag tag) async {
    final TagRepository repository = ref.read(tagRepositoryProvider);
    final List<NoteTag> current =
        state.valueOrNull ?? await repository.load();
    final List<NoteTag> next = <NoteTag>[
      for (final NoteTag item in current)
        if (item.id != tag.id) item,
    ];
    await _commit(next);

    final BookmarksNotifier bookmarks = ref.read(bookmarksProvider.notifier);
    final List<Bookmark> notes =
        ref.read(bookmarksProvider).valueOrNull ?? const <Bookmark>[];
    for (final Bookmark note in notes) {
      if (note.tagIds.contains(tag.id)) {
        await bookmarks.setTags(
          note.id,
          <String>[
            for (final String id in note.tagIds)
              if (id != tag.id) id,
          ],
        );
      }
    }
  }

  Future<void> _commit(List<NoteTag> next) async {
    state = AsyncData<List<NoteTag>>(next);
    await ref.read(tagRepositoryProvider).save(next);
  }
}

final tagsProvider = AsyncNotifierProvider<TagsNotifier, List<NoteTag>>(
  TagsNotifier.new,
);

final tagsByIdProvider = Provider<Map<String, NoteTag>>((ref) {
  final List<NoteTag> tags = ref.watch(tagsProvider).valueOrNull ?? const <NoteTag>[];
  return <String, NoteTag>{for (final NoteTag tag in tags) tag.id: tag};
});
