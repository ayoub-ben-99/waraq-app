import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/reveal.dart';
import '../../core/widgets/round_icon_button.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reading_position.dart';
import '../providers/library_providers.dart';
import '../reader/reader_route.dart';
import '../widgets/continue_card.dart';
import '../widgets/delete_document.dart';
import '../widgets/document_row.dart';
import '../widgets/import_document.dart';

/// Greeting, the resume card, and the most recent documents.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<List<PdfDocument>> documentsAsync =
        ref.watch(documentsProvider);
    final List<PdfDocument> documents =
        documentsAsync.valueOrNull ?? const <PdfDocument>[];
    final ContinueReading? resume = ref.watch(continueReadingProvider);
    final Map<String, ReadingPosition> positions =
        ref.watch(positionsProvider).valueOrNull ??
            const <String, ReadingPosition>{};
    final int librarySize = ref.watch(librarySizeProvider);
    final bool importing = ref.watch(importBusyProvider);
    final bool loading = documentsAsync.isLoading && documents.isEmpty;

    final String greeting = switch (greetingForHour(DateTime.now().hour)) {
      DayGreeting.morning => strings.greetingMorning,
      DayGreeting.afternoon => strings.greetingAfternoon,
      DayGreeting.evening => strings.greetingEvening,
      DayGreeting.night => strings.greetingNight,
    };

    final List<PdfDocument> recent = documents.take(8).toList(growable: false);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontal = math.max(
            Gap.xl,
            (constraints.maxWidth - Sizes.maxContentWidth) / 2,
          );
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Gap.m,
                  horizontal - Gap.xs,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Reveal(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                strings.wordmark,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                  letterSpacing: strings.isArabic ? 0 : 4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: Gap.s),
                              Text(
                                greeting,
                                style: theme.textTheme.displaySmall,
                              ),
                              const SizedBox(height: Gap.xs),
                              Text(
                                strings.librarySummary(
                                  documents.length,
                                  formatBytes(librarySize),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.m),
                        RoundIconButton(
                          icon: importing
                              ? Icons.hourglass_top_rounded
                              : Icons.add_rounded,
                          tooltip: importing
                              ? strings.importing
                              : strings.importPdf,
                          emphasized: true,
                          onPressed: importing
                              ? null
                              : () => unawaited(
                                    pickAndImportPdf(context, ref),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (resume != null)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverToBoxAdapter(
                    child: Reveal(
                      index: 1,
                      child: ContinueCard(
                        entry: resume,
                        onTap: () => unawaited(
                          openReader(context, ref, resume.document),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: strings.sectionRecent,
                    trailing: documents.isEmpty
                        ? null
                        : Text(
                            strings.documentsCount(documents.length),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
              if (loading)
                SliverToBoxAdapter(
                  child: _RecentSkeleton(horizontal: horizontal),
                )
              else if (recent.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.auto_stories_outlined,
                      title: strings.emptyLibraryTitle,
                      message: strings.emptyLibraryBody,
                      action: FilledButton.icon(
                        onPressed: importing
                            ? null
                            : () => unawaited(pickAndImportPdf(context, ref)),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(strings.importPdf),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final PdfDocument document = recent[index];
                        return Reveal(
                          index: index + 2,
                          offset: 8,
                          child: DocumentRow(
                            document: document,
                            position: positions[document.id],
                            onTap: () => unawaited(
                              openReader(context, ref, document),
                            ),
                            onLongPress: () => unawaited(
                              confirmDeleteDocument(context, ref, document),
                            ),
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: Gap.xxxl * 2)),
            ],
          );
        },
      ),
    );
  }
}

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton({required this.horizontal});

  final double horizontal;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.s),
              child: Row(
                children: <Widget>[
                  Container(
                    width: Sizes.thumbnailWidth,
                    height: Sizes.thumbnailHeight,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Sizes.thumbnailRadius),
                    ),
                  ),
                  const SizedBox(width: Gap.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          height: 12,
                          width: 180,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                        const SizedBox(height: Gap.s),
                        Container(
                          height: 9,
                          width: 110,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh.withFraction(0.7),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
