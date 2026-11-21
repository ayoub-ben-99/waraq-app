import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/pdf_document.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The first page of a document, used everywhere as its cover. Falls back to a
/// tonal placeholder when the thumbnail is still being rendered.
class DocumentCover extends StatelessWidget {
  const DocumentCover({
    required this.document,
    this.width = Sizes.thumbnailWidth,
    this.height = Sizes.thumbnailHeight,
    this.radius = Sizes.thumbnailRadius,
    super.key,
  });

  final PdfDocument document;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? path = document.thumbnailPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border.all(color: scheme.outlineVariant.withFraction(0.5)),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: path == null || path.isEmpty
              ? _Placeholder(scheme: scheme)
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: (width * 3).round(),
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) =>
                      _Placeholder(scheme: scheme),
                ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.picture_as_pdf_rounded,
        size: 20,
        color: scheme.onSurfaceVariant.withFraction(0.7),
      ),
    );
  }
}
