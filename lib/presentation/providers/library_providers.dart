import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/repositories/document_repository.dart';

/// The library index, kept in sync with the filesystem repository.
class DocumentsNotifier extends AsyncNotifier<List<PdfDocument>> {
  @override
  Future<List<PdfDocument>> build() async {
    final DocumentRepository repository = ref.watch(documentRepositoryProvider);
    await repository.ensureBundledSample();
    return repository.listDocuments();
  }

  Future<PdfDocument> importPdf({
    String? sourcePath,
    String? displayName,
    Uint8List? bytes,
  }) async {
    final DocumentRepository repository = ref.read(documentRepositoryProvider);
    final PdfDocument document = await repository.importPdf(
      sourcePath: sourcePath,
      displayName: displayName,
      bytes: bytes,
    );
    final List<PdfDocument> current = state.valueOrNull ?? const <PdfDocument>[];
    state = AsyncData<List<PdfDocument>>(<PdfDocument>[document, ...current]);
    return document;
  }

  Future<void> delete(PdfDocument document) async {
    final DocumentRepository repository = ref.read(documentRepositoryProvider);
    await repository.deleteDocument(document.id);
    await ref.read(readingStateRepositoryProvider).forget(document.id);
    state = AsyncData<List<PdfDocument>>(await repository.listDocuments());
  }

  Future<void> markOpened(String documentId) async {
    final DocumentRepository repository = ref.read(documentRepositoryProvider);
    final PdfDocument updated = await repository.markOpened(documentId);
    final List<PdfDocument> current = state.valueOrNull ?? const <PdfDocument>[];
    state = AsyncData<List<PdfDocument>>(<PdfDocument>[
      for (final PdfDocument document in current)
        if (document.id == updated.id) updated else document,
    ]);
  }

  Future<String?> ensureThumbnail(PdfDocument document) {
    return ref.read(documentRepositoryProvider).ensureThumbnail(document);
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<PdfDocument>>(
  DocumentsNotifier.new,
);

/// True while a file is being copied, measured and thumbnailed.
class ImportBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final importBusyProvider =
    NotifierProvider<ImportBusyNotifier, bool>(ImportBusyNotifier.new);

class PositionsNotifier extends AsyncNotifier<Map<String, ReadingPosition>> {
  @override
  Future<Map<String, ReadingPosition>> build() {
    return ref.watch(readingStateRepositoryProvider).loadPositions();
  }

  /// Re-reads from storage after the reader screen closes.
  Future<void> refresh() async {
    state = AsyncData<Map<String, ReadingPosition>>(
      await ref.read(readingStateRepositoryProvider).loadPositions(),
    );
  }
}

final positionsProvider =
    AsyncNotifierProvider<PositionsNotifier, Map<String, ReadingPosition>>(
  PositionsNotifier.new,
);

/// A document plus the exact page the reader stopped at.
class ContinueReading {
  const ContinueReading({required this.document, required this.position});

  final PdfDocument document;
  final ReadingPosition position;

  int get percent => position.percentComplete;
}

/// Most recently touched document that has a saved position.
final continueReadingProvider =
    Provider<ContinueReading?>((ref) {
  final List<PdfDocument> documents =
      ref.watch(documentsProvider).valueOrNull ?? const <PdfDocument>[];
  final Map<String, ReadingPosition> positions =
      ref.watch(positionsProvider).valueOrNull ??
          const <String, ReadingPosition>{};

  ContinueReading? best;
  for (final PdfDocument document in documents) {
    final ReadingPosition? position = positions[document.id];
    if (position == null) {
      continue;
    }
    if (best == null || position.updatedAt.isAfter(best.position.updatedAt)) {
      best = ContinueReading(document: document, position: position);
    }
  }
  return best;
});

/// Total bytes used by imported PDFs.
final librarySizeProvider = Provider<int>((ref) {
  final List<PdfDocument> documents =
      ref.watch(documentsProvider).valueOrNull ?? const <PdfDocument>[];
  int total = 0;
  for (final PdfDocument document in documents) {
    total += document.sizeBytes;
  }
  return total;
});
