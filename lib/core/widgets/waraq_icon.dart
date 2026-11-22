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

  /// Directional glyphs are mirrored by the framework when this is true.
  final bool mirrorInRtl;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Icon(
      icon,
      size: size,
      color: color ?? scheme.onSurfaceVariant,
      semanticLabel: semanticLabel,
      matchTextDirection: mirrorInRtl,
    );
  }
}
