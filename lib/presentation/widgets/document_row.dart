import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/document_cover.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reading_position.dart';

/// A document as a list row: cover, title, metadata and reading progress.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    required this.document,
    required this.onTap,
    this.position,
    this.onLongPress,
    super.key,
  });

  final PdfDocument document;
  final ReadingPosition? position;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    final List<String> meta = <String>[
      strings.pagesLabel(document.pageCount),
      formatBytes(document.sizeBytes),
    ];

    return PressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.xs,
          vertical: Gap.s,
        ),
        child: Row(
          children: <Widget>[
            DocumentCover(document: document),
            const SizedBox(width: Gap.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    meta.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Gap.s),
                  if (position != null)
                    _ProgressLine(position: position!)
                  else
                    Text(
                      strings.startReading,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Gap.s),
            Icon(
              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant.withFraction(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.position});

  final ReadingPosition position;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: LinearProgressIndicator(
            value: position.progress.clamp(0.0, 1.0).toDouble(),
            minHeight: 3,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: Gap.xs + 1),
        Text(
          '${position.percentComplete}% · ${formatRelative(position.updatedAt, isArabic: AppStrings.of(context).isArabic)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
