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
  }) {
    return Bookmark(
      id: id,
      documentId: documentId,
      page: page ?? this.page,
      createdAt: createdAt,
      note: clearNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
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
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, documentId, page, createdAt, note, updatedAt);
}
