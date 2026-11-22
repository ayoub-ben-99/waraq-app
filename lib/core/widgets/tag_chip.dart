import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/shape_motion.dart';
import '../theme/tokens.dart';
import '../../domain/entities/note_tag.dart';

/// Material 3 filter chip tinted with the tag's own colour.
class TagFilterChip extends StatelessWidget {
  const TagFilterChip({
    required this.tag,
    required this.selected,
    required this.onSelected,
    this.count,
    this.onLongPress,
    super.key,
  });

  final NoteTag tag;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color tint = tagColor(tag.colorIndex);

    return GestureDetector(
      onLongPress: onLongPress,
      child: FilterChip(
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        avatar: Icon(
          Icons.sell_rounded,
          size: 16,
          color: selected ? scheme.onSecondaryContainer : tint,
        ),
        label: Text(
          count == null ? tag.name : '${tag.name} · $count',
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? scheme.onSecondaryContainer : null,
          ),
        ),
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant.withFraction(0.6)),
      ),
    );
  }
}

/// Non-interactive pill used inside note cards.
class TagPill extends StatelessWidget {
  const TagPill({required this.tag, super.key});

  final NoteTag tag;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = tagColor(tag.colorIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 2),
      decoration: BoxDecoration(
        color: color.withFraction(0.14),
        borderRadius: WaraqShape.of(context).allPill,
      ),
      child: Text(
        tag.name,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Square colour dot used in the tag manager.
class TagDot extends StatelessWidget {
  const TagDot({required this.colorIndex, this.size = 12, super.key});

  final int colorIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tagColor(colorIndex),
        shape: BoxShape.circle,
      ),
    );
  }
}
