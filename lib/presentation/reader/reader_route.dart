import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../domain/entities/pdf_document.dart';
import '../providers/library_providers.dart';
import 'reader_screen.dart';

/// Fade-and-settle transition into the reader, so opening a book feels like the
/// page is coming forward rather than a hard cut.
class ReaderRoute extends PageRouteBuilder<void> {
  ReaderRoute({required PdfDocument document, int? startPage})
      : super(
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.base,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              ReaderScreen(document: document, startPage: startPage),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Motion.emphasized,
              reverseCurve: Motion.accelerate,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Opens the reader and refreshes the saved-position cache afterwards.
Future<void> openReader(
  BuildContext context,
  WidgetRef ref,
  PdfDocument document, {
  int? startPage,
}) async {
  await Navigator.of(context).push<void>(
    ReaderRoute(document: document, startPage: startPage),
  );
  try {
    await ref.read(positionsProvider.notifier).refresh();
  } catch (_) {
    // The provider may already be gone if the host screen was disposed.
  }
}
