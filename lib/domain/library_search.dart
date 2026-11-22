import 'arabic_text.dart';
import 'entities/bookmark.dart';
import 'entities/note_tag.dart';
import 'entities/pdf_document.dart';

/// What a global search found, grouped the way the screen shows it.
class SearchResults {
  const SearchResults({
    this.books = const <PdfDocument>[],
    this.notes = const <Bookmark>[],
    this.tags = const <NoteTag>[],
  });

  final List<PdfDocument> books;
  final List<Bookmark> notes;
  final List<NoteTag> tags;

  int get total => books.length + notes.length + tags.length;

  bool get isEmpty => total == 0;
}

/// Searches books (title and shelf), notes (text and tag names) and tags.
///
/// A one-character query is enough: Arabic words are short, and the reader
/// expects the list to narrow as they type.
SearchResults searchLibrary({
  required String query,
  required List<PdfDocument> documents,
  required List<Bookmark> notes,
  required List<NoteTag> tags,
  int limit = 40,
}) {
  final String needle = normalizeArabic(query);
  if (needle.isEmpty) {
    return const SearchResults();
  }

  final Map<String, NoteTag> tagsById = <String, NoteTag>{
    for (final NoteTag tag in tags) tag.id: tag,
  };

  final List<PdfDocument> books = <PdfDocument>[
    for (final PdfDocument document in documents)
      if (containsQuery(document.title, needle) ||
          containsQuery(document.category, needle))
        document,
  ]..sort((PdfDocument a, PdfDocument b) => a.title.compareTo(b.title));

  final List<Bookmark> matchedNotes = <Bookmark>[
    for (final Bookmark note in notes)
      if (containsQuery(note.note, needle) ||
          note.tagIds.any(
            (String id) => containsQuery(tagsById[id]?.name, needle),
          ))
        note,
  ]..sort((Bookmark a, Bookmark b) => b.touchedAt.compareTo(a.touchedAt));

  final List<NoteTag> matchedTags = <NoteTag>[
    for (final NoteTag tag in tags)
      if (containsQuery(tag.name, needle)) tag,
  ]..sort((NoteTag a, NoteTag b) => a.name.compareTo(b.name));

  return SearchResults(
    books: books.take(limit).toList(growable: false),
    notes: matchedNotes.take(limit).toList(growable: false),
    tags: matchedTags.take(limit).toList(growable: false),
  );
}
