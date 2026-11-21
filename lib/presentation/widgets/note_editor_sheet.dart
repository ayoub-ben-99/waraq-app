import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/waraq_sheet.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';

/// Opens the editor for the note attached to [page]; resolves to the saved
/// bookmark, or `null` when the reader dismissed the sheet.
Future<Bookmark?> showNoteEditor(
  BuildContext context, {
  required String documentId,
  required int page,
  required int pageCount,
  String? initialNote,
}) {
  return showWaraqSheet<Bookmark>(
    context: context,
    builder: (BuildContext context) => NoteEditorSheet(
      documentId: documentId,
      page: page,
      pageCount: pageCount,
      initialNote: initialNote,
    ),
  );
}

class NoteEditorSheet extends ConsumerStatefulWidget {
  const NoteEditorSheet({
    required this.documentId,
    required this.page,
    required this.pageCount,
    this.initialNote,
    super.key,
  });

  final String documentId;
  final int page;
  final int pageCount;
  final String? initialNote;

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialNote ?? '',
  );
  bool _saving = false;

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
    final Bookmark? saved = await ref.read(bookmarksProvider.notifier).setNote(
          documentId: widget.documentId,
          page: widget.page,
          note: _text.text,
        );
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
          const SizedBox(height: Gap.l),
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
