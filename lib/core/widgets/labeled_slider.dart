import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Slider with a leading icon, two end labels and an optional value chip.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    required this.value,
    required this.onChanged,
    this.icon,
    this.startLabel,
    this.endLabel,
    this.valueLabel,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final IconData? icon;
  final String? startLabel;
  final String? endLabel;
  final String? valueLabel;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: Gap.s),
            ],
            Text(
              startLabel ?? '',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (valueLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.m,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  valueLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: Gap.s),
            Text(
              endLabel ?? '',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
