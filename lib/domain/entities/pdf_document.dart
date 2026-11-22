/// A PDF that lives in the user's library. Files are copied into the app's
/// private storage on import, so this object owns a stable path.
class PdfDocument {
  const PdfDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.pageCount,
    required this.sizeBytes,
    required this.addedAt,
    this.thumbnailPath,
    this.lastOpenedAt,
    this.category,
  });

  final String id;
  final String title;
  final String filePath;
  final int pageCount;
  final int sizeBytes;
  final DateTime addedAt;
  final String? thumbnailPath;
  final DateTime? lastOpenedAt;

  /// Free-form shelf label written by the reader ("روايات", "عمل"…).
  final String? category;

  PdfDocument copyWith({
    String? title,
    String? filePath,
    int? pageCount,
    int? sizeBytes,
    DateTime? addedAt,
    String? thumbnailPath,
    DateTime? lastOpenedAt,
    String? category,
    bool clearCategory = false,
  }) {
    return PdfDocument(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      pageCount: pageCount ?? this.pageCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      addedAt: addedAt ?? this.addedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PdfDocument &&
        other.id == id &&
        other.title == title &&
        other.filePath == filePath &&
        other.pageCount == pageCount &&
        other.sizeBytes == sizeBytes &&
        other.addedAt == addedAt &&
        other.thumbnailPath == thumbnailPath &&
        other.lastOpenedAt == lastOpenedAt &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        filePath,
        pageCount,
        sizeBytes,
        addedAt,
        thumbnailPath,
        lastOpenedAt,
        category,
      );
}
