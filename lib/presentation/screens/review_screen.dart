import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/document_cover.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/review_scheduler.dart';
import '../providers/bookmark_providers.dart';
import '../providers/review_providers.dart';
import '../reader/reader_route.dart';
import '../widgets/note_editor_sheet.dart';

/// Due notes, the notes coming next, and a one-card-at-a-time session.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<ReviewEntry>? _queue;
  int _index = 0;
  int _known = 0;
  int _graded = 0;

  bool get _inSession => _queue != null;

  void _start(List<ReviewEntry> due) {
    if (due.isEmpty) {
      return;
    }
    setState(() {
      _queue = List<ReviewEntry>.of(due);
      _index = 0;
      _known = 0;
      _graded = 0;
    });
  }

  void _leaveSession() {
    setState(() {
      _queue = null;
      _index = 0;
    });
  }

  Future<void> _grade(ReviewEntry entry, ReviewGrade grade) async {
    await ref
        .read(reviewSchedulesProvider.notifier)
        .grade(entry.note.id, grade);
    if (!mounted) {
      return;
    }
    setState(() {
      _graded++;
      if (grade == ReviewGrade.good) {
        _known++;
      }
      _index++;
    });
  }

  Future<void> _skip(ReviewEntry entry) async {
    await ref.read(reviewSchedulesProvider.notifier).postpone(entry.note.id, 1);
    if (!mounted) {
      return;
    }
    setState(() => _index++);
  }

  Future<void> _postpone(ReviewEntry entry, int days) async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(reviewSchedulesProvider.notifier).postpone(entry.note.id, days);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.reviewPostponed(days))));
  }

  Future<void> _edit(ReviewEntry entry) async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Bookmark? saved = await showNoteEditor(
      context,
      documentId: entry.note.documentId,
      page: entry.note.page,
      pageCount: entry.document.pageCount,
      initialNote: entry.note.note,
    );
    if (saved != null) {
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.noteSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.reviewTitle),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: _inSession
            ? IconButton(
                tooltip: strings.reviewDone,
                onPressed: _leaveSession,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: _inSession ? _buildSession(context, strings) : _buildList(context, strings),
      ),
    );
  }

  // ------------------------------------------------------------------ list ---

  Widget _buildList(BuildContext context, AppStrings strings) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<ReviewEntry> due = ref.watch(reviewDueProvider);
    final List<ReviewEntry> upcoming = ref.watch(reviewUpcomingProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xs, Gap.xl, Gap.xxl),
      children: <Widget>[
        if (due.isEmpty && upcoming.isEmpty)
          EmptyState(
            icon: Icons.event_repeat_rounded,
            title: strings.reviewEmptyTitle,
            message: strings.reviewEmptyBody,
          )
        else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  strings.reviewDueCount(due.length, due.length + upcoming.length),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: due.isEmpty ? null : () => _start(due),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(strings.reviewStart),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          for (final ReviewEntry entry in due) ...<Widget>[
            _ReviewCard(
              entry: entry,
              now: DateTime.now(),
              onTap: () => unawaited(
                openReader(
                  context,
                  ref,
                  entry.document,
                  startPage: entry.note.page,
                ),
              ),
              onEdit: () => unawaited(_edit(entry)),
              onPostpone: () => unawaited(_postpone(entry, 1)),
            ),
            const SizedBox(height: Gap.s),
          ],
          if (upcoming.isNotEmpty) ...<Widget>[
            const SizedBox(height: Gap.l),
            Text(
              strings.reviewUpcoming,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Gap.s),
            for (final ReviewEntry entry in upcoming) ...<Widget>[
              _ReviewCard(
                entry: entry,
                now: DateTime.now(),
                muted: true,
                onTap: () => unawaited(
                  openReader(
                    context,
                    ref,
                    entry.document,
                    startPage: entry.note.page,
                  ),
                ),
                onEdit: () => unawaited(_edit(entry)),
                onPostpone: () => unawaited(_postpone(entry, 7)),
              ),
              const SizedBox(height: Gap.s),
            ],
          ],
        ],
      ],
    );
  }

  // --------------------------------------------------------------- session ---

  Widget _buildSession(BuildContext context, AppStrings strings) {
    final List<ReviewEntry> queue = _queue!;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);

    if (_index >= queue.length) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 36,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: Gap.l),
              Text(
                strings.reviewDoneTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.s),
              Text(
                strings.reviewDoneBody(_graded, _known),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Gap.xl),
              FilledButton(
                onPressed: _leaveSession,
                child: Text(strings.reviewDone),
              ),
            ],
          ),
        ),
      );
    }

    final ReviewEntry entry = queue[_index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xs, Gap.xl, Gap.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                strings.reviewProgress(_index + 1, queue.length),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => unawaited(_skip(entry)),
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: Text(strings.reviewSkip),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          ClipRRect(
            borderRadius: shape.allPill,
            child: LinearProgressIndicator(
              value: queue.isEmpty ? 0.0 : (_index + 1) / queue.length,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: Gap.l),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(Gap.xl),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: shape.allXl,
                border: Border.all(
                  color: scheme.outlineVariant.withFraction(0.5),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        DocumentCover(
                          document: entry.document,
                          width: 30,
                          height: 40,
                        ),
                        const SizedBox(width: Gap.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.document.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                strings.pageOf(
                                  entry.note.page,
                                  entry.document.pageCount,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: strings.noteEditAction,
                          onPressed: () => unawaited(_edit(entry)),
                          icon: Icon(
                            Icons.edit_note_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.l),
                    SelectableText(
                      entry.note.note ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.l),
          Row(
            children: <Widget>[
              Expanded(
                child: _GradeButton(
                  label: strings.reviewForgot,
                  icon: Icons.refresh_rounded,
                  color: scheme.errorContainer,
                  foreground: scheme.onErrorContainer,
                  onPressed: () => unawaited(
                    _grade(entry, ReviewGrade.forgot),
                  ),
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: _GradeButton(
                  label: strings.reviewPartial,
                  icon: Icons.trending_flat_rounded,
                  color: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer,
                  onPressed: () => unawaited(
                    _grade(entry, ReviewGrade.partial),
                  ),
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: _GradeButton(
                  label: strings.reviewGood,
                  icon: Icons.check_rounded,
                  color: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                  onPressed: () => unawaited(_grade(entry, ReviewGrade.good)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: color,
      borderRadius: WaraqShape.of(context).allLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.m, horizontal: Gap.xs),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 22, color: foreground),
              const SizedBox(height: Gap.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.entry,
    required this.now,
    required this.onTap,
    required this.onEdit,
    required this.onPostpone,
    this.muted = false,
  });

  final ReviewEntry entry;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPostpone;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final int days = daysUntilDue(entry.schedule.dueAt, now);

    return Material(
      color: muted
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainerLow,
      borderRadius: shape.allLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.xs, Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      entry.document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.s),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gap.s,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: muted
                          ? scheme.surfaceContainerHigh
                          : scheme.primaryContainer,
                      borderRadius: shape.allPill,
                    ),
                    child: Text(
                      strings.reviewNextIn(days),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted
                            ? scheme.onSurfaceVariant
                            : scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: strings.noteEditAction,
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: strings.reviewPostpone,
                    onPressed: onPostpone,
                    icon: Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: Gap.s),
                child: Text(
                  entry.note.note ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: Gap.xs),
              Padding(
                padding: const EdgeInsets.only(right: Gap.s),
                child: Text(
                  '${strings.pageOf(entry.note.page, entry.document.pageCount)} · ${formatRelative(entry.note.touchedAt, isArabic: strings.isArabic)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withFraction(0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
