import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../providers/library_providers.dart';

/// Four compact numbers plus the average reading progress across the shelf.
class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.stats, super.key});

  final LibraryStats stats;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final WaraqMotion motion = WaraqMotion.of(context);

    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: shape.allLg,
        border: Border.all(color: scheme.outlineVariant.withFraction(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCell(
                  icon: Icons.menu_book_rounded,
                  value: '${stats.documents}',
                  label: strings.statsDocuments,
                ),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: _StatCell(
                  icon: Icons.auto_stories_outlined,
                  value: '${stats.pages}',
                  label: strings.statsPages,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCell(
                  icon: Icons.bookmark_rounded,
                  value: '${stats.bookmarks}',
                  label: strings.statsBookmarks,
                ),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: _StatCell(
                  icon: Icons.sd_storage_rounded,
                  value: formatBytes(stats.storageBytes),
                  label: strings.statsStorage,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withFraction(0.4),
          ),
          const SizedBox(height: Gap.m),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  strings.statsProgress,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${stats.progressPercent}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          ClipRRect(
            borderRadius: shape.allPill,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: stats.averageProgress),
              duration: motion.base,
              curve: Motion.emphasized,
              builder: (BuildContext context, double value, Widget? child) {
                return LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0).toDouble(),
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withFraction(0.1),
            borderRadius: shape.allSm,
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
