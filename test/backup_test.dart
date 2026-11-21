import 'dart:typed_data';

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/data/backup/backup_format.dart';
import 'package:waraq/data/backup/backup_service.dart';
import 'package:waraq/data/models/app_settings_dto.dart';
import 'package:waraq/data/models/bookmark_dto.dart';
import 'package:waraq/data/models/pdf_document_dto.dart';
import 'package:waraq/data/models/reading_position_dto.dart';
import 'package:waraq/domain/entities/app_settings.dart';
import 'package:waraq/domain/entities/bookmark.dart';
import 'package:waraq/domain/entities/pdf_document.dart';
import 'package:waraq/domain/entities/reading_position.dart';
import 'package:waraq/domain/repositories/document_repository.dart';
import 'package:waraq/domain/repositories/reading_state_repository.dart';
import 'package:waraq/domain/repositories/settings_repository.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 21, 12);

  group('backup format', () {
    test('round-trips data, notes and pdf bytes', () {
      final BackupContents contents = BackupContents(
        createdAt: now,
        appVersion: '4.2.0',
        settings: <String, Object?>{'language': 'ar'},
        documents: <Map<String, Object?>>[
          <String, Object?>{'id': 'a', 'title': 'كتاب'},
        ],
        positions: <Map<String, Object?>>[
          <String, Object?>{'documentId': 'a', 'page': 3},
        ],
        bookmarks: <Map<String, Object?>>[
          <String, Object?>{'id': 'a_3', 'documentId': 'a', 'page': 3, 'note': 'فكرة'},
        ],
        pdfs: <String, Uint8List>{
          'a': Uint8List.fromList(<int>[37, 80, 68, 70]),
        },
      );

      final BackupContents decoded = decodeBackup(encodeBackup(contents));

      expect(decoded.appVersion, '4.2.0');
      expect(decoded.documents.single['title'], 'كتاب');
      expect(decoded.noteCount, 1);
      expect(decoded.includesPdfs, isTrue);
      expect(decoded.pdfs['a'], <int>[37, 80, 68, 70]);
    });

    test('rejects a file that is not a zip', () {
      expect(
        () => decodeBackup(Uint8List.fromList(<int>[1, 2, 3, 4])),
        throwsA(
          isA<BackupException>().having(
            (BackupException error) => error.code,
            'code',
            'notABackup',
          ),
        ),
      );
    });

    test('refuses a backup written by a newer schema', () {
      final Archive archive = Archive();
      void add(String name, String json) {
        final List<int> bytes = utf8.encode(json);
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }

      add('manifest.json', '{"schema":${kBackupSchema + 1}}');
      add('data.json', '{"schema":${kBackupSchema + 1}}');
      final Uint8List bytes =
          Uint8List.fromList(ZipEncoder().encode(archive)!);

      expect(
        () => decodeBackup(bytes),
        throwsA(
          isA<BackupException>().having(
            (BackupException error) => error.code,
            'code',
            'newerSchema',
          ),
        ),
      );
    });

    test('names the file with its date', () {
      expect(backupFileName(now), 'waraq-2026-11-21.waraq.zip');
    });
  });

  group('restore merge', () {
    late _FakeDocuments documents;
    late _FakeReading reading;
    late _FakeSettings settings;
    late BackupService service;

    setUp(() {
      documents = _FakeDocuments();
      reading = _FakeReading();
      settings = _FakeSettings();
      service = BackupService(
        documents: documents,
        reading: reading,
        settings: settings,
      );
    });

    test('imports a new book and remaps its notes and position', () async {
      final PdfDocument existing = documents.add(
        id: 'local',
        title: 'Local book',
        pages: 10,
      );
      final Uint8List bytes = encodeBackup(
        BackupContents(
          createdAt: now,
          appVersion: '4.2.0',
          settings: const <String, Object?>{},
          documents: <Map<String, Object?>>[
            PdfDocumentDto.toMap(
              PdfDocument(
                id: 'foreign',
                title: 'Book from the backup',
                filePath: '/tmp/foreign.pdf',
                pageCount: 12,
                sizeBytes: 4,
                addedAt: now,
              ),
            ),
          ],
          positions: <Map<String, Object?>>[
            ReadingPositionDto.toMap(
              ReadingPosition(
                documentId: 'foreign',
                page: 5,
                progress: 0.4,
                updatedAt: now,
              ),
            ),
          ],
          bookmarks: <Map<String, Object?>>[
            BookmarkDto.toMap(
              Bookmark(
                id: 'foreign_5',
                documentId: 'foreign',
                page: 5,
                createdAt: now,
                note: 'اقتباس',
              ),
            ),
          ],
          pdfs: <String, Uint8List>{
            'foreign': Uint8List.fromList(<int>[1, 2, 3]),
          },
        ),
      );

      final BackupRestore result = await service.restore(bytes);

      expect(result.documentsAdded, 1);
      expect(result.documentsSkipped, 0);
      expect(result.notes, 1);
      final String newId = documents.documents.last.id;
      expect(newId, isNot('foreign'));
      expect(reading.positions[newId]?.page, 5);
      final Bookmark note = reading.bookmarks.single;
      expect(note.documentId, newId);
      expect(note.id, '${newId}_5');
      expect(note.note, 'اقتباس');
      expect(existing.id, 'local');
    });

    test('skips a document whose PDF is missing from the file', () async {
      final Uint8List bytes = encodeBackup(
        BackupContents(
          createdAt: now,
          appVersion: '4.2.0',
          settings: const <String, Object?>{},
          documents: <Map<String, Object?>>[
            PdfDocumentDto.toMap(
              PdfDocument(
                id: 'gone',
                title: 'Data only',
                filePath: '/nowhere.pdf',
                pageCount: 3,
                sizeBytes: 0,
                addedAt: now,
              ),
            ),
          ],
          positions: <Map<String, Object?>>[], 
          bookmarks: <Map<String, Object?>>[],
          pdfs: const <String, Uint8List>{},
        ),
      );

      final BackupRestore result = await service.restore(bytes);

      expect(result.documentsAdded, 0);
      expect(result.documentsSkipped, 1);
    });

    test('keeps the newer of two reading positions', () async {
      final PdfDocument local = documents.add(id: 'doc', title: 'Doc', pages: 9);
      reading.positions[local.id] = ReadingPosition(
        documentId: local.id,
        page: 8,
        progress: 0.9,
        updatedAt: now.add(const Duration(days: 1)),
      );
      final Uint8List bytes = encodeBackup(
        BackupContents(
          createdAt: now,
          appVersion: '4.2.0',
          settings: const <String, Object?>{},
          documents: <Map<String, Object?>>[
            PdfDocumentDto.toMap(local),
          ],
          positions: <Map<String, Object?>>[
            ReadingPositionDto.toMap(
              ReadingPosition(
                documentId: 'doc',
                page: 2,
                progress: 0.1,
                updatedAt: now,
              ),
            ),
          ],
          bookmarks: const <Map<String, Object?>>[],
          pdfs: const <String, Uint8List>{},
        ),
      );

      await service.restore(bytes);

      expect(reading.positions['doc']?.page, 8);
    });

    test('applies the settings from the file', () async {
      final Uint8List bytes = encodeBackup(
        BackupContents(
          createdAt: now,
          appVersion: '4.2.0',
          settings: AppSettingsDto.toMap(const AppSettings()),
          documents: const <Map<String, Object?>>[],
          positions: const <Map<String, Object?>>[],
          bookmarks: const <Map<String, Object?>>[],
          pdfs: const <String, Uint8List>{},
        ),
      );

      final BackupRestore result = await service.restore(bytes);

      expect(result.settingsApplied, isTrue);
      expect(settings.saved, isNotNull);
    });
  });
}

class _FakeDocuments implements DocumentRepository {
  final List<PdfDocument> documents = <PdfDocument>[];
  int _ids = 0;

  PdfDocument add({required String id, required String title, required int pages}) {
    final PdfDocument document = PdfDocument(
      id: id,
      title: title,
      filePath: '/library/$id.pdf',
      pageCount: pages,
      sizeBytes: 10,
      addedAt: DateTime(2026, 1, 1),
    );
    documents.add(document);
    return document;
  }

  @override
  Future<List<PdfDocument>> listDocuments() async =>
      List<PdfDocument>.of(documents);

  @override
  Future<PdfDocument> importPdf({
    String? sourcePath,
    String? displayName,
    Uint8List? bytes,
  }) async {
    _ids++;
    return add(id: 'imported$_ids', title: displayName ?? 'Doc', pages: 3);
  }

  @override
  Future<void> ensureBundledSample() async {}

  @override
  Future<void> deleteDocument(String documentId) async {
    documents.removeWhere((PdfDocument document) => document.id == documentId);
  }

  @override
  Future<PdfDocument> markOpened(String documentId) async =>
      documents.firstWhere((PdfDocument document) => document.id == documentId);

  @override
  Future<String?> ensureThumbnail(PdfDocument document) async => null;
}

class _FakeReading implements ReadingStateRepository {
  final Map<String, ReadingPosition> positions = <String, ReadingPosition>{};
  final List<Bookmark> bookmarks = <Bookmark>[];

  @override
  Future<Map<String, ReadingPosition>> loadPositions() async =>
      Map<String, ReadingPosition>.of(positions);

  @override
  Future<void> savePosition(ReadingPosition position) async {
    positions[position.documentId] = position;
  }

  @override
  Future<List<Bookmark>> loadBookmarks() async =>
      List<Bookmark>.of(bookmarks);

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    final int index =
        bookmarks.indexWhere((Bookmark item) => item.id == bookmark.id);
    if (index >= 0) {
      bookmarks[index] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    bookmarks.removeWhere((Bookmark item) => item.id == bookmarkId);
  }

  @override
  Future<void> forget(String documentId) async {
    positions.remove(documentId);
    bookmarks.removeWhere((Bookmark item) => item.documentId == documentId);
  }

  @override
  Future<void> clearAll() async {
    positions.clear();
    bookmarks.clear();
  }
}

class _FakeSettings implements SettingsRepository {
  AppSettings? saved;

  @override
  Future<AppSettings> load() async => saved ?? const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
  }
}
