import 'dart:math' as math;

/// Intrinsic size of a PDF page, in points.
class PageSize {
  const PageSize({required this.width, required this.height});

  /// A4 portrait, used when a page reports no usable size.
  static const PageSize fallback = PageSize(width: 595, height: 842);

  final double width;
  final double height;

  bool get isValid => width > 0 && height > 0;

  double get aspectRatio => isValid ? width / height : 595 / 842;
}

/// Pure geometry for a continuously scrolling stack of pages.
///
/// Every page is laid out at [contentWidth] wide and keeps its own aspect
/// ratio, so page boundaries land at predictable offsets. That makes scrubbing,
/// jump-to-page and "which page am I on" exact instead of approximate.
class PageLayout {
  PageLayout({
    required List<PageSize> pageSizes,
    required this.contentWidth,
    this.spacing = 12,
  })  : pageSizes = List<PageSize>.unmodifiable(pageSizes),
        assert(contentWidth >= 0);

  final List<PageSize> pageSizes;
  final double contentWidth;
  final double spacing;

  late final List<double> _tops = _buildTops();

  int get pageCount => pageSizes.length;

  double heightFor(int index) {
    if (index < 0 || index >= pageSizes.length) {
      return 0;
    }
    return contentWidth / pageSizes[index].aspectRatio;
  }

  double topFor(int index) {
    if (index <= 0 || _tops.isEmpty) {
      return 0;
    }
    if (index >= _tops.length) {
      return extent;
    }
    return _tops[index];
  }

  /// Total height of every page plus the gaps between them.
  double get extent => _tops.isEmpty ? 0 : _tops.last + heightFor(pageCount - 1);

  /// Index of the page that owns [offset] (0-based, clamped).
  int pageIndexForOffset(double offset) {
    if (_tops.isEmpty) {
      return 0;
    }
    if (offset <= 0) {
      return 0;
    }
    if (offset >= extent) {
      return pageCount - 1;
    }
    int low = 0;
    int high = _tops.length - 1;
    while (low < high) {
      final int mid = (low + high + 1) >> 1;
      if (_tops[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  double offsetForPage(int index) => topFor(index);

  double offsetForProgress(double progress) {
    return (progress.clamp(0.0, 1.0) * extent).toDouble();
  }

  double progressForOffset(double offset) {
    if (extent <= 0) {
      return 0;
    }
    return (offset / extent).clamp(0.0, 1.0).toDouble();
  }

  /// Fraction of the page at [index] that has scrolled past [offset].
  double fractionWithinPage(int index, double offset) {
    final double height = heightFor(index);
    if (height <= 0) {
      return 0;
    }
    return ((offset - topFor(index)) / height).clamp(0.0, 1.0).toDouble();
  }

  List<double> _buildTops() {
    final List<double> tops = <double>[];
    double cursor = 0;
    for (int i = 0; i < pageSizes.length; i++) {
      tops.add(cursor);
      cursor += heightFor(i) + spacing;
    }
    return tops;
  }

  /// Page width that keeps a page readable on wide screens.
  static double fittedContentWidth({
    required double viewportWidth,
    double gutter = 16,
    double maxWidth = 720,
    double zoom = 1,
  }) {
    final double available = math.max(viewportWidth - gutter * 2, 160);
    final double base = math.min(available, maxWidth);
    return base * zoom.clamp(0.8, 3.0).toDouble();
  }
}
