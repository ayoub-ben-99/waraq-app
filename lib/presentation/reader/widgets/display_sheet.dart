import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/page_filters.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/labeled_slider.dart';
import '../../../core/widgets/waraq_sheet.dart';
import '../../../domain/entities/reader_settings.dart';
import '../reader_controller.dart';

/// Page tone, brightness and scroll direction for the open document.
class DisplaySheet extends StatelessWidget {
  const DisplaySheet({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final ReaderController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return WaraqSheet(
      title: strings.displayTitle,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                strings.pageToneTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Gap.m),
              Row(
                children: <Widget>[
                  for (final PageFilter filter in PageFilter.values) ...<Widget>[
                    Expanded(
                      child: _ToneTile(
                        label: switch (filter) {
                          PageFilter.none => strings.toneOriginal,
                          PageFilter.sepia => strings.toneSepia,
                          PageFilter.night => strings.toneNight,
                        },
                        filter: filter,
                        selected: controller.filter == filter,
                        onTap: () {
                          controller.setFilter(filter);
                          onChanged();
                        },
                      ),
                    ),
                    if (filter != PageFilter.values.last)
                      const SizedBox(width: Gap.s),
                  ],
                ],
              ),
              const SizedBox(height: Gap.xl),
              Text(
                strings.brightnessTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              LabeledSlider(
                value: controller.dim,
                max: 0.75,
                icon: Icons.brightness_6_rounded,
                startLabel: '\u2600',
                endLabel: '\u263D',
                valueLabel: '${(100 - controller.dim / 0.75 * 60).round()}%',
                onChanged: controller.setDim,
                onChangeEnd: (double _) => onChanged(),
              ),
              Text(
                strings.brightnessHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Gap.xl),
              Text(
                strings.scrollModeTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Gap.m),
              SegmentedButton<ScrollMode>(
                showSelectedIcon: false,
                segments: <ButtonSegment<ScrollMode>>[
                  ButtonSegment<ScrollMode>(
                    value: ScrollMode.vertical,
                    icon: const Icon(Icons.swap_vert_rounded, size: 18),
                    label: Text(strings.scrollModeVertical),
                  ),
                  ButtonSegment<ScrollMode>(
                    value: ScrollMode.horizontal,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(strings.scrollModeHorizontal),
                  ),
                ],
                selected: <ScrollMode>{controller.scrollMode},
                onSelectionChanged: (Set<ScrollMode> selection) {
                  controller.setScrollMode(selection.first);
                  onChanged();
                },
              ),
              const SizedBox(height: Gap.s),
              Text(
                controller.scrollMode == ScrollMode.vertical
                    ? strings.scrollModeVerticalHint
                    : strings.scrollModeHorizontalHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({
    required this.label,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PageFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ColorFilter? colorFilter = PageFilters.of(filter);

    Widget swatch = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final double widthFactor in <double>[1, 0.86, 0.93, 0.6])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: widthFactor,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (colorFilter != null) {
      swatch = ColorFiltered(colorFilter: colorFilter, child: swatch);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Gap.s + 6),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.emphasized,
        padding: const EdgeInsets.all(Gap.s),
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Gap.s + 6),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: SizedBox(height: 52, child: swatch),
            ),
            const SizedBox(height: Gap.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (selected) ...<Widget>[
                  Icon(Icons.check_rounded, size: 14, color: scheme.primary),
                  const SizedBox(width: 3),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
