import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/domain/arabic_text.dart';
import 'package:waraq/domain/entities/bookmark.dart';
import 'package:waraq/domain/entities/note_tag.dart';
import 'package:waraq/domain/entities/pdf_document.dart';
import 'package:waraq/domain/library_search.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 22, 12);

  PdfDocument book(String id, String title, {String? category}) {
    return PdfDocument(
      id: id,
      title: title,
      filePath: '/library/$id.pdf',
      pageCount: 10,
      sizeBytes: 10,
      addedAt: now,
      category: category,
    );
  }

  group('Arabic normalisation', () {
    test('drops diacritics and unifies alef forms', () {
      expect(normalizeArabic('أَحْمَد'), 'احمد');
      expect(normalizeArabic('إسلام'), normalizeArabic('اسلام'));
      expect(normalizeArabic('آية'), 'ايه');
    });

    test('unifies ya and ta-marbuta, and removes tatweel', () {
      expect(normalizeArabic('مدرسة'), 'مدرسه');
      expect(normalizeArabic('مصطفى'), 'مصطفي');
      expect(normalizeArabic('كــتاب'), 'كتاب');
    });

    test('folds Latin case and squeezes spaces', () {
      expect(normalizeArabic('  Deep   Work '), 'deep work');
    });

    test('an empty query never matches', () {
      expect(containsQuery('anything', '   '), isFalse);
      expect(containsQuery(null, 'x'), isFalse);
      expect(containsQuery('كتاب', 'كتاب'), isTrue);
    });
  });

  group('global search', () {
    final List<PdfDocument> books = <PdfDocument>[
      book('a', 'العادات الذرية', category: 'تطوير'),
      book('b', 'رواية الطريق'),
    ];
    final List<NoteTag> tags = <NoteTag>[
      const NoteTag(id: 't1', name: 'اقتباس'),
      const NoteTag(id: 't2', name: 'فكرة'),
    ];
    final List<Bookmark> notes = <Bookmark>[
      Bookmark(
        id: 'a_4',
        documentId: 'a',
        page: 4,
        createdAt: now,
        note: 'التحسين المستمر أهم من الأهداف الكبيرة',
        tagIds: const <String>['t1'],
        updatedAt: now,
      ),
      Bookmark(
        id: 'b_2',
        documentId: 'b',
        page: 2,
        createdAt: now,
        note: 'ملاحظة قديمة',
        tagIds: const <String>['t2'],
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    SearchResults run(String query) => searchLibrary(
          query: query,
          documents: books,
          notes: notes,
          tags: tags,
        );

    test('matches a book by its undiacritised title', () {
      expect(run('العادات').books.single.title, 'العادات الذرية');
      expect(run('العَادَات').books.length, 1);
    });

    test('matches a book by its shelf', () {
      expect(run('تطوير').books.single.id, 'a');
    });

    test('matches note text with a different alef form', () {
      expect(run('الأهداف').notes.single.id, 'a_4');
      expect(run('الاهداف').notes.single.id, 'a_4');
    });

    test('matches a note through its tag name', () {
      final SearchResults results = run('فكرة');
      expect(results.notes.single.id, 'b_2');
      expect(results.tags.single.name, 'فكرة');
    });

    test('orders notes newest first', () {
      final SearchResults results = run('ملاحظة');
      expect(results.notes.map((Bookmark note) => note.id), <String>['b_2']);
    });

    test('an empty query finds nothing', () {
      expect(run('  ').total, 0);
      expect(run('').isEmpty, isTrue);
    });

    test('respects the result limit', () {
      final SearchResults results = searchLibrary(
        query: 'ا',
        documents: books,
        notes: notes,
        tags: tags,
        limit: 1,
      );
      expect(results.books.length, lessThanOrEqualTo(1));
      expect(results.notes.length, lessThanOrEqualTo(1));
    });
  });
}
