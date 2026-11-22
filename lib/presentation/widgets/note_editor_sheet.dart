import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/tag_chip.dart';
import '../../core/widgets/waraq_sheet.dart';
import '../../domain/entities/note_tag.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';
import '../providers/tag_providers.dart';

/// Opens the editor for the note attached to [page]; resolves to the saved
/// bookmark, or `null` when the reader dismissed the sheet.
Future<Bookmark?> showNoteEditor(
  BuildContext context, {
  required String documentId,
  required int page,
  required int pageCount,
  String? initialNote,
  List<String> initialTags = const <String>[],
}) {
  return showWaraqSheet<Bookmark>(
    context: context,
    builder: (BuildContext context) => NoteEditorSheet(
      documentId: documentId,
      page: page,
      pageCount: pageCount,
      initialNote: initialNote,
      initialTags: initialTags,
    ),
  );
}

class _TagPicker extends ConsumerWidget {
  const _TagPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final AppStrings strings = AppStrings.of(context);
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.tagNewTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: strings.tagNameHint),
          onSubmitted: (String value) =>
              Navigator.of(context).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(strings.tagCreate),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }
    final NoteTag tag = await ref.read(tagsProvider.notifier).create(name);
    onChanged(<String>{...selected, tag.id});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final List<NoteTag> tags = ref.watch(tagsProvider).valueOrNull ??
        const <NoteTag>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          strings.noteTagsLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Gap.xs),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.xs,
          children: <Widget>[
            for (final NoteTag tag in tags)
              TagFilterChip(
                tag: tag,
                selected: selected.contains(tag.id),
                onSelected: (bool isSelected) {
                  final Set<String> next = <String>{...selected};
                  if (isSelected) {
                    next.add(tag.id);
                  } else {
                    next.remove(tag.id);
                  }
                  onChanged(next);
                },
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16),
              label: Text(strings.tagNew),
              onPressed: () => unawaited(_create(context, ref)),
            ),
          ],
        ),
      ],
    );
  }
}

class NoteEditorSheet extends ConsumerStatefulWidget {
  const NoteEditorSheet({
    required this.documentId,
    required this.page,
    required this.pageCount,
    this.initialNote,
    this.initialTags = const <String>[],
    super.key,
  });

  final String documentId;
  final int page;
  final int pageCount;
  final String? initialNote;
  final List<String> initialTags;

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialNote ?? '',
  );
  bool _saving = false;
  late final Set<String> _tags = <String>{
    for (final String id in widget.initialTags) id,
  };

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => _text.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (_saving || !_canSave) {
      return;
    }
    setState(() => _saving = true);
    final NavigatorState navigator = Navigator.of(context);
    final BookmarksNotifier bookmarks = ref.read(bookmarksProvider.notifier);
    final Bookmark? saved = await bookmarks.setNote(
      documentId: widget.documentId,
      page: widget.page,
      note: _text.text,
    );
    if (saved != null) {
      await bookmarks.setTags(saved.id, _tags.toList(growable: false));
    }
    if (!mounted) {
      return;
    }
    navigator.pop(saved);
  }

  Future<void> _clear() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final NavigatorState navigator = Navigator.of(context);
    await ref.read(bookmarksProvider.notifier).setNote(
          documentId: widget.documentId,
          page: widget.page,
          note: '',
        );
    if (!mounted) {
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final bool editing = (widget.initialNote ?? '').trim().isNotEmpty;

    return WaraqSheet(
      title: editing ? strings.noteEditTitle : strings.noteAddTitle,
      subtitle: strings.pageOf(widget.page, widget.pageCount),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: strings.noteHint,
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.all(Gap.l),
              border: OutlineInputBorder(
                borderRadius: shape.allMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          _TagPicker(
            selected: _tags,
            onChanged: (Set<String> next) => setState(() {
              _tags
                ..clear()
                ..addAll(next);
            }),
          ),
          const SizedBox(height: Gap.m),
          Row(
            children: <Widget>[
              if (editing) ...<Widget>[
                TextButton.icon(
                  onPressed: _saving ? null : () => unawaited(_clear()),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(strings.noteDelete),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              FilledButton.icon(
                onPressed: _saving || !_canSave
                    ? null
                    : () => unawaited(_save()),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(strings.noteSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
