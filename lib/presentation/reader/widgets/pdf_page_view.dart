import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/page_filters.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/waraq_palette.dart';
import '../../../data/pdf/pdf_page_cache.dart';
import '../../../domain/entities/reader_settings.dart';

/// One rendered PDF page, with its own loading and error states.
///
/// The bitmap is requested at the exact pixel size it will be shown at, so text
/// stays crisp without decoding gigantic images. Repaints are isolated so
/// neighbouring pages never slow each other down.
class PdfPageView extends StatefulWidget {
  const PdfPageView({
    required this.cache,
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.pixelRatio,
    this.filter = PageFilter.none,
    this.radius = Radii.xs,
    super.key,
  });

  final PdfPageCache cache;
  final int pageIndex;
  final double width;
  final double height;
  final double pixelRatio;
  final PageFilter filter;
  final double radius;

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView> {
  Uint8List? _bytes;
  Object? _error;
  int _token = 0;

  double get _renderWidth => widget.width * widget.pixelRatio;

  @override
  void initState() {
    super.initState();
    _bytes = widget.cache.cached(widget.pageIndex, _renderWidth);
    if (_bytes == null) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(covariant PdfPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool pageChanged = oldWidget.pageIndex != widget.pageIndex;
    final bool widthChanged = (oldWidget.width - widget.width).abs() > 0.5;
    final bool cacheChanged = oldWidget.cache != widget.cache;
    if (!pageChanged && !widthChanged && !cacheChanged) {
      return;
    }
    final Uint8List? cached = widget.cache.cached(widget.pageIndex, _renderWidth);
    if (cached != null) {
      setState(() {
        _bytes = cached;
        _error = null;
      });
      return;
    }
    setState(() {
      _bytes = null;
      _error = null;
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    final int token = ++_token;
    try {
      final Uint8List bytes = await widget.cache.load(
        widget.pageIndex,
        _renderWidth,
      );
      if (!mounted || token != _token) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _error = null;
      });
    } catch (error) {
      if (!mounted || token != _token) {
        return;
      }
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final WaraqPalette palette = WaraqPalette.of(context);
    final bool inverted = PageFilters.isInverted(widget.filter);
    final Color paper = inverted ? Colors.black : palette.pageSurface;
    final ColorFilter? colorFilter = PageFilters.of(widget.filter);

    Widget content;
    final Uint8List? bytes = _bytes;
    if (bytes != null) {
      Widget image = Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _BrokenPage(scheme: theme.colorScheme),
      );
      if (colorFilter != null) {
        image = ColorFiltered(colorFilter: colorFilter, child: image);
      }
      content = image;
    } else if (_error != null) {
      content = _BrokenPage(scheme: theme.colorScheme);
    } else {
      content = _PagePlaceholder(
        scheme: theme.colorScheme,
        pageNumber: widget.pageIndex + 1,
      );
    }

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: 'Page ${widget.pageIndex + 1}',
        child: Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: palette.pageBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.pageShadow,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}

class _PagePlaceholder extends StatelessWidget {
  const _PagePlaceholder({required this.scheme, required this.pageNumber});

  final ColorScheme scheme;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.article_outlined,
            size: 26,
            color: scheme.onSurfaceVariant.withFraction(0.35),
          ),
          const SizedBox(height: Gap.s),
          Text(
            '$pageNumber',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withFraction(0.45),
                ),
          ),
        ],
      ),
    );
  }
}

class _BrokenPage extends StatelessWidget {
  const _BrokenPage({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 26,
        color: scheme.error.withFraction(0.6),
      ),
    );
  }
}
