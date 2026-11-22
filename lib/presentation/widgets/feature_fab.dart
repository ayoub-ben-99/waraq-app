import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/waraq_icon.dart';
import '../shell/feature_actions.dart';

/// A single floating button that unfolds the app's actions in a staggered arc.
///
/// Paper has FAB.Group, Flutter does not, and the staggered entrance plus the
/// rotating glyph are easier to express with one [AnimationController].
class FeatureFab extends ConsumerStatefulWidget {
  const FeatureFab({super.key});

  @override
  ConsumerState<FeatureFab> createState() => _FeatureFabState();
}

class _FeatureFabState extends ConsumerState<FeatureFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  bool get _open => _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.completed;

  void _toggle() {
    if (_open) {
      unawaited(_controller.reverse());
    } else {
      unawaited(_controller.forward());
    }
    setState(() {});
  }

  Future<void> _run(FeatureAction action) async {
    await _controller.reverse();
    if (!mounted) {
      return;
    }
    await action.invoke(context, ref);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final bool animate = WaraqMotion.of(context).enabled;

    return Stack(
      children: <Widget>[
        // Tap anywhere outside to close.
        IgnorePointer(
          ignoring: !_open,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return Container(
                  color: scheme.scrim.withFraction(0.28 * _controller.value),
                );
              },
            ),
          ),
        ),
        PositionedDirectional(
          end: Gap.xl,
          bottom: Gap.l,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int index = kFeatureActions.length - 1; index >= 0; index--)
                _ActionRow(
                  action: kFeatureActions[index],
                  index: index,
                  total: kFeatureActions.length,
                  controller: _controller,
                  animate: animate,
                  onTap: () => unawaited(_run(kFeatureActions[index])),
                ),
              const SizedBox(height: Gap.s),
              FloatingActionButton(
                onPressed: _toggle,
                tooltip: _open ? strings.close : strings.fabActions,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: shape.allLg),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    return Transform.rotate(
                      angle: _controller.value * 0.785,
                      child: Icon(_open ? Icons.close_rounded : Icons.add_rounded),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.index,
    required this.total,
    required this.controller,
    required this.animate,
    required this.onTap,
  });

  final FeatureAction action;
  final int index;
  final int total;
  final AnimationController controller;
  final bool animate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);

    // Bottom-most row leaves first, so the list feels like it unfolds upwards.
    final double start = (index * 0.05).clamp(0.0, 0.4).toDouble();
    final Animation<double> curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (BuildContext context, Widget? child) {
        final double value = curve.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(top: index == total - 1 ? 0 : Gap.s),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: shape.allPill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                Gap.l,
                Gap.s,
                Gap.s,
                Gap.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    action.label(strings),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(width: Gap.s),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: WaraqIcon(
                        action.icon,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
