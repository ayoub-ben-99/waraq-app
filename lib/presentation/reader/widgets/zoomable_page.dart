import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/pdf/pdf_page_cache.dart';
import '../../../domain/entities/page_geometry.dart';
import '../../../domain/entities/reader_settings.dart';
import 'pdf_page_view.dart';

/// A page that can be pinched and double-tapped in paged (horizontal) mode,
/// where the document zoom is handled per page instead of by the layout.
class ZoomablePage extends StatefulWidget {
  const ZoomablePage({
    required this.pageSize,
    required this.pageIndex,
    required this.cache,
    required this.pixelRatio,
    this.filter = PageFilter.none,
    super.key,
  });

  final PageSize pageSize;
  final int pageIndex;
  final PdfPageCache cache;
  final double pixelRatio;
  final PageFilter filter;

  @override
  State<ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<ZoomablePage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: Motion.base,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _animation,
    curve: Motion.emphasized,
  );

  Animation<Matrix4>? _tween;
  bool _zoomed = false;
  Size _childSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_handleTransform);
    _animation.addListener(_applyTween);
  }

  @override
  void dispose() {
    _transform.removeListener(_handleTransform);
    _animation.removeListener(_applyTween);
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _handleTransform() {
    final bool zoomed = _transform.value.getMaxScaleOnAxis() > 1.02;
    if (zoomed != _zoomed && mounted) {
      setState(() => _zoomed = zoomed);
    }
  }

  void _applyTween() {
    final Animation<Matrix4>? tween = _tween;
    if (tween != null) {
      _transform.value = tween.value;
    }
  }

  void _toggleZoom() {
    final bool zoomIn = _transform.value.getMaxScaleOnAxis() < 1.5;
    final Matrix4 target = Matrix4.identity();
    if (zoomIn && _childSize.width > 0 && _childSize.height > 0) {
      // 2× around the centre of the page.
      target.setEntry(0, 0, 2);
      target.setEntry(1, 1, 2);
      target.setEntry(0, 3, -_childSize.width / 2);
      target.setEntry(1, 3, -_childSize.height / 2);
    }
    _tween = Matrix4Tween(begin: _transform.value, end: target).animate(_curve);
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double aspect = widget.pageSize.aspectRatio;
        double width = constraints.maxWidth;
        double height = width / aspect;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * aspect;
        }
        _childSize = Size(width, height);
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 4,
                panEnabled: _zoomed,
                scaleEnabled: true,
                child: PdfPageView(
                  cache: widget.cache,
                  pageIndex: widget.pageIndex,
                  width: width,
                  height: height,
                  pixelRatio: widget.pixelRatio,
                  filter: widget.filter,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
