/// A remembered place inside a document.
class ReadingPosition {
  const ReadingPosition({
    required this.documentId,
    required this.page,
    required this.progress,
    required this.updatedAt,
    this.offsetFraction = 0,
  });

  final String documentId;

  /// 1-based page number.
  final int page;

  /// 0..1 across the whole document.
  final double progress;

  /// 0..1 inside the current page, so reopening resumes mid-page.
  final double offsetFraction;

  final DateTime updatedAt;

  ReadingPosition copyWith({
    int? page,
    double? progress,
    double? offsetFraction,
    DateTime? updatedAt,
  }) {
    return ReadingPosition(
      documentId: documentId,
      page: page ?? this.page,
      progress: progress ?? this.progress,
      offsetFraction: offsetFraction ?? this.offsetFraction,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get percentComplete => (progress.clamp(0.0, 1.0) * 100).round();

  @override
  bool operator ==(Object other) {
    return other is ReadingPosition &&
        other.documentId == documentId &&
        other.page == page &&
        other.progress == progress &&
        other.offsetFraction == offsetFraction &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(documentId, page, progress, offsetFraction, updatedAt);
}
