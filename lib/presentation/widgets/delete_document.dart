import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../domain/entities/pdf_document.dart';
import '../providers/library_providers.dart';

/// Confirms, then removes a document and everything remembered about it.
Future<void> confirmDeleteDocument(
  BuildContext context,
  WidgetRef ref,
  PdfDocument document,
) async {
  final AppStrings strings = AppStrings.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(strings.deleteDocumentTitle),
      content: Text(strings.deleteDocumentBody),
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

  try {
    await ref.read(documentsProvider.notifier).delete(document);
    messenger.showSnackBar(SnackBar(content: Text(strings.deleted)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(strings.fileMissing)));
  }
}
