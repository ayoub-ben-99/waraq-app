import '../entities/note_tag.dart';

/// Stores the reader's own tag vocabulary.
abstract interface class TagRepository {
  Future<List<NoteTag>> load();

  Future<void> save(List<NoteTag> tags);
}
