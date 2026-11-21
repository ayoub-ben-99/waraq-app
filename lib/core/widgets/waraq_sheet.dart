import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/shape_motion.dart';
import '../theme/tokens.dart';

/// Shows a rounded, scrollable sheet. Bottom safe-area padding is applied here
/// so callers never have to think about the gesture bar.
Future<T?> showWaraqSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withFraction(0.45),
    builder: builder,
  );
}

class WaraqSheet extends StatelessWidget {
  const WaraqSheet({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.maxHeightFactor = 0.82,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double maxHeightFactor;

  /// Set to `false` when the child scrolls on its own (for example a grid).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double maxHeight =
        MediaQuery.sizeOf(context).height * maxHeightFactor;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.vertical(
            top: WaraqShape.of(context).topXl,
          ),
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withFraction(0.5)),
          ),
        ),
        child: Column(
          mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            const SizedBox(height: Gap.m),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withFraction(0.35),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.m, Gap.s),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            if (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    Gap.xl,
                    Gap.s,
                    Gap.xl,
                    Gap.xl + bottomInset,
                  ),
                  child: child,
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Gap.xl,
                    Gap.s,
                    Gap.xl,
                    Gap.l + bottomInset,
                  ),
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
