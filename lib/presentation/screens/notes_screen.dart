import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/document_cover.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/tag_chip.dart';
import '../../core/widgets/reveal.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/note_tag.dart';
import '../../domain/entities/pdf_document.dart';
import '../providers/bookmark_providers.dart';
import '../providers/library_providers.dart';
import '../providers/review_providers.dart';
import '../providers/tag_providers.dart';
import 'review_screen.dart';
import '../reader/reader_route.dart';
import '../widgets/note_editor_sheet.dart';

/// Every written note, searchable, newest first, with a jump back to its page.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _tagFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({Bookmark note, PdfDocument document})> _visible(
    List<Bookmark> notes,
    Map<String, PdfDocument> byId,
  ) {
    final String query = _query.trim().toLowerCase();
    return <({Bookmark note, PdfDocument document})>[
      for (final Bookmark note in notes)
        if (byId[note.documentId] case final PdfDocument document)
          if (_tagFilter == null || note.tagIds.contains(_tagFilter))
            if (query.isEmpty ||
                (note.note ?? '').toLowerCase().contains(query) ||
                document.title.toLowerCase().contains(query))
              (note: note, document: document),
    ];
  }

  Future<void> _edit(
    BuildContext context,
    Bookmark note,
    PdfDocument document,
  ) async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Bookmark? saved = await showNoteEditor(
      context,
      documentId: note.documentId,
      page: note.page,
      pageCount: document.pageCount,
      initialNote: note.note,
      initialTags: note.tagIds,
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final List<Bookmark> notes = ref.watch(notesProvider);
    final int due = ref.watch(reviewDueCountProvider);
    final Map<String, NoteTag> tagsById = ref.watch(tagsByIdProvider);
    final List<NoteTag> tags = <NoteTag>[
      for (final NoteTag tag in tagsById.values)
        if (_countFor(notes, tag.id) > 0) tag,
    ]..sort((NoteTag a, NoteTag b) => a.name.compareTo(b.name));
    final List<PdfDocument> documents =
        ref.watch(documentsProvider).valueOrNull ?? const <PdfDocument>[];
    final Map<String, PdfDocument> byId = <String, PdfDocument>{
      for (final PdfDocument document in documents) document.id: document,
    };
    final List<({Bookmark note, PdfDocument document})> visible =
        _visible(notes, byId);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double horizontal = math.max(
            Gap.xl,
            (constraints.maxWidth - Sizes.maxContentWidth) / 2,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Gap.m,
                  horizontal,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        strings.notesTitle,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                    if (notes.isNotEmpty)
                      IconButton(
                        tooltip: strings.reviewTitle,
                        onPressed: () => unawaited(
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const ReviewScreen(),
                            ),
                          ),
                        ),
                        icon: Badge(
                          isLabelVisible: due > 0,
                          label: Text('$due'),
                          child: const Icon(Icons.event_repeat_rounded),
                        ),
                      ),
                    if (notes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.m,
                          vertical: Gap.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: WaraqShape.of(context).allPill,
                        ),
                        child: Text(
                          '${notes.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Gap.l,
                  horizontal,
                  0,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (String value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: strings.notesSearchHint,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Gap.l,
                      vertical: Gap.m,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: WaraqShape.of(context).allPill,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (tags.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    Gap.m,
                    horizontal,
                    0,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: Gap.s),
                          child: ChoiceChip(
                            label: Text(strings.notesAllTags),
                            selected: _tagFilter == null,
                            onSelected: (_) =>
                                setState(() => _tagFilter = null),
                          ),
                        ),
                        for (final NoteTag tag in tags)
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(end: Gap.s),
                            child: TagFilterChip(
                              tag: tag,
                              count: _countFor(notes, tag.id),
                              selected: _tagFilter == tag.id,
                              onSelected: (bool selected) => setState(
                                () => _tagFilter = selected ? tag.id : null,
                              ),
                              onLongPress: () =>
                                  unawaited(_manageTag(context, tag)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: Gap.l),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontal,
                            vertical: Gap.xl,
                          ),
                          child: EmptyState(
                            icon: Icons.sticky_note_2_outlined,
                            title: notes.isEmpty
                                ? strings.notesEmptyTitle
                                : strings.notesNoMatchTitle,
                            message: notes.isEmpty
                                ? strings.notesEmptyBody
                                : strings.notesNoMatchBody,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          Gap.xs,
                          horizontal,
                          Gap.xxl,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Gap.s),
                        itemBuilder: (BuildContext context, int index) {
                          final ({Bookmark note, PdfDocument document}) item =
                              visible[index];
                          return Reveal(
                            index: index,
                            child: _NoteTile(
                              note: item.note,
                              document: item.document,
                              tags: <NoteTag>[
                                for (final String id in item.note.tagIds)
                                  if (tagsById[id] case final NoteTag tag) tag,
                              ],
                              onTap: () => unawaited(
                                openReader(
                                  context,
                                  ref,
                                  item.document,
                                  startPage: item.note.page,
                                ),
                              ),
                              onEdit: () => unawaited(
                                _edit(context, item.note, item.document),
                              ),
                              onDelete: () => unawaited(
                                _confirmDelete(context, item.note),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _countFor(List<Bookmark> notes, String tagId) {
    return notes
        .where((Bookmark note) => note.tagIds.contains(tagId))
        .length;
  }

  /// Long-press on a tag chip: rename or delete the tag everywhere.
  Future<void> _manageTag(BuildContext context, NoteTag tag) async {
    final AppStrings strings = AppStrings.of(context);
    final TextEditingController controller =
        TextEditingController(text: tag.name);
    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.tagManageTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: strings.tagNameHint,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: TagDot(colorIndex: tag.colorIndex),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: Text(strings.delete),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    final String name = controller.text.trim();
    controller.dispose();
    if (action == 'save' && name.isNotEmpty && name != tag.name) {
      await ref.read(tagsProvider.notifier).rename(tag, name);
    } else if (action == 'delete') {
      await ref.read(tagsProvider.notifier).delete(tag);
      if (mounted && _tagFilter == tag.id) {
        setState(() => _tagFilter = null);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Bookmark note) async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.noteDeleteTitle),
        content: Text(strings.noteDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(bookmarksProvider.notifier).clearNote(note);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.noteDeleted)));
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.document,
    required this.tags,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Bookmark note;
  final PdfDocument document;
  final List<NoteTag> tags;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);

    return Material(
      color: scheme.surfaceContainerLow,
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
                  DocumentCover(document: document, width: 26, height: 34),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    strings.pageOf(note.page, document.pageCount),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
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
                    tooltip: strings.delete,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              Padding(
                padding: const EdgeInsets.only(right: Gap.s),
                child: Text(
                  note.note ?? '',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
              if (tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.s),
                Padding(
                  padding: const EdgeInsets.only(right: Gap.s),
                  child: Wrap(
                    spacing: Gap.xs,
                    runSpacing: Gap.xxs,
                    children: <Widget>[
                      for (final NoteTag tag in tags) TagPill(tag: tag),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.s),
              Padding(
                padding: const EdgeInsets.only(right: Gap.s),
                child: Text(
                  formatRelative(note.touchedAt, isArabic: strings.isArabic),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withFraction(0.8),
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
