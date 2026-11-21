import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/document_cover.dart';
import '../../core/widgets/pressable_scale.dart';
import '../providers/library_providers.dart';

/// Hero card that resumes the most recently read document.
class ContinueCard extends StatelessWidget {
  const ContinueCard({required this.entry, required this.onTap, super.key});

  final ContinueReading entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: Gap.xl),
      child: PressableScale(
        onTap: onTap,
        borderRadius: WaraqShape.of(context).allXl,
        child: Container(
          padding: const EdgeInsets.all(Gap.xl),
          decoration: BoxDecoration(
            borderRadius: WaraqShape.of(context).allXl,
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: <Color>[
                scheme.primaryContainer,
                Color.alphaBlend(
                  scheme.tertiaryContainer.withFraction(0.75),
                  scheme.primaryContainer,
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          strings.continueReading.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimaryContainer.withFraction(0.75),
                            letterSpacing: strings.isArabic ? 0 : 1.7,
                          ),
                        ),
                        const SizedBox(height: Gap.m),
                        Text(
                          entry.document.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: Gap.m),
                        Text(
                          '${strings.pageOf(entry.position.page, entry.document.pageCount)} · ${strings.percent(entry.percent)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer.withFraction(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.l),
                  DocumentCover(
                    document: entry.document,
                    width: 64,
                    height: 86,
                    radius: Radii.sm,
                  ),
                ],
              ),
              const SizedBox(height: Gap.l),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: entry.position.progress.clamp(0.0, 1.0).toDouble(),
                        minHeight: 5,
                        backgroundColor:
                            scheme.onPrimaryContainer.withFraction(0.16),
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.m),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
