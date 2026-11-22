import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/reveal.dart';
import '../../core/widgets/round_icon_button.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reading_position.dart';
import '../providers/library_providers.dart';
import '../reader/reader_route.dart';
import '../widgets/book_details_sheet.dart';
import '../widgets/document_row.dart';
import '../widgets/import_document.dart';

enum _SortMode { recent, title }

/// Searchable list of every imported document.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _search = TextEditingController();
  _SortMode _sort = _SortMode.recent;
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PdfDocument> _filter(List<PdfDocument> documents) {
    final String query = _query.trim().toLowerCase();
    final List<PdfDocument> result = <PdfDocument>[
      for (final PdfDocument document in documents)
        if (_category == null || document.category == _category)
          if (query.isEmpty || document.title.toLowerCase().contains(query))
            document,
    ];
    if (_sort == _SortMode.title) {
      result.sort(
        (PdfDocument a, PdfDocument b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else {
      result.sort((PdfDocument a, PdfDocument b) {
        final DateTime aTime = a.lastOpenedAt ?? a.addedAt;
        final DateTime bTime = b.lastOpenedAt ?? b.addedAt;
        return bTime.compareTo(aTime);
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AsyncValue<List<PdfDocument>> documentsAsync =
        ref.watch(documentsProvider);
    final List<PdfDocument> documents =
        documentsAsync.valueOrNull ?? const <PdfDocument>[];
    final Map<String, ReadingPosition> positions =
        ref.watch(positionsProvider).valueOrNull ??
            const <String, ReadingPosition>{};
    final bool importing = ref.watch(importBusyProvider);
    final List<String> categories = ref.watch(categoriesProvider);
    final List<PdfDocument> visible = _filter(documents);

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
                  horizontal - Gap.xs,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        strings.libraryTitle,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                    RoundIconButton(
                      icon: importing
                          ? Icons.hourglass_top_rounded
                          : Icons.add_rounded,
                      tooltip: strings.importPdf,
                      emphasized: true,
                      onPressed: importing
                          ? null
                          : () => unawaited(pickAndImportPdf(context, ref)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  Gap.l,
                  horizontal,
                  Gap.s,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (String value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: strings.searchHint,
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
                      borderRadius: BorderRadius.circular(Radii.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (categories.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    Gap.s,
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
                            label: Text(strings.allCategories),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                        ),
                        for (final String category in categories)
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(end: Gap.s),
                            child: ChoiceChip(
                              avatar: const Icon(Icons.layers_outlined, size: 16),
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (bool selected) => setState(
                                () => _category = selected ? category : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Row(
                  children: <Widget>[
                    _SortChip(
                      label: strings.sortRecent,
                      selected: _sort == _SortMode.recent,
                      onTap: () => setState(() => _sort = _SortMode.recent),
                    ),
                    const SizedBox(width: Gap.s),
                    _SortChip(
                      label: strings.sortTitle,
                      selected: _sort == _SortMode.title,
                      onTap: () => setState(() => _sort = _SortMode.title),
                    ),
                    const Spacer(),
                    Text(
                      strings.documentsCount(documents.length),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: documents.isEmpty
                              ? EmptyState(
                                  icon: Icons.auto_stories_outlined,
                                  title: strings.emptyLibraryTitle,
                                  message: strings.emptyLibraryBody,
                                  action: FilledButton.icon(
                                    onPressed: importing
                                        ? null
                                        : () => unawaited(
                                              pickAndImportPdf(context, ref),
                                            ),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: Text(strings.importPdf),
                                  ),
                                )
                              : EmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: strings.noResults(_query),
                                  compact: true,
                                ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          Gap.s,
                          horizontal,
                          Gap.xxxl * 2,
                        ),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: visible.length,
                        itemBuilder: (BuildContext context, int index) {
                          final PdfDocument document = visible[index];
                          return Reveal(
                            index: index,
                            offset: 8,
                            child: DocumentRow(
                              document: document,
                              position: positions[document.id],
                              onTap: () => unawaited(
                                openReader(context, ref, document),
                              ),
                              onLongPress: () => unawaited(
                                showBookDetails(context, ref, document),
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
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
