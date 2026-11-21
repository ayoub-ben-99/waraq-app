import 'dart:async';

import 'package:flutter/widgets.dart';

/// Raw pointer handling for the page canvas.
///
/// Using a [Listener] instead of gesture recognisers means pinch-to-zoom never
/// fights the scroll view for the gesture arena: single-finger drags scroll as
/// usual, while a second finger starts a zoom. Taps and double-taps are
/// detected here too, so showing the toolbar feels instant instead of waiting
/// for the double-tap timeout.
class ReaderGestureLayer extends StatefulWidget {
  const ReaderGestureLayer({
    required this.child,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPointerDown,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onPointerDown;
  final VoidCallback onScaleStart;
  final ValueChanged<double> onScaleUpdate;
  final VoidCallback onScaleEnd;
  final bool enabled;

  @override
  State<ReaderGestureLayer> createState() => _ReaderGestureLayerState();
}

class _ReaderGestureLayerState extends State<ReaderGestureLayer> {
  final Map<int, Offset> _pointers = <int, Offset>{};

  double? _baseDistance;
  Offset? _downPosition;
  DateTime? _downAt;
  Offset? _lastTapPosition;
  DateTime? _lastTapAt;
  bool _isSecondTap = false;
  Timer? _tapTimer;
  bool _moved = false;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  double _distance() {
    final List<Offset> points = _pointers.values.toList(growable: false);
    if (points.length < 2) {
      return 0;
    }
    return (points[0] - points[1]).distance;
  }

  void _handleDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    if (_pointers.length == 1) {
      final DateTime now = DateTime.now();
      final DateTime? lastAt = _lastTapAt;
      final Offset? lastPosition = _lastTapPosition;
      // A second press that lands quickly and close by is a double tap: cancel
      // the pending single tap so the toolbar does not flash in between.
      _isSecondTap = lastAt != null &&
          lastPosition != null &&
          now.difference(lastAt).inMilliseconds < 340 &&
          (event.position - lastPosition).distance < 44;
      if (_isSecondTap) {
        _tapTimer?.cancel();
        _tapTimer = null;
        _lastTapAt = null;
        _lastTapPosition = null;
      }
      _downPosition = event.position;
      _downAt = now;
      _moved = false;
      widget.onPointerDown();
    } else if (_pointers.length == 2 && widget.enabled) {
      _baseDistance = _distance();
      widget.onScaleStart();
    }
  }

  void _handleMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) {
      return;
    }
    _pointers[event.pointer] = event.position;
    final Offset? down = _downPosition;
    if (down != null && (event.position - down).distance > 12) {
      _moved = true;
    }
    final double? base = _baseDistance;
    if (widget.enabled &&
        _pointers.length >= 2 &&
        base != null &&
        base > 1) {
      widget.onScaleUpdate(_distance() / base);
    }
  }

  void _handleUp(PointerUpEvent event) {
    final Offset? down = _downPosition;
    final DateTime? downAt = _downAt;
    final bool secondTap = _isSecondTap;
    _release(event.pointer);

    // Only a press that was the last finger down, stayed put and was short
    // counts as a tap.
    if (_pointers.isNotEmpty || _moved || down == null || downAt == null) {
      return;
    }
    if (DateTime.now().difference(downAt).inMilliseconds > 320) {
      return;
    }

    if (secondTap) {
      // Paged mode zooms the page itself, so only the column reports it here.
      if (widget.enabled) {
        widget.onDoubleTap();
      }
      return;
    }

    _lastTapAt = DateTime.now();
    _lastTapPosition = event.position;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onTap();
      }
    });
  }

  void _handleCancel(PointerCancelEvent event) {
    _release(event.pointer);
  }

  void _release(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.length < 2 && _baseDistance != null) {
      _baseDistance = null;
      widget.onScaleEnd();
    }
    if (_pointers.isEmpty) {
      _downPosition = null;
      _downAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleDown,
      onPointerMove: _handleMove,
      onPointerUp: _handleUp,
      onPointerCancel: _handleCancel,
      child: widget.child,
    );
  }
}
