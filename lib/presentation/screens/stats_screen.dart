import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/reading_stats.dart';
import '../providers/session_providers.dart';

/// Reading history: streaks, the last seven days and lifetime totals.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ReadingStats stats = ref.watch(readingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.statsTitle),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: stats.sessionCount == 0
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.xl),
                  child: EmptyState(
                    icon: Icons.insights_rounded,
                    title: strings.statsEmptyTitle,
                    message: strings.statsEmptyBody,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  Gap.xl,
                  Gap.xs,
                  Gap.xl,
                  Gap.xxl,
                ),
                children: <Widget>[
                  _StreakCard(stats: stats),
                  const SizedBox(height: Gap.l),
                  _ChartCard(stats: stats),
                  const SizedBox(height: Gap.l),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Metric(
                          icon: Icons.today_rounded,
                          label: strings.statsToday,
                          value: formatMinutes(stats.todayMinutes),
                        ),
                      ),
                      const SizedBox(width: Gap.s),
                      Expanded(
                        child: _Metric(
                          icon: Icons.date_range_rounded,
                          label: strings.statsThisWeek,
                          value: formatMinutes(stats.weekMinutes),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.s),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Metric(
                          icon: Icons.auto_stories_rounded,
                          label: strings.statsPagesRead,
                          value: '${stats.totalPages}',
                        ),
                      ),
                      const SizedBox(width: Gap.s),
                      Expanded(
                        child: _Metric(
                          icon: Icons.speed_rounded,
                          label: strings.statsSpeed,
                          value: strings.statsPagesPerHour(
                            stats.pagesPerHour.round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.s),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Metric(
                          icon: Icons.timer_outlined,
                          label: strings.statsTotalTime,
                          value: formatMinutes(stats.totalMinutes),
                        ),
                      ),
                      const SizedBox(width: Gap.s),
                      Expanded(
                        child: _Metric(
                          icon: Icons.event_available_rounded,
                          label: strings.statsSessions,
                          value: '${stats.sessionCount}',
                          tint: scheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);

    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: shape.allXl,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.onPrimaryContainer.withFraction(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 30,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: Gap.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stats.streakDays > 0
                      ? strings.statsStreak(stats.streakDays)
                      : strings.statsStreakNone,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.statsStreakBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withFraction(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final List<int> values = stats.dailyMinutes;
    final int peak = values.fold<int>(0, (int a, int b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: shape.allLg,
        border: Border.all(color: scheme.outlineVariant.withFraction(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.statsLastSevenDays,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gap.l),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int index = 0; index < values.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            values[index] == 0 ? '' : '${values[index]}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Gap.xxs),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: peak == 0 ? 0 : values[index] / peak,
                            ),
                            duration: WaraqMotion.of(context).slow,
                            curve: Motion.emphasized,
                            builder: (
                              BuildContext context,
                              double factor,
                              Widget? child,
                            ) {
                              return Container(
                                height: 8 + 76 * factor,
                                decoration: BoxDecoration(
                                  color: index == values.length - 1
                                      ? scheme.primary
                                      : scheme.primary.withFraction(0.35),
                                  borderRadius: shape.allSm,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Gap.s),
          Row(
            children: <Widget>[
              for (int index = 0; index < stats.dailyLabels.length; index++)
                Expanded(
                  child: Text(
                    '${stats.dailyLabels[index]}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withFraction(0.8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = tint ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(Gap.l),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: WaraqShape.of(context).allLg,
        border: Border.all(color: scheme.outlineVariant.withFraction(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: Gap.s),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
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
    );
  }
}
