import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/shape_motion.dart';
import '../theme/tokens.dart';
import '../utils/links.dart';
import 'pressable_scale.dart';

/// Row that opens an external destination (community group, source code).
class LinkTile extends StatelessWidget {
  const LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    this.accent,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final Color? accent;

  Future<void> _open(BuildContext context) async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool opened = await openExternalLink(url);
    if (!opened) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.linkError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final Color tint = accent ?? scheme.primary;

    return PressableScale(
      onTap: () => unawaited(_open(context)),
      borderRadius: shape.allMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.xs,
          vertical: Gap.s,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withFraction(0.12),
                borderRadius: shape.allSm,
              ),
              child: Icon(icon, size: 20, color: tint),
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.north_west_rounded
                  : Icons.north_east_rounded,
              size: 16,
              color: scheme.onSurfaceVariant.withFraction(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
