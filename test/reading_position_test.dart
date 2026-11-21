import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/domain/entities/bookmark.dart';
import 'package:waraq/domain/entities/reading_position.dart';

void main() {
  group('ReadingPosition', () {
    final DateTime updatedAt = DateTime(2026, 5, 4, 10, 30);

    test('reports completion as a rounded percentage', () {
      final ReadingPosition position = ReadingPosition(
        documentId: 'doc',
        page: 12,
        progress: 0.128,
        updatedAt: updatedAt,
      );
      expect(position.percentComplete, 13);
    });

    test('clamps a corrupted progress value', () {
      final ReadingPosition position = ReadingPosition(
        documentId: 'doc',
        page: 1,
        progress: 4.2,
        updatedAt: updatedAt,
      );
      expect(position.percentComplete, 100);
    });

    test('copies while keeping the document id', () {
      final ReadingPosition position = ReadingPosition(
        documentId: 'doc',
        page: 12,
        progress: 0.1,
        offsetFraction: 0.5,
        updatedAt: updatedAt,
      );
      final ReadingPosition next = position.copyWith(page: 13, progress: 0.2);
      expect(next.documentId, 'doc');
      expect(next.page, 13);
      expect(next.progress, 0.2);
      expect(next.offsetFraction, 0.5);
      expect(next.updatedAt, updatedAt);
    });
  });

  group('Bookmark', () {
    test('compares by value', () {
      final DateTime created = DateTime(2026, 1, 1);
      final Bookmark a = Bookmark(
        id: 'x_3',
        documentId: 'x',
        page: 3,
        createdAt: created,
      );
      final Bookmark b = Bookmark(
        id: 'x_3',
        documentId: 'x',
        page: 3,
        createdAt: created,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
