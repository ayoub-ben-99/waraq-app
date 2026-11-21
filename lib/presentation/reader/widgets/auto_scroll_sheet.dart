import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/labeled_slider.dart';
import '../../../core/widgets/waraq_sheet.dart';
import '../reader_controller.dart';

/// Play/pause plus a speed dial for hands-free reading.
class AutoScrollSheet extends StatelessWidget {
  const AutoScrollSheet({
    required this.controller,
    required this.onSpeedCommitted,
    super.key,
  });

  final ReaderController controller;
  final ValueChanged<double> onSpeedCommitted;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);

    return WaraqSheet(
      title: strings.autoScrollTitle,
      subtitle: strings.autoScrollHint,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final bool running = controller.isAutoScrolling;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FilledButton.icon(
                onPressed: controller.toggleAutoScroll,
                icon: _SwappingIcon(
                  icon: running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  running ? strings.autoScrollPause : strings.autoScrollStart,
                ),
              ),
              const SizedBox(height: Gap.xl),
              LabeledSlider(
                value: controller.speed,
                min: 0.05,
                max: 1,
                icon: Icons.speed_rounded,
                startLabel: strings.speedSlow,
                endLabel: strings.speedFast,
                valueLabel: formatAutoScrollSpeed(controller.speed),
                onChanged: controller.setSpeed,
                onChangeEnd: onSpeedCommitted,
              ),
              const SizedBox(height: Gap.xs),
            ],
          );
        },
      ),
    );
  }
}

/// Swaps the leading icon with a quick scale/fade so play ⇄ pause reads as a
/// state change rather than a redraw.
class _SwappingIcon extends StatelessWidget {
  const _SwappingIcon({required this.icon, this.size = 18, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.fast,
      switchInCurve: Motion.emphasized,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Icon(icon, key: ValueKey<IconData>(icon), size: size),
    );
  }
}
