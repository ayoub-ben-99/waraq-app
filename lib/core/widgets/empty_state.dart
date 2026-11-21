import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Soft empty state: one large tonal icon, a line of text, then an action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double circle = compact ? 64 : 84;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Gap.xl,
        vertical: compact ? Gap.l : Gap.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withFraction(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 28 : 36,
              color: scheme.onSecondaryContainer,
            ),
          ),
          SizedBox(height: compact ? Gap.m : Gap.l),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: Gap.s),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: Gap.l),
            action!,
          ],
        ],
      ),
    );
  }
}
