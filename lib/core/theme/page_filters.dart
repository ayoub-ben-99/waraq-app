import 'dart:ui' show ColorFilter;

import '../../domain/entities/reader_settings.dart';

/// Colour washes applied to the rendered PDF canvas (never to the chrome, so
/// labels and controls keep their contrast).
abstract final class PageFilters {
  static const List<double> sepiaMatrix = <double>[
    0.393, 0.769, 0.189, 0.0, 0.0, //
    0.349, 0.686, 0.168, 0.0, 0.0, //
    0.272, 0.534, 0.131, 0.0, 0.0, //
    0.0, 0.0, 0.0, 1.0, 0.0, //
  ];

  static const List<double> nightMatrix = <double>[
    -1.0, 0.0, 0.0, 0.0, 255.0, //
    0.0, -1.0, 0.0, 0.0, 255.0, //
    0.0, 0.0, -1.0, 0.0, 255.0, //
    0.0, 0.0, 0.0, 1.0, 0.0, //
  ];

  static ColorFilter? of(PageFilter filter) {
    return switch (filter) {
      PageFilter.none => null,
      PageFilter.sepia => const ColorFilter.matrix(sepiaMatrix),
      PageFilter.night => const ColorFilter.matrix(nightMatrix),
    };
  }

  /// The paper colour a page should sit on so corners never flash white.
  static bool isInverted(PageFilter filter) => filter == PageFilter.night;
}
