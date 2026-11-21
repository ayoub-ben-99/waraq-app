/// A page the reader wants to come back to.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.documentId,
    required this.page,
    required this.createdAt,
  });

  final String id;
  final String documentId;

  /// 1-based page number.
  final int page;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return other is Bookmark &&
        other.id == id &&
        other.documentId == documentId &&
        other.page == page &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, documentId, page, createdAt);
}
