import 'package:flutter/material.dart';

/// One door for every glyph in the app.
///
/// It keeps size, colour and right-to-left mirroring in a single place, so
/// directional icons (chevrons, arrows) flip in Arabic without each call site
/// remembering to ask. Non-directional icons need nothing.
class WaraqIcon extends StatelessWidget {
  const WaraqIcon(
    this.icon, {
    this.size = 22,
    this.color,
    this.mirrorInRtl = false,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final double size;

  /// Defaults to the muted on-surface colour of the theme.
  final Color? color;

  /// Directional glyphs are flipped horizontally under a right-to-left
  /// text direction when this is true.
  final bool mirrorInRtl;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool flip =
        mirrorInRtl && Directionality.of(context) == TextDirection.rtl;
    final Widget glyph = Icon(
      icon,
      size: size,
      color: color ?? scheme.onSurfaceVariant,
      semanticLabel: semanticLabel,
    );
    return flip
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1, 1, 1),
            child: glyph,
          )
        : glyph;
  }
}
