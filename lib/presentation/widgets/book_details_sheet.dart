import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/document_cover.dart';
import '../../core/widgets/waraq_sheet.dart';
import '../../domain/entities/pdf_document.dart';
import '../providers/library_providers.dart';
import 'delete_document.dart';

/// Rename a book, move it to a shelf category, or delete it.
Future<void> showBookDetails(
  BuildContext context,
  WidgetRef ref,
  PdfDocument document,
) {
  return showWaraqSheet<void>(
    context: context,
    builder: (BuildContext context) =>
        _BookDetailsSheet(document: document),
  );
}

class _BookDetailsSheet extends ConsumerStatefulWidget {
  const _BookDetailsSheet({required this.document});

  final PdfDocument document;

  @override
  ConsumerState<_BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends ConsumerState<_BookDetailsSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.document.title);
  late final TextEditingController _category =
      TextEditingController(text: widget.document.category ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final AppStrings strings = AppStrings.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(documentsProvider.notifier).updateMetadata(
          widget.document,
          title: _title.text,
          category: _category.text,
          clearCategory: _category.text.trim().isEmpty,
        );
    if (!mounted) {
      return;
    }
    navigator.pop();
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.bookSaved)));
  }

  /// Closes the sheet first, then asks for confirmation on the page below it.
  Future<void> _delete() async {
    final NavigatorState navigator = Navigator.of(context);
    final BuildContext host = navigator.context;
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!host.mounted) {
      return;
    }
    await confirmDeleteDocument(host, ref, widget.document);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final WaraqShape shape = WaraqShape.of(context);
    final List<String> categories = ref.watch(categoriesProvider);

    return WaraqSheet(
      title: widget.document.title,
      subtitle: strings.pagesLabel(widget.document.pageCount),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              DocumentCover(document: widget.document, width: 44, height: 58),
              const SizedBox(width: Gap.l),
              Expanded(
                child: TextField(
                  controller: _title,
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(
                    labelText: strings.bookTitleLabel,
                    filled: true,
                    fillColor: scheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: shape.allMd,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          TextField(
            controller: _category,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: strings.bookCategoryLabel,
              hintText: strings.bookCategoryHint,
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: shape.allMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (categories.isNotEmpty) ...<Widget>[
            const SizedBox(height: Gap.s),
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.xs,
              children: <Widget>[
                for (final String category in categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: _category.text.trim() == category,
                    onSelected: (bool selected) {
                      setState(() {
                        _category.text = selected ? category : '';
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: Gap.l),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(strings.delete),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _saving ? null : () => unawaited(_save()),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(strings.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
