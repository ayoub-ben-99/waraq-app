import 'dart:async';
import 'dart:typed_data';

import 'package:pdfx/pdfx.dart' as pdfx;

import '../../domain/entities/page_geometry.dart';

/// Any failure coming from the PDF engine.
class PdfRenderException implements Exception {
  const PdfRenderException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'PdfRenderException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Thin, opinionated wrapper around `pdfx`.
///
/// This is the only file in the app that knows about the PDF engine, so a
/// different engine can be swapped in without touching the reader. Rendering is
/// serialised because Android allows a single open page per document.
class PdfRenderer {
  PdfRenderer._(this._document, this.pageSizes);

  final pdfx.PdfDocument _document;
  final List<PageSize> pageSizes;

  Future<void> _queue = Future<void>.value();
  bool _closed = false;

  int get pageCount => pageSizes.length;

  static Future<PdfRenderer> open(
    String filePath, {
    void Function(int done, int total)? onProgress,
  }) async {
    pdfx.PdfDocument document;
    try {
      document = await pdfx.PdfDocument.openFile(filePath);
    } catch (error) {
      throw PdfRenderException('Could not open the document', error);
    }

    final int count = document.pagesCount;
    final List<PageSize> sizes = <PageSize>[];
    for (int pageNumber = 1; pageNumber <= count; pageNumber++) {
      try {
        final pdfx.PdfPage page = await document.getPage(pageNumber);
        final PageSize size = PageSize(width: page.width, height: page.height);
        await page.close();
        sizes.add(size.isValid ? size : (sizes.isEmpty ? PageSize.fallback : sizes.last));
      } catch (_) {
        // A single unreadable page must not make the whole document unusable.
        sizes.add(sizes.isEmpty ? PageSize.fallback : sizes.last);
      }
      if (pageNumber % 12 == 0 || pageNumber == count) {
        onProgress?.call(pageNumber, count);
        // Yield to the frame loop so the progress UI stays responsive.
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (sizes.isEmpty) {
      sizes.add(PageSize.fallback);
    }
    return PdfRenderer._(document, List<PageSize>.unmodifiable(sizes));
  }

  /// Renders one page to PNG bytes at approximately [targetWidth] pixels.
  Future<Uint8List> renderPage(
    int pageIndex, {
    required double targetWidth,
    String backgroundColor = '#FFFFFF',
  }) {
    return _enqueue(() async {
      if (_closed) {
        throw const PdfRenderException('The renderer is closed');
      }
      final int pageNumber = (pageIndex + 1).clamp(1, pageCount);
      final pdfx.PdfPage page = await _document.getPage(pageNumber);
      try {
        final double sourceWidth = page.width > 0 ? page.width : PageSize.fallback.width;
        final double sourceHeight =
            page.height > 0 ? page.height : PageSize.fallback.height;
        final double scale = (targetWidth / sourceWidth).clamp(0.08, 6.0).toDouble();
        final pdfx.PdfPageImage? image = await page.render(
          width: sourceWidth * scale,
          height: sourceHeight * scale,
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: backgroundColor,
        );
        if (image == null) {
          throw PdfRenderException('Page $pageNumber produced no image');
        }
        return image.bytes;
      } finally {
        await page.close();
      }
    });
  }

  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await _queue;
      await _document.close();
    } catch (_) {
      // Nothing useful left to do if the engine refuses to close.
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final Completer<T> completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
