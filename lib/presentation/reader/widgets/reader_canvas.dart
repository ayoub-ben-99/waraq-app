import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/waraq_palette.dart';
import '../../../domain/entities/page_geometry.dart';
import '../../../domain/entities/reader_settings.dart';
import '../reader_controller.dart';
import 'pdf_page_view.dart';
import 'reader_gesture_layer.dart';
import 'zoomable_page.dart';

/// Renders the document itself: a continuous column of pages in vertical mode,
/// a paged view in horizontal mode. All chrome lives above this widget.
class ReaderCanvas extends StatefulWidget {
  const ReaderCanvas({required this.controller, super.key});

  final ReaderController controller;

  @override
  State<ReaderCanvas> createState() => _ReaderCanvasState();
}

class _ReaderCanvasState extends State<ReaderCanvas> {
  final ScrollController _panController = ScrollController();

  ScrollMode? _mode;
  double _zoom = 1;
  bool _pinching = false;
  PageFilter? _filter;

  ReaderController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _captureControllerState();
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.restoreInitialPosition();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReaderCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _captureControllerState();
      widget.controller.restoreInitialPosition();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _panController.dispose();
    super.dispose();
  }

  void _captureControllerState() {
    _mode = _controller.scrollMode;
    _zoom = _controller.zoom;
    _pinching = _controller.isPinching;
    _filter = _controller.filter;
  }

  /// Only rebuild for things that change the layout of the canvas; scrolling
  /// and progress updates are handled by the chrome widgets instead.
  void _onControllerChanged() {
    final ReaderController controller = _controller;
    final bool zoomChanged = (controller.zoom - _zoom).abs() > 0.0015;
    if (controller.scrollMode == _mode &&
        !zoomChanged &&
        controller.isPinching == _pinching &&
        controller.filter == _filter) {
      return;
    }
    _captureControllerState();
    if (!mounted) {
      return;
    }
    setState(() {});
    if (zoomChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_panController.hasClients) {
          return;
        }
        final double extent = _panController.position.maxScrollExtent;
        if (extent > 0) {
          _panController.jumpTo(extent / 2);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WaraqPalette palette = WaraqPalette.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final double safeBottom = media.padding.bottom;
    final double pixelRatio = media.devicePixelRatio;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _controller.updateViewport(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        final PageLayout? layout = _controller.layout;
        if (layout != null) {
          _controller.noteRenderWidth(layout.contentWidth * pixelRatio);
        }

        Widget body;
        if (layout == null) {
          body = const SizedBox.expand();
        } else if (_controller.scrollMode == ScrollMode.vertical) {
          body = NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              _controller.handleScrollNotification(notification);
              return false;
            },
            child: _buildVertical(layout, constraints, safeBottom, pixelRatio),
          );
        } else {
          body = _buildHorizontal(safeBottom, pixelRatio);
        }

        return ReaderGestureLayer(
          enabled: _controller.scrollMode == ScrollMode.vertical,
          onPointerDown: _controller.handlePointerDown,
          onTap: _controller.toggleChrome,
          onDoubleTap: _controller.toggleDoubleTapZoom,
          onScaleStart: _controller.beginPinch,
          onScaleUpdate: _controller.updatePinch,
          onScaleEnd: _controller.endPinch,
          child: ColoredBox(color: palette.readerBackdrop, child: body),
        );
      },
    );
  }

  Widget _buildVertical(
    PageLayout layout,
    BoxConstraints constraints,
    double safeBottom,
    double pixelRatio,
  ) {
    final double pageWidth = layout.contentWidth;
    final bool needsPan = pageWidth + Gap.l * 2 > constraints.maxWidth + 0.5;
    final ScrollPhysics physics = _controller.isPinching
        ? const NeverScrollableScrollPhysics()
        : const ClampingScrollPhysics();

    final Widget list = ListView.builder(
      controller: _controller.scrollController,
      physics: physics,
      padding: EdgeInsets.only(
        top: ReaderController.topInset,
        bottom: math.max(Gap.xxl, safeBottom + Gap.xxxl),
      ),
      itemCount: layout.pageCount,
      cacheExtent: 1400,
      itemBuilder: (BuildContext context, int index) {
        final double height = layout.heightFor(index);
        return Padding(
          padding: EdgeInsets.only(bottom: layout.spacing),
          child: Center(
            child: SizedBox(
              width: pageWidth,
              height: height,
              child: PdfPageView(
                key: ValueKey<int>(index),
                cache: _controller.cache,
                pageIndex: index,
                width: pageWidth,
                height: height,
                pixelRatio: pixelRatio,
                filter: _controller.filter,
              ),
            ),
          ),
        );
      },
    );

    if (!needsPan) {
      return list;
    }

    // Zoomed in: the column becomes pannable sideways as well.
    return SingleChildScrollView(
      controller: _panController,
      scrollDirection: Axis.horizontal,
      physics: physics,
      child: SizedBox(
        width: pageWidth + Gap.l * 2,
        height: constraints.maxHeight,
        child: list,
      ),
    );
  }

  Widget _buildHorizontal(double safeBottom, double pixelRatio) {
    final ReaderController controller = _controller;
    return PageView.builder(
      controller: controller.pageController,
      itemCount: controller.pageCount,
      physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
      padEnds: false,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            Gap.m,
            ReaderController.topInset + Gap.xs,
            Gap.m,
            math.max(Gap.l, safeBottom + Gap.l),
          ),
          child: ZoomablePage(
            key: ValueKey<int>(index),
            pageSize: controller.renderer.pageSizes[index],
            pageIndex: index,
            cache: controller.cache,
            pixelRatio: pixelRatio,
            filter: controller.filter,
          ),
        );
      },
    );
  }
}
