import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/data/models/bookmark_dto.dart';
import 'package:waraq/domain/entities/bookmark.dart';

void main() {
  group('Bookmark notes', () {
    final DateTime created = DateTime(2026, 3, 1, 9, 15);

    test('a plain marker has no note', () {
      final Bookmark bookmark = Bookmark(
        id: 'doc_4',
        documentId: 'doc',
        page: 4,
        createdAt: created,
      );
      expect(bookmark.hasNote, isFalse);
      expect(BookmarkDto.toMap(bookmark).containsKey('note'), isFalse);
    });

    test('a note survives a storage round-trip', () {
      final Bookmark original = Bookmark(
        id: 'doc_4',
        documentId: 'doc',
        page: 4,
        createdAt: created,
        note: '  الفكرة الأساسية: التحقق قبل النشر  ',
        updatedAt: created.add(const Duration(days: 2)),
      );
      final Bookmark restored = BookmarkDto.fromMap(BookmarkDto.toMap(original));

      expect(restored.id, original.id);
      expect(restored.page, original.page);
      expect(restored.note, 'الفكرة الأساسية: التحقق قبل النشر');
      expect(restored.hasNote, isTrue);
      expect(restored.touchedAt, original.updatedAt);
    });

    test('blank notes are dropped when reading', () {
      final Bookmark restored = BookmarkDto.fromMap(<String, Object?>{
        'id': 'doc_2',
        'documentId': 'doc',
        'page': 2,
        'createdAt': created.toIso8601String(),
        'note': '   ',
      });
      expect(restored.note, isNull);
      expect(restored.hasNote, isFalse);
    });

    test('copyWith can clear the note while keeping the marker', () {
      final Bookmark bookmark = Bookmark(
        id: 'doc_1',
        documentId: 'doc',
        page: 1,
        createdAt: created,
        note: 'kept',
      );
      final Bookmark cleared = bookmark.copyWith(clearNote: true, updatedAt: created);
      expect(cleared.note, isNull);
      expect(cleared.hasNote, isFalse);
      expect(cleared.id, bookmark.id);
      expect(cleared.page, bookmark.page);
    });

    test('older payloads without a note still load', () {
      final Bookmark restored = BookmarkDto.fromMap(<String, Object?>{
        'id': 'legacy_7',
        'documentId': 'legacy',
        'page': 7,
        'createdAt': created.toIso8601String(),
      });
      expect(restored.hasNote, isFalse);
      expect(restored.updatedAt, isNull);
    });
  });
}
