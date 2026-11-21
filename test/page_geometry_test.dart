import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/domain/entities/page_geometry.dart';

void main() {
  // 100 × 200 at a content width of 400 renders 800 tall.
  const List<PageSize> sizes = <PageSize>[
    PageSize(width: 100, height: 200),
    PageSize(width: 100, height: 200),
    PageSize(width: 100, height: 100),
  ];
  const double spacing = 12;

  PageLayout buildLayout({double width = 400}) {
    return PageLayout(pageSizes: sizes, contentWidth: width, spacing: spacing);
  }

  group('PageSize', () {
    test('falls back to an A4 ratio when a page reports no size', () {
      const PageSize invalid = PageSize(width: 0, height: 0);
      expect(invalid.isValid, isFalse);
      expect(invalid.aspectRatio, closeTo(595 / 842, 0.0001));
    });
  });

  group('PageLayout', () {
    test('sizes each page from its own aspect ratio', () {
      final PageLayout layout = buildLayout();
      expect(layout.heightFor(0), closeTo(800, 0.001));
      expect(layout.heightFor(2), closeTo(400, 0.001));
      expect(layout.pageCount, 3);
    });

    test('places pages with a gap between them', () {
      final PageLayout layout = buildLayout();
      expect(layout.topFor(0), 0);
      expect(layout.topFor(1), closeTo(812, 0.001));
      expect(layout.topFor(2), closeTo(1624, 0.001));
      // Two 800-tall pages, one 400-tall page, two 12px gaps.
      expect(layout.extent, closeTo(2024, 0.001));
    });

    test('reports the page that owns an offset', () {
      final PageLayout layout = buildLayout();
      expect(layout.pageIndexForOffset(0), 0);
      expect(layout.pageIndexForOffset(400), 0);
      expect(layout.pageIndexForOffset(811), 0);
      expect(layout.pageIndexForOffset(812), 1);
      expect(layout.pageIndexForOffset(1623), 1);
      expect(layout.pageIndexForOffset(1700), 2);
      expect(layout.pageIndexForOffset(99999), 2);
      expect(layout.pageIndexForOffset(-20), 0);
    });

    test('computes progress across the whole document', () {
      final PageLayout layout = buildLayout();
      expect(layout.progressForOffset(0), 0);
      expect(layout.progressForOffset(layout.extent / 2), closeTo(0.5, 0.0001));
      expect(layout.progressForOffset(layout.extent * 2), 1);
    });

    test('reports how far through a page an offset is', () {
      final PageLayout layout = buildLayout();
      expect(layout.fractionWithinPage(0, 0), 0);
      expect(layout.fractionWithinPage(0, 400), closeTo(0.5, 0.0001));
      expect(layout.fractionWithinPage(0, 800), 1);
      expect(layout.fractionWithinPage(1, 812), 0);
      expect(layout.fractionWithinPage(1, 1212), closeTo(0.5, 0.0001));
    });

    test('handles an empty document without dividing by zero', () {
      final PageLayout layout = PageLayout(
        pageSizes: const <PageSize>[],
        contentWidth: 400,
      );
      expect(layout.pageCount, 0);
      expect(layout.extent, 0);
      expect(layout.heightFor(0), 0);
      expect(layout.pageIndexForOffset(10), 0);
      expect(layout.progressForOffset(10), 0);
    });

    test('scales every page with the zoom factor', () {
      final PageLayout layout = buildLayout(width: 800);
      expect(layout.heightFor(0), closeTo(1600, 0.001));
      expect(layout.topFor(1), closeTo(1612, 0.001));
    });

    test('fitted content width respects gutters, max width and zoom', () {
      expect(
        PageLayout.fittedContentWidth(viewportWidth: 400),
        closeTo(368, 0.001),
      );
      // Wide screens stop growing, keeping line lengths readable.
      expect(
        PageLayout.fittedContentWidth(viewportWidth: 1400),
        closeTo(720, 0.001),
      );
      expect(
        PageLayout.fittedContentWidth(viewportWidth: 400, zoom: 2),
        closeTo(736, 0.001),
      );
      // Never collapses to nothing on absurd viewports.
      expect(
        PageLayout.fittedContentWidth(viewportWidth: 10),
        greaterThanOrEqualTo(160),
      );
    });
  });
}
