import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 48dp circular action button. Icon-only buttons always carry a label for
/// screen readers.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.emphasized = false,
    this.outlined = false,
    this.size = 48,
    this.iconSize = 22,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool emphasized;
  final bool outlined;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background = emphasized
        ? scheme.primary
        : outlined
            ? Colors.transparent
            : scheme.surfaceContainerHigh;
    final Color foreground = emphasized ? scheme.onPrimary : scheme.onSurface;
    final bool enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: background,
          shape: CircleBorder(
            side: outlined
                ? BorderSide(color: scheme.outlineVariant.withFraction(0.9))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: iconSize,
                color: enabled ? foreground : foreground.withFraction(0.38),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
