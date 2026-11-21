/// How pages move under the eye.
enum ScrollMode {
  /// One continuous column. Default.
  vertical,

  /// One page at a time, swiped sideways.
  horizontal,
}

/// Colour wash applied to the rendered page.
enum PageFilter { none, sepia, night }

/// Reading preferences that persist between sessions.
class ReaderSettings {
  const ReaderSettings({
    this.scrollMode = ScrollMode.vertical,
    this.pageFilter = PageFilter.none,
    this.autoScrollSpeed = 0.32,
    this.pageBrightness = 0.0,
  });

  final ScrollMode scrollMode;
  final PageFilter pageFilter;

  /// 0 = slowest, 1 = fastest. Mapped to pixels per second by the controller.
  final double autoScrollSpeed;

  /// Extra dimming applied to the page canvas, 0 (off) to 0.75.
  final double pageBrightness;

  ReaderSettings copyWith({
    ScrollMode? scrollMode,
    PageFilter? pageFilter,
    double? autoScrollSpeed,
    double? pageBrightness,
  }) {
    return ReaderSettings(
      scrollMode: scrollMode ?? this.scrollMode,
      pageFilter: pageFilter ?? this.pageFilter,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      pageBrightness: pageBrightness ?? this.pageBrightness,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderSettings &&
        other.scrollMode == scrollMode &&
        other.pageFilter == pageFilter &&
        (other.autoScrollSpeed - autoScrollSpeed).abs() < 0.0001 &&
        (other.pageBrightness - pageBrightness).abs() < 0.0001;
  }

  @override
  int get hashCode => Object.hash(
        scrollMode,
        pageFilter,
        autoScrollSpeed.toStringAsFixed(2),
        pageBrightness.toStringAsFixed(2),
      );
}
