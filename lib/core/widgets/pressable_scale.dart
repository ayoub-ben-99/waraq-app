import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Press feedback used by every tappable card: a soft spring down to 0.97 and
/// back, plus the platform ripple.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.scale = 0.97,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: reduceMotion ? Duration.zero : Motion.tap,
      curve: Motion.emphasized,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: widget.borderRadius,
          onHighlightChanged: _setPressed,
          child: widget.child,
        ),
      ),
    );
  }
}
