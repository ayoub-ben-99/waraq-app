import 'package:flutter/material.dart' show Color;

/// A label the reader can attach to any note: "فكرة", "اقتباس", "للمراجعة"…
class NoteTag {
  const NoteTag({
    required this.id,
    required this.name,
    this.colorIndex = 0,
  });

  final String id;
  final String name;

  /// Index into the app's tag palette, so tags get stable, distinct colours.
  final int colorIndex;

  NoteTag copyWith({String? name, int? colorIndex}) {
    return NoteTag(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NoteTag &&
        other.id == id &&
        other.name == name &&
        other.colorIndex == colorIndex;
  }

  @override
  int get hashCode => Object.hash(id, name, colorIndex);
}

/// Six hues that stay legible in light and dark themes.
const List<Color> kTagColors = <Color>[
  Color(0xFF6B4EFF),
  Color(0xFF0E9F6E),
  Color(0xFFD97706),
  Color(0xFFE11D48),
  Color(0xFF0284C7),
  Color(0xFF9333EA),
];

/// Colour for [colorIndex], wrapping safely.
Color tagColor(int colorIndex) =>
    kTagColors[colorIndex.abs() % kTagColors.length];
