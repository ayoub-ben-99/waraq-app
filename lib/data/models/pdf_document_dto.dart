import '../../domain/entities/pdf_document.dart';
import 'json_utils.dart';

class PdfDocumentDto {
  const PdfDocumentDto._();

  static PdfDocument fromMap(Map<String, Object?> map) {
    final DateTime addedAt = readDate(map['addedAt'], DateTime.now());
    final String? thumbnail = map['thumbnailPath'] is String
        ? map['thumbnailPath'] as String
        : null;
    final DateTime? lastOpened = map['lastOpenedAt'] == null
        ? null
        : readDate(map['lastOpenedAt'], addedAt);
    final String category = readString(map['category'], '');
    return PdfDocument(
      id: readString(map['id'], ''),
      title: readString(map['title'], 'Untitled'),
      filePath: readString(map['filePath'], ''),
      pageCount: readInt(map['pageCount'], 1),
      sizeBytes: readInt(map['sizeBytes'], 0),
      addedAt: addedAt,
      thumbnailPath: thumbnail,
      lastOpenedAt: lastOpened,
      category: category.isEmpty ? null : category,
    );
  }

  static Map<String, Object?> toMap(PdfDocument document) {
    return <String, Object?>{
      'id': document.id,
      'title': document.title,
      'filePath': document.filePath,
      'pageCount': document.pageCount,
      'sizeBytes': document.sizeBytes,
      'addedAt': document.addedAt.toIso8601String(),
      'thumbnailPath': document.thumbnailPath,
      'lastOpenedAt': document.lastOpenedAt?.toIso8601String(),
      if (document.category != null && document.category!.isNotEmpty)
        'category': document.category,
    };
  }
}
