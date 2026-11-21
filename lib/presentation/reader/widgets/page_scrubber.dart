import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../reader_controller.dart';

/// Draggable progress rail. Tapping seeks, dragging previews the target page in
/// the floating indicator above it.
class PageScrubber extends StatelessWidget {
  const PageScrubber({required this.controller, super.key});

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final bool dragging = controller.isScrubbing;
        final double fraction = (dragging ? controller.scrubProgress : controller.progress)
            .clamp(0.0, 1.0)
            .toDouble();

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double railInset = Gap.l;
            final double railWidth = math.max(width - railInset * 2, 1);

            double fractionFor(double dx) =>
                ((dx - railInset) / railWidth).clamp(0.0, 1.0).toDouble();

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails details) =>
                  controller.jumpToProgress(fractionFor(details.localPosition.dx)),
              onHorizontalDragStart: (DragStartDetails details) =>
                  controller.beginScrub(fractionFor(details.localPosition.dx)),
              onHorizontalDragUpdate: (DragUpdateDetails details) =>
                  controller.updateScrub(fractionFor(details.localPosition.dx)),
              onHorizontalDragEnd: (DragEndDetails details) => controller.endScrub(),
              onHorizontalDragCancel: controller.endScrub,
              child: SizedBox(
                height: dragging ? 34 : 28,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: railInset,
                      right: railInset,
                      top: dragging ? 14 : 12,
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        height: dragging ? 6 : 4,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                    ),
                    Positioned(
                      left: railInset,
                      width: railWidth * fraction,
                      top: dragging ? 14 : 12,
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        height: dragging ? 6 : 4,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                    ),
                    if (dragging)
                      Positioned(
                        left: (railInset + railWidth * fraction - 9)
                            .clamp(0.0, math.max(width - 18, 0))
                            .toDouble(),
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.surfaceContainerLow,
                              width: 2,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withFraction(0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
