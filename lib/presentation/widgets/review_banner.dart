import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/waraq_icon.dart';
import '../providers/bookmark_providers.dart';
import '../providers/review_providers.dart';
import '../screens/review_screen.dart';

/// Invitation to the daily review, hidden until the reader has written a note.
class ReviewBanner extends ConsumerWidget {
  const ReviewBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final int notes = ref.watch(notesProvider).length;
    final int due = ref.watch(reviewDueCountProvider);

    if (notes == 0) {
      return const SizedBox.shrink();
    }

    return Material(
      color: scheme.primaryContainer,
      borderRadius: shape.allLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const ReviewScreen(),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.m, Gap.m),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.onPrimaryContainer.withFraction(0.1),
                  borderRadius: shape.allMd,
                ),
                child: Icon(
                  Icons.event_repeat_rounded,
                  size: 22,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.homeReviewTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      strings.homeReviewBody(due),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withFraction(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (due > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.s,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: shape.allPill,
                  ),
                  child: Text(
                    '$due',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              WaraqIcon(
                Icons.chevron_right_rounded,
                mirrorInRtl: true,
                color: scheme.onPrimaryContainer.withFraction(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
