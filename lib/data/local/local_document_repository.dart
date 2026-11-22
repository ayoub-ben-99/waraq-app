import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/pdf_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/json_utils.dart';
import '../models/pdf_document_dto.dart';
import '../pdf/pdf_renderer.dart';
import 'prefs_keys.dart';

/// Filesystem-backed library. Imported PDFs are copied into application
/// support storage, so the library survives the source file being moved or
/// deleted, and nothing needs broad storage permissions.
class LocalDocumentRepository implements DocumentRepository {
  LocalDocumentRepository(this._prefs);

  static const String sampleAssetPath = 'assets/sample/waraq_sample.pdf';
  static const String sampleTitle = 'On Quiet Reading';

  final SharedPreferences _prefs;
  final math.Random _random = math.Random();

  @override
  Future<List<PdfDocument>> listDocuments() async {
    final List<PdfDocument> documents = _readIndex();
    documents.sort((PdfDocument a, PdfDocument b) {
      final DateTime aTime = a.lastOpenedAt ?? a.addedAt;
      final DateTime bTime = b.lastOpenedAt ?? b.addedAt;
      return bTime.compareTo(aTime);
    });
    return documents;
  }

  @override
  Future<PdfDocument> importPdf({
    String? sourcePath,
    String? displayName,
    Uint8List? bytes,
  }) async {
    if (sourcePath == null && bytes == null) {
      throw const DocumentException('No file was provided');
    }

    final Directory library = await _libraryDirectory();
    final String id = _newId();
    final File target = File(p.join(library.path, '$id.pdf'));
    try {
      if (sourcePath != null) {
        await File(sourcePath).copy(target.path);
      } else {
        await target.writeAsBytes(bytes!, flush: true);
      }
    } on FileSystemException catch (error) {
      throw DocumentException('Could not copy the file: ${error.message}');
    }

    PdfRenderer? renderer;
    try {
      renderer = await PdfRenderer.open(target.path);
      final String title = _titleFor(sourcePath, displayName);
      final String? thumbnailPath = await _writeThumbnail(renderer, id);
      final PdfDocument document = PdfDocument(
        id: id,
        title: title,
        filePath: target.path,
        pageCount: renderer.pageCount,
        sizeBytes: await target.length(),
        addedAt: DateTime.now(),
        thumbnailPath: thumbnailPath,
      );
      final List<PdfDocument> documents = _readIndex()..add(document);
      await _writeIndex(documents);
      return document;
    } catch (error) {
      if (await target.exists()) {
        await target.delete();
      }
      if (error is DocumentException) {
        rethrow;
      }
      throw DocumentException('Could not read the PDF: $error');
    } finally {
      await renderer?.dispose();
    }
  }

  @override
  Future<void> ensureBundledSample() async {
    if (_prefs.getBool(PrefsKeys.sampleSeeded) ?? false) {
      return;
    }
    final bool libraryIsEmpty = _readIndex().isEmpty;
    try {
      if (libraryIsEmpty) {
        final ByteData data = await rootBundle.load(sampleAssetPath);
        await importPdf(
          bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          displayName: sampleTitle,
        );
      }
    } catch (_) {
      // A missing asset or an unsupported platform must never block the app.
    } finally {
      await _prefs.setBool(PrefsKeys.sampleSeeded, true);
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    final List<PdfDocument> documents = _readIndex();
    final String? filePath = _pathOf(documents, documentId);
    documents.removeWhere((PdfDocument document) => document.id == documentId);
    await _writeIndex(documents);

    if (filePath != null) {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    final File thumbnail = File(await _thumbnailPath(documentId));
    if (await thumbnail.exists()) {
      await thumbnail.delete();
    }
  }

  @override
  Future<PdfDocument> updateMetadata(
    String documentId, {
    String? title,
    String? category,
    bool clearCategory = false,
  }) async {
    final List<PdfDocument> documents = _readIndex();
    final int index = documents.indexWhere(
      (PdfDocument document) => document.id == documentId,
    );
    if (index < 0) {
      throw DocumentException('Unknown document: $documentId');
    }
    final String trimmedTitle = (title ?? '').trim();
    final String trimmedCategory = (category ?? '').trim();
    final PdfDocument updated = documents[index].copyWith(
      title: trimmedTitle.isEmpty ? null : trimmedTitle,
      category: trimmedCategory.isEmpty ? null : trimmedCategory,
      clearCategory: clearCategory || trimmedCategory.isEmpty,
    );
    documents[index] = updated;
    await _writeIndex(documents);
    return updated;
  }

  @override
  Future<PdfDocument> markOpened(String documentId) async {
    final List<PdfDocument> documents = _readIndex();
    final int index = documents.indexWhere((PdfDocument d) => d.id == documentId);
    if (index < 0) {
      throw DocumentException('Unknown document: $documentId');
    }
    final PdfDocument updated =
        documents[index].copyWith(lastOpenedAt: DateTime.now());
    documents[index] = updated;
    await _writeIndex(documents);
    return updated;
  }

  @override
  Future<String?> ensureThumbnail(PdfDocument document) async {
    if (document.thumbnailPath != null) {
      final File existing = File(document.thumbnailPath!);
      if (await existing.exists()) {
        return existing.path;
      }
    }
    if (!await File(document.filePath).exists()) {
      return null;
    }
    PdfRenderer? renderer;
    try {
      renderer = await PdfRenderer.open(document.filePath);
      return await _writeThumbnail(renderer, document.id);
    } catch (_) {
      return null;
    } finally {
      await renderer?.dispose();
    }
  }

  String? _pathOf(List<PdfDocument> documents, String documentId) {
    for (final PdfDocument document in documents) {
      if (document.id == documentId) {
        return document.filePath;
      }
    }
    return null;
  }

  Future<String?> _writeThumbnail(PdfRenderer renderer, String documentId) async {
    try {
      final Directory directory = await _thumbnailDirectory();
      final Uint8List bytes = await renderer.renderPage(0, targetWidth: 360);
      final File file = File(p.join(directory.path, '$documentId.png'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _titleFor(String? sourcePath, String? displayName) {
    final String raw = (displayName ??
            (sourcePath == null ? 'Document' : p.basenameWithoutExtension(sourcePath)))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return raw.isEmpty ? 'Untitled' : raw;
  }

  String _newId() {
    final String time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final String noise = _random.nextInt(1 << 20).toRadixString(36);
    return '$time$noise';
  }

  Future<Directory> _libraryDirectory() => _ensureDirectory('library');

  Future<Directory> _thumbnailDirectory() => _ensureDirectory('thumbnails');

  Future<Directory> _ensureDirectory(String name) async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory directory = Directory(p.join(base.path, name));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<String> _thumbnailPath(String documentId) async {
    final Directory directory = await _thumbnailDirectory();
    return p.join(directory.path, '$documentId.png');
  }

  List<PdfDocument> _readIndex() {
    final String? raw = _prefs.getString(PrefsKeys.documents);
    if (raw == null || raw.isEmpty) {
      return <PdfDocument>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <PdfDocument>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(readMap)
          .map(PdfDocumentDto.fromMap)
          .where((PdfDocument document) => document.id.isNotEmpty)
          .toList();
    } catch (_) {
      return <PdfDocument>[];
    }
  }

  Future<void> _writeIndex(List<PdfDocument> documents) async {
    final List<Map<String, Object?>> payload =
        documents.map(PdfDocumentDto.toMap).toList(growable: false);
    await _prefs.setString(PrefsKeys.documents, jsonEncode(payload));
  }
}
