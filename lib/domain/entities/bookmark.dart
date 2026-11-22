bool _sameTags(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (int index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// A page the reader wants to come back to, optionally carrying a note.
///
/// A bookmark without a note is just a marker; once [note] is set the same
/// record becomes a written note, which is what the Notes screen lists.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.documentId,
    required this.page,
    required this.createdAt,
    this.note,
    this.updatedAt,
    this.tagIds = const <String>[],
  });

  final String id;
  final String documentId;

  /// 1-based page number.
  final int page;
  final DateTime createdAt;

  /// Free text written by the reader, `null` when the page is only marked.
  final String? note;

  /// Last time the note text changed; falls back to [createdAt] when absent.
  final DateTime? updatedAt;

  /// Ids of the tags attached to this note.
  final List<String> tagIds;

  bool get hasNote {
    final String? text = note;
    return text != null && text.trim().isNotEmpty;
  }

  DateTime get touchedAt => updatedAt ?? createdAt;

  Bookmark copyWith({
    int? page,
    String? note,
    bool clearNote = false,
    DateTime? updatedAt,
    List<String>? tagIds,
  }) {
    return Bookmark(
      id: id,
      documentId: documentId,
      page: page ?? this.page,
      createdAt: createdAt,
      note: clearNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Bookmark &&
        other.id == id &&
        other.documentId == documentId &&
        other.page == page &&
        other.createdAt == createdAt &&
        other.note == note &&
        other.updatedAt == updatedAt &&
        _sameTags(other.tagIds, tagIds);
  }

  @override
  int get hashCode => Object.hash(
        id,
        documentId,
        page,
        createdAt,
        note,
        updatedAt,
        Object.hashAll(tagIds),
      );
}
