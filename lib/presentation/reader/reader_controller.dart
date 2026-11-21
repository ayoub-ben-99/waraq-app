import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';
import '../../data/pdf/pdf_page_cache.dart';
import '../../data/pdf/pdf_renderer.dart';
import '../../domain/entities/page_geometry.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reader_settings.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/repositories/reading_state_repository.dart';

/// Screen-scoped state for one open document.
///
/// Lives for as long as the reader route does, because it owns the scroll
/// controllers, the render cache and the auto-scroll ticker. App-wide state
/// (settings, library, bookmarks) is handled by Riverpod providers; this class
/// is plain Dart so the scroll maths stays testable.
class ReaderController extends ChangeNotifier {
  ReaderController({
    required this.document,
    required this.renderer,
    required this.cache,
    required this.readingState,
    required ReaderSettings initialSettings,
    required TickerProvider vsync,
    ReadingPosition? initialPosition,
    this.startPage,
  })  : _pageCount = renderer.pageCount,
        _currentPage = initialPosition?.page ?? 1,
        _progress = initialPosition?.progress ?? 0,
        _speed = initialSettings.autoScrollSpeed,
        _scrollMode = initialSettings.scrollMode,
        _filter = initialSettings.pageFilter,
        _dim = initialSettings.pageBrightness,
        _initialPosition = initialPosition {
    _ticker = vsync.createTicker(_onTick);
    scrollController.addListener(_handleVerticalScroll);
    pageController.addListener(_handlePagedScroll);
  }

  static const double minZoom = 1.0;
  static const double maxZoom = 3.0;

  /// Air above the first page; the canvas pads its list by the same amount so
  /// scroll offsets and page geometry stay in sync.
  static const double topInset = Gap.l;

  final PdfDocument document;
  final PdfRenderer renderer;
  final PdfPageCache cache;
  final ReadingStateRepository readingState;

  final ScrollController scrollController = ScrollController();
  final PageController pageController = PageController();

  /// When set, the reader opens on this page instead of the saved position
  /// (used when jumping from a note or bookmark).
  final int? startPage;

  ReadingPosition? _initialPosition;
  late final Ticker _ticker;

  int _pageCount;
  int _currentPage;
  double _progress;
  double _speed;
  ScrollMode _scrollMode;
  PageFilter _filter;
  double _dim;

  double _zoom = 1;
  bool _pinching = false;
  double _pinchStartZoom = 1;

  bool _chromeVisible = true;
  bool _indicatorVisible = false;
  bool _autoScrolling = false;

  bool _scrubbing = false;
  int? _scrubPage;
  double _scrubProgress = 0;

  double _viewportWidth = 0;
  double _viewportHeight = 0;
  double _renderWidth = 0;
  PageLayout? _layout;

  bool _disposed = false;
  bool _hasRestored = false;
  bool _hasBuiltOnce = false;

  Timer? _indicatorTimer;
  Timer? _saveTimer;
  Timer? _pageTurnTimer;
  Duration? _lastTick;
  DateTime _lastIndicatorTouch = DateTime.fromMillisecondsSinceEpoch(0);

  int get pageCount => _pageCount;
  int get currentPage => _currentPage;
  double get progress => _progress;
  double get zoom => _zoom;
  bool get isPinching => _pinching;
  bool get chromeVisible => _chromeVisible;
  bool get indicatorVisible => _indicatorVisible;
  bool get isAutoScrolling => _autoScrolling;
  double get speed => _speed;
  ScrollMode get scrollMode => _scrollMode;
  PageFilter get filter => _filter;
  double get dim => _dim;
  bool get isScrubbing => _scrubbing;
  int? get scrubPage => _scrubPage;
  double get scrubProgress => _scrubProgress;
  PageLayout? get layout => _layout;
  double get viewportHeight => _viewportHeight;

  /// Current reader preferences, for persisting back to settings.
  ReaderSettings get settingsSnapshot => ReaderSettings(
        scrollMode: _scrollMode,
        pageFilter: _filter,
        autoScrollSpeed: _speed,
        pageBrightness: _dim,
      );

  double get pageContentWidth => PageLayout.fittedContentWidth(
        viewportWidth: _viewportWidth,
        gutter: Gap.l,
        maxWidth: Sizes.readerPageMaxWidth,
        zoom: _zoom,
      );

  // ------------------------------------------------------------- viewport ---

  void updateViewport(Size size) {
    if ((size.width - _viewportWidth).abs() < 0.5 &&
        (size.height - _viewportHeight).abs() < 0.5) {
      return;
    }
    _viewportWidth = size.width;
    _viewportHeight = size.height;
    _layout = _buildLayout();
    if (_hasBuiltOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
    }
    _hasBuiltOnce = true;
  }

  /// Called by the canvas so neighbour pages are rendered at the resolution the
  /// screen will actually display.
  void noteRenderWidth(double width) {
    if ((width - _renderWidth).abs() < 1 || width <= 0) {
      return;
    }
    _renderWidth = width;
    cache.prefetchAround(_currentPage - 1, width);
  }

  PageLayout? _buildLayout() {
    if (_viewportWidth <= 0 || _pageCount <= 0) {
      return null;
    }
    return PageLayout(
      pageSizes: renderer.pageSizes,
      contentWidth: pageContentWidth,
      spacing: Sizes.readerPageSpacing,
    );
  }

  // -------------------------------------------------------------- restore ---

  void restoreInitialPosition() {
    if (_hasRestored) {
      return;
    }
    _hasRestored = true;
    final int? jump = startPage;
    if (jump != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) {
          return;
        }
        jumpToPage(jump);
        _scheduleSave();
      });
      return;
    }
    final ReadingPosition? position = _initialPosition;
    _initialPosition = null;
    if (position == null) {
      _scheduleSave();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) {
        return;
      }
      jumpToPage(position.page, fraction: position.offsetFraction);
    });
  }

  // ------------------------------------------------------------ scrolling ---

  void _handleVerticalScroll() {
    if (_disposed || _scrubbing || _scrollMode != ScrollMode.vertical) {
      return;
    }
    if (!scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = scrollController.position;
    final double offset = position.pixels;

    int nextPage = _currentPage;
    double nextProgress = _progress;
    final PageLayout? layout = _layout;
    if (layout != null && layout.extent > 0) {
      final double local = (offset - topInset).clamp(0.0, layout.extent).toDouble();
      final int index = layout.pageIndexForOffset(local);
      nextPage = (index + 1).clamp(1, _pageCount).toInt();
      nextProgress = _pageProgress(index, local, layout);
    } else {
      final double maxExtent = position.maxScrollExtent;
      nextProgress = maxExtent <= 0
          ? 0
          : (offset / maxExtent).clamp(0.0, 1.0).toDouble();
    }

    final bool pageChanged = nextPage != _currentPage;
    final bool progressChanged = (nextProgress - _progress).abs() > 0.0015;
    _flashIndicator();
    if (!pageChanged && !progressChanged) {
      return;
    }
    _currentPage = nextPage;
    _progress = nextProgress;
    _notify();
    if (pageChanged) {
      _scheduleSave();
      if (_renderWidth > 0) {
        cache.prefetchAround(_currentPage - 1, _renderWidth);
      }
    }
  }

  void _handlePagedScroll() {
    if (_disposed || _scrollMode != ScrollMode.horizontal) {
      return;
    }
    if (!pageController.hasClients) {
      return;
    }
    final double? page = pageController.page;
    if (page == null) {
      return;
    }
    final int nextPage = (page.round() + 1).clamp(1, _pageCount).toInt();
    final double nextProgress = _pageCount <= 1
        ? 0
        : (page / (_pageCount - 1)).clamp(0.0, 1.0).toDouble();
    final bool pageChanged = nextPage != _currentPage;
    if (!pageChanged && (nextProgress - _progress).abs() < 0.0015) {
      return;
    }
    _currentPage = nextPage;
    _progress = nextProgress;
    _notify();
    if (pageChanged) {
      _scheduleSave();
      if (_renderWidth > 0) {
        cache.prefetchAround(_currentPage - 1, _renderWidth);
      }
    }
  }

  /// Progress across the document, counted in pages so it matches the page
  /// indicator exactly (page 1 starts at 0, the end of the last page is 1).
  double _pageProgress(int pageIndex, double offset, PageLayout layout) {
    if (_pageCount <= 0) {
      return 0;
    }
    final double fraction = layout.fractionWithinPage(pageIndex, offset);
    return ((pageIndex + fraction) / _pageCount).clamp(0.0, 1.0).toDouble();
  }

  void jumpToPage(int page, {double fraction = 0, bool animate = false}) {
    final int target = page.clamp(1, math.max(1, _pageCount)).toInt();
    _currentPage = target;
    if (_scrollMode == ScrollMode.horizontal) {
      if (pageController.hasClients) {
        if (animate) {
          unawaited(pageController.animateToPage(
            target - 1,
            duration: Motion.base,
            curve: Motion.emphasized,
          ));
        } else {
          pageController.jumpToPage(target - 1);
        }
      }
      _progress = _pageCount <= 1 ? 0 : (target - 1) / (_pageCount - 1);
    } else {
      final PageLayout? layout = _layout;
      if (layout != null) {
        if (scrollController.hasClients) {
          final double height = layout.heightFor(target - 1);
          final double raw = topInset +
              layout.topFor(target - 1) +
              fraction.clamp(0.0, 1.0).toDouble() * height;
          final double maxExtent = scrollController.position.maxScrollExtent;
          final double offset = raw.clamp(0.0, maxExtent).toDouble();
          if (animate) {
            unawaited(scrollController.animateTo(
              offset,
              duration: Motion.base,
              curve: Motion.emphasized,
            ));
          } else {
            scrollController.jumpTo(offset);
          }
        }
        final double top = topInset + layout.topFor(target - 1);
        final double local = top.clamp(0.0, layout.extent).toDouble();
        _progress = _pageProgress(
          layout.pageIndexForOffset(local),
          local,
          layout,
        );
      }
    }
    _notify();
    _scheduleSave();
  }

  void handleScrollNotification(ScrollNotification notification) {
    if (_disposed) {
      return;
    }
    _flashIndicator();
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        _chromeVisible &&
        _scrollMode == ScrollMode.vertical) {
      setChromeVisible(false);
    }
    if (notification is ScrollEndNotification) {
      _scheduleSave();
    }
  }

  // ----------------------------------------------------------------- zoom ---

  void beginPinch() {
    if (_pinching) {
      return;
    }
    _pinching = true;
    _pinchStartZoom = _zoom;
    if (_autoScrolling) {
      pauseAutoScroll();
    }
    _notify();
  }

  void updatePinch(double factor) {
    if (!_pinching) {
      beginPinch();
    }
    final double next =
        (_pinchStartZoom * factor).clamp(minZoom, maxZoom).toDouble();
    if ((next - _zoom).abs() < 0.008) {
      return;
    }
    _applyZoom(next, restorePage: false);
  }

  void endPinch() {
    if (!_pinching) {
      return;
    }
    _pinching = false;
    final double snapped =
        _zoom < 1.04 ? 1.0 : _zoom.clamp(minZoom, maxZoom).toDouble();
    _applyZoom(snapped, restorePage: true);
  }

  void toggleDoubleTapZoom() {
    _applyZoom(_zoom > 1.05 ? 1.0 : 1.85, restorePage: true);
  }

  void _applyZoom(double value, {required bool restorePage}) {
    final int page = _currentPage;
    _zoom = value.clamp(minZoom, maxZoom).toDouble();
    _layout = _buildLayout();
    _notify();
    if (restorePage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          jumpToPage(page);
        }
      });
    }
  }

  // ------------------------------------------------------------- chrome ----

  void setChromeVisible(bool visible) {
    if (_chromeVisible == visible) {
      return;
    }
    _chromeVisible = visible;
    _notify();
  }

  void toggleChrome() => setChromeVisible(!_chromeVisible);

  /// Any touch on the page pauses auto-scroll immediately.
  void handlePointerDown() {
    if (_autoScrolling) {
      pauseAutoScroll();
    }
  }

  // --------------------------------------------------------- auto-scroll ---

  void toggleAutoScroll() {
    if (_autoScrolling) {
      pauseAutoScroll();
    } else {
      startAutoScroll();
    }
  }

  void startAutoScroll() {
    if (_autoScrolling) {
      return;
    }
    _autoScrolling = true;
    setChromeVisible(false);
    if (_scrollMode == ScrollMode.horizontal) {
      _startPageTurning();
    } else {
      _lastTick = null;
      if (!_ticker.isActive) {
        _ticker.start();
      }
    }
    _notify();
  }

  void pauseAutoScroll() {
    if (!_autoScrolling) {
      return;
    }
    _autoScrolling = false;
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastTick = null;
    _pageTurnTimer?.cancel();
    _pageTurnTimer = null;
    _notify();
    _scheduleSave();
  }

  void setSpeed(double value) {
    final double next = value.clamp(0.05, 1.0).toDouble();
    if ((next - _speed).abs() < 0.004) {
      return;
    }
    _speed = next;
    _notify();
  }

  double get _pixelsPerSecond => 14 + _speed * 150;

  void _onTick(Duration elapsed) {
    if (_disposed || !_autoScrolling) {
      return;
    }
    final Duration previous = _lastTick ?? elapsed;
    _lastTick = elapsed;
    final double dt =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0 || !scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = scrollController.position;
    final double next = position.pixels + _pixelsPerSecond * dt;
    if (next >= position.maxScrollExtent) {
      scrollController.jumpTo(position.maxScrollExtent);
      pauseAutoScroll();
      return;
    }
    scrollController.jumpTo(next);
  }

  void _startPageTurning() {
    _pageTurnTimer?.cancel();
    final int intervalMs =
        (9000 - _speed * 6500).round().clamp(2200, 9000).toInt();
    _pageTurnTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (Timer timer) {
        if (_disposed || !_autoScrolling) {
          timer.cancel();
          return;
        }
        final int next = _currentPage + 1;
        if (next > _pageCount) {
          pauseAutoScroll();
          return;
        }
        if (pageController.hasClients) {
          unawaited(pageController.animateToPage(
            next - 1,
            duration: Motion.slow,
            curve: Motion.emphasized,
          ));
        }
      },
    );
  }

  // ----------------------------------------------------------- display -----

  void setFilter(PageFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    _notify();
  }

  void setDim(double value) {
    final double next = value.clamp(0.0, 0.75).toDouble();
    if ((next - _dim).abs() < 0.004) {
      return;
    }
    _dim = next;
    _notify();
  }

  void setScrollMode(ScrollMode mode) {
    if (_scrollMode == mode) {
      return;
    }
    final int page = _currentPage;
    if (_autoScrolling) {
      pauseAutoScroll();
    }
    _scrollMode = mode;
    _notify();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        jumpToPage(page);
      }
    });
  }

  // ------------------------------------------------------------ scrubber ---

  int _pageForFraction(double fraction) {
    if (_pageCount <= 1) {
      return 1;
    }
    final double clamped = fraction.clamp(0.0, 1.0).toDouble();
    return (clamped * (_pageCount - 1)).round() + 1;
  }

  void beginScrub(double fraction) {
    _scrubbing = true;
    _scrubProgress = fraction.clamp(0.0, 1.0).toDouble();
    _scrubPage = _pageForFraction(_scrubProgress);
    setChromeVisible(true);
    _notify();
  }

  void updateScrub(double fraction) {
    if (!_scrubbing) {
      beginScrub(fraction);
      return;
    }
    _scrubProgress = fraction.clamp(0.0, 1.0).toDouble();
    _scrubPage = _pageForFraction(_scrubProgress);
    _notify();
  }

  void endScrub() {
    if (!_scrubbing) {
      return;
    }
    final int page = _scrubPage ?? _currentPage;
    _scrubbing = false;
    _scrubPage = null;
    _notify();
    jumpToPage(page, animate: true);
  }

  void jumpToProgress(double fraction) {
    jumpToPage(_pageForFraction(fraction), animate: true);
  }

  // ---------------------------------------------------------- indicator ----

  void _flashIndicator() {
    if (!_indicatorVisible) {
      _indicatorVisible = true;
      _notify();
    }
    final DateTime now = DateTime.now();
    if (_indicatorTimer != null &&
        now.difference(_lastIndicatorTouch).inMilliseconds < 120) {
      return;
    }
    _lastIndicatorTouch = now;
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(Motion.idle, () {
      if (_disposed) {
        return;
      }
      _indicatorVisible = false;
      _notify();
    });
  }

  // --------------------------------------------------------- persistence ---

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 650), () {
      unawaited(_saveQuietly(_snapshotPosition()));
    });
  }

  ReadingPosition _snapshotPosition() {
    double fraction = 0;
    final PageLayout? layout = _layout;
    if (_scrollMode == ScrollMode.vertical &&
        layout != null &&
        scrollController.hasClients) {
      final double local =
          (scrollController.offset - topInset).clamp(0.0, layout.extent).toDouble();
      fraction = layout.fractionWithinPage(_currentPage - 1, local);
    }
    return ReadingPosition(
      documentId: document.id,
      page: _currentPage,
      progress: _progress,
      offsetFraction: fraction,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveQuietly(ReadingPosition position) async {
    try {
      await readingState.savePosition(position);
    } catch (_) {
      // Losing one position write is not worth interrupting reading.
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final ReadingPosition finalPosition = _snapshotPosition();
    _disposed = true;
    _indicatorTimer?.cancel();
    _saveTimer?.cancel();
    _pageTurnTimer?.cancel();
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _ticker.dispose();
    scrollController.removeListener(_handleVerticalScroll);
    pageController.removeListener(_handlePagedScroll);
    scrollController.dispose();
    pageController.dispose();
    unawaited(_saveQuietly(finalPosition));
    super.dispose();
  }
}
