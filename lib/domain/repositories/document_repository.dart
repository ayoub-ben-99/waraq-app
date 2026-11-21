import 'dart:typed_data';

import '../entities/pdf_document.dart';

/// Failure raised when a file cannot be copied, opened or measured.
class DocumentException implements Exception {
  const DocumentException(this.message);

  final String message;

  @override
  String toString() => 'DocumentException: $message';
}

/// Owns the library: imported files, their metadata and their thumbnails.
abstract interface class DocumentRepository {
  Future<List<PdfDocument>> listDocuments();

  /// Copies a PDF into private storage, reads its page count and renders a
  /// cover thumbnail. Accepts either a filesystem [sourcePath] or raw [bytes].
  Future<PdfDocument> importPdf({
    String? sourcePath,
    String? displayName,
    Uint8List? bytes,
  });

  /// Adds the bundled sample document once, so the library is never empty.
  Future<void> ensureBundledSample();

  Future<void> deleteDocument(String documentId);

  /// Records that the document was opened, for the "recent" ordering.
  Future<PdfDocument> markOpened(String documentId);

  /// Returns the thumbnail path, rendering it if it is missing.
  Future<String?> ensureThumbnail(PdfDocument document);
}
