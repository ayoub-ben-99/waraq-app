import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Icon that pops from 0.6 to 1 whenever its state flips (bookmark on/off).
class PopIcon extends StatefulWidget {
  const PopIcon({
    required this.icon,
    required this.active,
    this.size = 22,
    this.color,
    this.activeColor,
    super.key,
  });

  final IconData icon;
  final bool active;
  final double size;
  final Color? color;
  final Color? activeColor;

  @override
  State<PopIcon> createState() => _PopIconState();
}

class _PopIconState extends State<PopIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );

  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.6, end: 1.16)
            .chain(CurveTween(curve: Motion.decelerate)),
        weight: 55,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.16, end: 1)
            .chain(CurveTween(curve: Motion.emphasized)),
        weight: 45,
      ),
    ],
  ).animate(_controller);

  @override
  void didUpdateWidget(covariant PopIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduceMotion) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.active
            ? (widget.activeColor ?? Theme.of(context).colorScheme.primary)
            : widget.color,
      ),
    );
  }
}
