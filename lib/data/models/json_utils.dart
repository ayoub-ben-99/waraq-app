/// Defensive readers used by every DTO, so a corrupted preference value can
/// never crash the app.
library;

double readDouble(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int readInt(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool readBool(Object? value, bool fallback) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

String readString(Object? value, String fallback) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

DateTime readDate(Object? value, DateTime fallback) {
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return fallback;
}

T readEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final T candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  return fallback;
}

Map<String, Object?> readMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>(
      (Object? key, Object? item) => MapEntry<String, Object?>('$key', item),
    );
  }
  return <String, Object?>{};
}
