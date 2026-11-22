import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/waraq_sheet.dart';
import '../../../domain/entities/bookmark.dart';
import '../../../domain/entities/pdf_document.dart';
import '../../providers/bookmark_providers.dart';
import '../../widgets/note_editor_sheet.dart';
import '../reader_controller.dart';

/// Every marked page of the open document.
class BookmarksSheet extends ConsumerWidget {
  const BookmarksSheet({
    required this.controller,
    required this.document,
    super.key,
  });

  final ReaderController controller;
  final PdfDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<Bookmark> bookmarks =
        ref.watch(documentBookmarksProvider(document.id));

    return WaraqSheet(
      title: strings.readerBookmarks,
      subtitle: strings.pageOf(controller.currentPage, controller.pageCount),
      child: bookmarks.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: strings.bookmarksEmptyTitle,
              message: strings.bookmarksEmptyBody,
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final Bookmark bookmark in bookmarks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: Material(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Radii.md),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          controller.jumpToPage(bookmark.page);
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Gap.l,
                            Gap.s,
                            Gap.s,
                            Gap.s,
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: scheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(Radii.xs),
                                ),
                                child: Text(
                                  '${bookmark.page}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Gap.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      strings.pageOf(
                                        bookmark.page,
                                        controller.pageCount,
                                      ),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    if (bookmark.hasNote) ...<Widget>[
                                      const SizedBox(height: Gap.xxs),
                                      Text(
                                        bookmark.note!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: bookmark.hasNote
                                    ? strings.noteEditAction
                                    : strings.noteAddAction,
                                onPressed: () => showNoteEditor(
                                  context,
                                  documentId: document.id,
                                  page: bookmark.page,
                                  pageCount: controller.pageCount,
                                  initialNote: bookmark.note,
                                  initialTags: bookmark.tagIds,
                                ),
                                icon: Icon(
                                  bookmark.hasNote
                                      ? Icons.edit_note_rounded
                                      : Icons.note_add_outlined,
                                  size: 20,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              IconButton(
                                tooltip: strings.removeBookmarkTooltip,
                                onPressed: () => ref
                                    .read(bookmarksProvider.notifier)
                                    .remove(bookmark),
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: scheme.onSurfaceVariant
                                      .withFraction(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
