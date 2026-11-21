import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/core/utils/formatters.dart';

void main() {
  group('formatBytes', () {
    test('formats the common magnitudes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(-4), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(1024 * 1024), '1 MB');
      expect(formatBytes(1024 * 1024 * 1024 * 3), '3 GB');
    });
  });

  group('formatShortDate', () {
    test('omits the year for the current year', () {
      final DateTime now = DateTime(2026, 11, 21);
      expect(formatShortDate(DateTime(2026, 3, 9), now: now), '9 Mar');
      expect(formatShortDate(DateTime(2025, 12, 1), now: now), '1 Dec 2025');
    });
  });

  group('formatRelative', () {
    final DateTime now = DateTime(2026, 11, 21, 12);

    test('describes recent moments', () {
      expect(formatRelative(now.subtract(const Duration(seconds: 5)), now: now), 'just now');
      expect(formatRelative(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
      expect(formatRelative(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(formatRelative(now.subtract(const Duration(days: 1)), now: now), 'yesterday');
      expect(formatRelative(now.subtract(const Duration(days: 4)), now: now), '4d ago');
      expect(
        formatRelative(now.subtract(const Duration(days: 40)), now: now),
        '12 Oct',
      );
    });

    test('speaks Arabic when asked', () {
      expect(
        formatRelative(now.subtract(const Duration(minutes: 5)), now: now, isArabic: true),
        'قبل 5 د',
      );
      expect(
        formatRelative(now.subtract(const Duration(days: 1)), now: now, isArabic: true),
        'أمس',
      );
    });
  });

  group('greetingForHour', () {
    test('maps the day into four buckets', () {
      expect(greetingForHour(7), DayGreeting.morning);
      expect(greetingForHour(13), DayGreeting.afternoon);
      expect(greetingForHour(19), DayGreeting.evening);
      expect(greetingForHour(23), DayGreeting.night);
      expect(greetingForHour(3), DayGreeting.night);
    });
  });

  group('formatAutoScrollSpeed', () {
    test('maps the normalised slider onto a multiplier', () {
      expect(formatAutoScrollSpeed(0), '0.5×');
      expect(formatAutoScrollSpeed(0.5), '1.8×');
      expect(formatAutoScrollSpeed(1), '3.0×');
      // Out of range values are clamped.
      expect(formatAutoScrollSpeed(-1), '0.5×');
      expect(formatAutoScrollSpeed(4), '3.0×');
    });
  });

  group('clampDouble', () {
    test('clamps and survives NaN', () {
      expect(clampDouble(5, 0, 1), 1);
      expect(clampDouble(-5, 0, 1), 0);
      expect(clampDouble(0.4, 0, 1), 0.4);
      expect(clampDouble(double.nan, 0, 1), 0);
    });
  });
}
