import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../providers/library_providers.dart';

/// Opens the system picker, imports the chosen PDF and reports the outcome.
/// Returns the imported document when the import succeeded.
Future<PdfDocument?> pickAndImportPdf(
  BuildContext context,
  WidgetRef ref,
) async {
  final AppStrings strings = AppStrings.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final ImportBusyNotifier busy = ref.read(importBusyProvider.notifier);

  FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf'],
      withData: false,
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(strings.importFailed)));
    return null;
  }
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final PlatformFile file = result.files.first;
  final String? path = file.path;
  final String title = file.name.replaceAll(
    RegExp(r'\.pdf$', caseSensitive: false),
    '',
  );

  busy.set(true);
  try {
    final PdfDocument document =
        await ref.read(documentsProvider.notifier).importPdf(
              sourcePath: path,
              displayName: title,
            );
    messenger.showSnackBar(
      SnackBar(content: Text(strings.addedToLibrary(document.title))),
    );
    return document;
  } on DocumentException catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('${strings.importFailed} · ${error.message}')),
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(strings.importFailed)));
  } finally {
    busy.set(false);
  }
  return null;
}
