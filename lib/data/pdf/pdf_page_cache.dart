import 'dart:async';
import 'dart:typed_data';

import 'pdf_renderer.dart';

/// Small LRU of rendered page bitmaps.
///
/// Keys include the render resolution, rounded to a coarse bucket, so pinching
/// does not queue dozens of near-identical renders. Neighbouring pages are
/// pre-rendered by the reader, which keeps scrolling at frame rate.
class PdfPageCache {
  PdfPageCache({
    required this.renderer,
    this.maxEntries = 6,
    this.maxRenderWidth = 1600,
    this.minRenderWidth = 320,
  });

  final PdfRenderer renderer;
  final int maxEntries;
  final double maxRenderWidth;
  final double minRenderWidth;

  /// Insertion-ordered map used as an LRU list.
  final Map<String, Uint8List> _entries = <String, Uint8List>{};
  final Map<String, Future<Uint8List>> _inFlight = <String, Future<Uint8List>>{};

  static String keyFor(int pageIndex, double width) {
    final int bucket = (width / 96).round().clamp(1, 64);
    return '$pageIndex@$bucket';
  }

  Uint8List? cached(int pageIndex, double width) {
    final String key = keyFor(pageIndex, width);
    final Uint8List? bytes = _entries[key];
    if (bytes != null) {
      _touch(key, bytes);
    }
    return bytes;
  }

  Future<Uint8List> load(int pageIndex, double width) {
    final String key = keyFor(pageIndex, width);
    final Uint8List? existing = _entries[key];
    if (existing != null) {
      _touch(key, existing);
      return Future<Uint8List>.value(existing);
    }
    final Future<Uint8List>? pending = _inFlight[key];
    if (pending != null) {
      return pending;
    }
    final double target =
        width.clamp(minRenderWidth, maxRenderWidth).toDouble();
    final Future<Uint8List> future = renderer
        .renderPage(pageIndex, targetWidth: target)
        .then((Uint8List bytes) {
      _entries[key] = bytes;
      _evict();
      return bytes;
    });
    _inFlight[key] = future;
    unawaited(future.whenComplete(() {
      _inFlight.remove(key);
    }));
    return future;
  }

  /// Warms pages around [pageIndex] without blocking the caller.
  void prefetchAround(int pageIndex, double width, {int radius = 2}) {
    for (int delta = 1; delta <= radius; delta++) {
      for (final int index in <int>[pageIndex + delta, pageIndex - delta]) {
        if (index < 0 || index >= renderer.pageCount) {
          continue;
        }
        final String key = keyFor(index, width);
        if (_entries.containsKey(key) || _inFlight.containsKey(key)) {
          continue;
        }
        unawaited(load(index, width).then<void>(
          (_) {},
          onError: (Object _) {},
        ));
      }
    }
  }

  void clear() {
    _entries.clear();
  }

  void _touch(String key, Uint8List bytes) {
    if (_entries.length <= 1) {
      return;
    }
    _entries.remove(key);
    _entries[key] = bytes;
  }

  void _evict() {
    while (_entries.length > maxEntries) {
      final String? oldest = _entries.keys.firstOrNull;
      if (oldest == null) {
        return;
      }
      _entries.remove(oldest);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final Iterator<T> iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
