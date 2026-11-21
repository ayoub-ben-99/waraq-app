// Formatting helpers kept free of dependencies so they can be unit tested.

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

final RegExp _trailingZeros = RegExp(r'\.0+$');

/// `1536` → `1.5 KB`, `1048576` → `1 MB`.
String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const List<String> units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final String digits = unit == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(value >= 100 ? 0 : 1).replaceFirst(_trailingZeros, '');
  return '$digits ${units[unit]}';
}

/// `2026-03-09T…` → `9 Mar` (or `9 Mar 2025` when the year differs).
String formatShortDate(DateTime date, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final String day = date.day.toString();
  final String month = _months[(date.month - 1).clamp(0, 11)];
  if (date.year == reference.year) {
    return '$day $month';
  }
  return '$day $month ${date.year}';
}

/// Relative wording for "last read" captions.
String formatRelative(DateTime time, {DateTime? now, bool isArabic = false}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration diff = reference.difference(time);

  if (diff.inSeconds < 90) {
    return isArabic ? 'الآن' : 'just now';
  }
  if (diff.inMinutes < 60) {
    final int minutes = diff.inMinutes;
    return isArabic ? 'قبل $minutes د' : '${minutes}m ago';
  }
  if (diff.inHours < 24) {
    final int hours = diff.inHours;
    return isArabic ? 'قبل $hours س' : '${hours}h ago';
  }
  if (diff.inDays == 1) {
    return isArabic ? 'أمس' : 'yesterday';
  }
  if (diff.inDays < 7) {
    final int days = diff.inDays;
    return isArabic ? 'قبل $days أيام' : '${days}d ago';
  }
  return formatShortDate(time, now: reference);
}

/// Greeting bucket for the home header.
enum DayGreeting { morning, afternoon, evening, night }

DayGreeting greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) {
    return DayGreeting.morning;
  }
  if (hour >= 12 && hour < 17) {
    return DayGreeting.afternoon;
  }
  if (hour >= 17 && hour < 22) {
    return DayGreeting.evening;
  }
  return DayGreeting.night;
}

/// Human label for an auto-scroll speed in the 0..1 range.
String formatAutoScrollSpeed(double speed) {
  final double multiplier = 0.5 + speed.clamp(0.0, 1.0) * 2.5;
  return '${multiplier.toStringAsFixed(1)}×';
}

/// Clamp helper used across the reader math.
double clampDouble(double value, double min, double max) {
  if (value.isNaN) {
    return min;
  }
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
