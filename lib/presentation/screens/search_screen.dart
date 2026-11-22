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
import '../../core/widgets/section_header.dart';
import '../../core/widgets/tag_chip.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/note_tag.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/library_search.dart';
import '../providers/bookmark_providers.dart';
import '../providers/library_providers.dart';
import '../providers/tag_providers.dart';
import '../reader/reader_route.dart';

/// One field over everything: books, notes and tags.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _field = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _searchFor(String value) {
    _field
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);

    final List<PdfDocument> documents =
        ref.watch(documentsProvider).valueOrNull ?? const <PdfDocument>[];
    final List<Bookmark> notes = ref.watch(notesProvider);
    final List<NoteTag> tags =
        ref.watch(tagsProvider).valueOrNull ?? const <NoteTag>[];
    final Map<String, PdfDocument> documentsById = <String, PdfDocument>{
      for (final PdfDocument document in documents) document.id: document,
    };
    final Map<String, NoteTag> tagsById = <String, NoteTag>{
      for (final NoteTag tag in tags) tag.id: tag,
    };
    final SearchResults results = searchLibrary(
      query: _query,
      documents: documents,
      notes: notes,
      tags: tags,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (String value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: strings.searchEverythingHint,
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            prefixIcon: Icon(Icons.search_rounded, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _field.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Gap.l,
              vertical: Gap.m,
            ),
            border: OutlineInputBorder(
              borderRadius: shape.allPill,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: const <Widget>[SizedBox(width: Gap.l)],
      ),
      body: SafeArea(
        top: false,
        child: _query.trim().isEmpty
            ? _Suggestions(tags: tags, onPick: _searchFor)
            : results.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Gap.xl),
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: strings.searchNoResultsTitle,
                        message: strings.searchNoResultsBody(_query.trim()),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.xl,
                      Gap.s,
                      Gap.xl,
                      Gap.xxl,
                    ),
                    children: <Widget>[
                      if (results.books.isNotEmpty) ...<Widget>[
                        SectionHeader(
                          title: strings.searchBooks(results.books.length),
                        ),
                        for (final PdfDocument document in results.books)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Gap.xs),
                            child: _BookHit(
                              document: document,
                              onTap: () => unawaited(
                                openReader(context, ref, document),
                              ),
                            ),
                          ),
                        const SizedBox(height: Gap.l),
                      ],
                      if (results.notes.isNotEmpty) ...<Widget>[
                        SectionHeader(
                          title: strings.searchNotes(results.notes.length),
                        ),
                        for (final Bookmark note in results.notes)
                          if (documentsById[note.documentId]
                              case final PdfDocument document)
                            Padding(
                              padding: const EdgeInsets.only(bottom: Gap.s),
                              child: _NoteHit(
                                note: note,
                                document: document,
                                tags: <NoteTag>[
                                  for (final String id in note.tagIds)
                                    if (tagsById[id] case final NoteTag tag)
                                      tag,
                                ],
                                onTap: () => unawaited(
                                  openReader(
                                    context,
                                    ref,
                                    document,
                                    startPage: note.page,
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: Gap.l),
                      ],
                      if (results.tags.isNotEmpty) ...<Widget>[
                        SectionHeader(title: strings.searchTags),
                        Wrap(
                          spacing: Gap.s,
                          runSpacing: Gap.xs,
                          children: <Widget>[
                            for (final NoteTag tag in results.tags)
                              TagFilterChip(
                                tag: tag,
                                selected: false,
                                onSelected: (_) => _searchFor(tag.name),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.tags, required this.onPick});

  final List<NoteTag> tags;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.l, Gap.xl, Gap.xxl),
      children: <Widget>[
        Text(
          strings.searchIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: Gap.l),
          Text(
            strings.searchTags,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gap.s),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.xs,
            children: <Widget>[
              for (final NoteTag tag in tags)
                TagFilterChip(
                  tag: tag,
                  selected: false,
                  onSelected: (_) => onPick(tag.name),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BookHit extends StatelessWidget {
  const _BookHit({required this.document, required this.onTap});

  final PdfDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: WaraqShape.of(context).allLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Row(
            children: <Widget>[
              DocumentCover(document: document, width: 34, height: 46),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Text(
                      <String>[
                        if (document.category != null) document.category!,
                        strings.pagesLabel(document.pageCount),
                        formatBytes(document.sizeBytes),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withFraction(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteHit extends StatelessWidget {
  const _NoteHit({
    required this.note,
    required this.document,
    required this.tags,
    required this.onTap,
  });

  final Bookmark note;
  final PdfDocument document;
  final List<NoteTag> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: WaraqShape.of(context).allLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    strings.pageOf(note.page, document.pageCount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.xxs),
              Text(
                note.note ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: Gap.s),
                Wrap(
                  spacing: Gap.xs,
                  runSpacing: Gap.xxs,
                  children: <Widget>[
                    for (final NoteTag tag in tags) TagPill(tag: tag),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
