import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/shape_motion.dart';
import '../theme/tokens.dart';

/// The signature entrance: fade in and rise a few pixels, staggered by index.
/// Plays once on first paint and honours the platform "reduce motion" setting.
class Reveal extends StatefulWidget {
  const Reveal({
    required this.child,
    this.index = 0,
    this.offset = 12,
    this.duration,
    super.key,
  });

  final Widget child;

  /// Position in a list; each step delays the reveal by [Motion.stagger].
  final int index;
  final double offset;
  final Duration? duration;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration ?? Motion.base,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.decelerate,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final WaraqMotion motion = WaraqMotion.of(context);
    if (reduceMotion || !motion.enabled) {
      _controller.value = 1;
      return;
    }
    _controller.duration = motion.of(widget.duration ?? Motion.base);
    final Duration delay = motion.stagger * widget.index.clamp(0, 8);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
    );
  }
}
