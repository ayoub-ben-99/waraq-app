import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/data/backup/backup_format.dart';
import 'package:waraq/data/models/bookmark_dto.dart';
import 'package:waraq/data/models/json_utils.dart';
import 'package:waraq/data/models/note_tag_dto.dart';
import 'package:waraq/data/models/pdf_document_dto.dart';
import 'package:waraq/domain/entities/bookmark.dart';
import 'package:waraq/domain/entities/note_tag.dart';
import 'package:waraq/domain/entities/pdf_document.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 22, 10);

  group('tags on notes', () {
    test('tag ids survive storage and are dropped when empty', () {
      final Bookmark note = Bookmark(
        id: 'doc_3',
        documentId: 'doc',
        page: 3,
        createdAt: now,
        note: 'اقتباس',
        tagIds: const <String>['tag1', 'tag2'],
      );
      final Bookmark restored = BookmarkDto.fromMap(BookmarkDto.toMap(note));

      expect(restored.tagIds, <String>['tag1', 'tag2']);
      expect(restored, note);

      final Bookmark plain = note.copyWith(tagIds: const <String>[]);
      expect(BookmarkDto.toMap(plain).containsKey('tagIds'), isFalse);
      expect(BookmarkDto.fromMap(BookmarkDto.toMap(plain)).tagIds, isEmpty);
    });

    test('a corrupted tag payload reads as no tags', () {
      expect(readStringList('nope'), isEmpty);
      expect(readStringList(<Object?>[1, '', '  ', 'ok']), <String>['ok']);
    });

    test('a tag round-trips with its colour', () {
      const NoteTag tag = NoteTag(id: 't1', name: 'فكرة', colorIndex: 3);
      expect(NoteTagDto.fromMap(NoteTagDto.toMap(tag)), tag);
    });

    test('tag colours wrap safely', () {
      expect(tagColor(-1), isNotNull);
      expect(tagColor(99), isNotNull);
      expect(tagColor(0), kTagColors.first);
    });
  });

  group('shelf categories', () {
    test('a category survives storage', () {
      final PdfDocument document = PdfDocument(
        id: 'd1',
        title: 'Book',
        filePath: '/library/d1.pdf',
        pageCount: 40,
        sizeBytes: 100,
        addedAt: now,
        category: 'روايات',
      );
      final PdfDocument restored =
          PdfDocumentDto.fromMap(PdfDocumentDto.toMap(document));
      expect(restored.category, 'روايات');
      expect(restored, document);
    });

    test('a book without a shelf stores nothing', () {
      final PdfDocument document = PdfDocument(
        id: 'd2',
        title: 'Book',
        filePath: '/library/d2.pdf',
        pageCount: 10,
        sizeBytes: 10,
        addedAt: now,
      );
      expect(PdfDocumentDto.toMap(document).containsKey('category'), isFalse);
      expect(
        PdfDocumentDto.fromMap(PdfDocumentDto.toMap(document)).category,
        isNull,
      );
    });

    test('copyWith can clear the shelf', () {
      final PdfDocument document = PdfDocument(
        id: 'd3',
        title: 'Book',
        filePath: '/library/d3.pdf',
        pageCount: 5,
        sizeBytes: 5,
        addedAt: now,
        category: 'عمل',
      );
      expect(document.copyWith(clearCategory: true).category, isNull);
      expect(document.copyWith(category: 'دراسة').category, 'دراسة');
    });
  });

  group('backup', () {
    test('carries the tag vocabulary', () {
      final Uint8List bytes = encodeBackup(
        BackupContents(
          createdAt: now,
          appVersion: '4.4.0',
          settings: const <String, Object?>{},
          documents: const <Map<String, Object?>>[],
          positions: const <Map<String, Object?>>[],
          bookmarks: const <Map<String, Object?>>[],
          tags: <Map<String, Object?>>[
            NoteTagDto.toMap(const NoteTag(id: 't1', name: 'اقتباس')),
          ],
          pdfs: const <String, Uint8List>{},
        ),
      );

      final BackupContents decoded = decodeBackup(bytes);
      expect(decoded.tags.single['name'], 'اقتباس');
    });
  });
}
