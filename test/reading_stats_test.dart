import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/data/models/reading_session_dto.dart';
import 'package:waraq/domain/entities/reading_session.dart';
import 'package:waraq/domain/reading_stats.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 22, 20);

  ReadingSession session({
    required DateTime start,
    int minutes = 30,
    int pages = 5,
    String id = 's',
  }) {
    return ReadingSession(
      id: id,
      documentId: 'doc',
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      pages: pages,
    );
  }

  group('reading stats', () {
    test('no sessions gives an empty summary', () {
      final ReadingStats stats =
          computeReadingStats(const <ReadingSession>[], now);
      expect(stats.sessionCount, 0);
      expect(stats.streakDays, 0);
      expect(stats.dailyMinutes.length, 7);
    });

    test('today and this week add up', () {
      final ReadingStats stats = computeReadingStats(<ReadingSession>[
        session(start: DateTime(2026, 11, 22, 9), minutes: 25),
        session(start: DateTime(2026, 11, 22, 18), minutes: 20, id: 's2'),
        session(start: DateTime(2026, 11, 20, 20), minutes: 45, id: 's3'),
      ], now);

      expect(stats.todayMinutes, 45);
      expect(stats.weekMinutes, 90);
      expect(stats.totalMinutes, 90);
      expect(stats.totalPages, 15);
    });

    test('the streak counts consecutive days ending today', () {
      final ReadingStats stats = computeReadingStats(<ReadingSession>[
        session(start: DateTime(2026, 11, 22, 8)),
        session(start: DateTime(2026, 11, 21, 8), id: 's2'),
        session(start: DateTime(2026, 11, 20, 8), id: 's3'),
        // A gap on the 19th breaks the chain.
        session(start: DateTime(2026, 11, 18, 8), id: 's4'),
      ], now);

      expect(stats.streakDays, 3);
    });

    test('a streak survives a day that has not been read yet', () {
      final ReadingStats stats = computeReadingStats(<ReadingSession>[
        session(start: DateTime(2026, 11, 21, 8)),
        session(start: DateTime(2026, 11, 20, 8), id: 's2'),
      ], now);

      expect(stats.streakDays, 2);
      expect(stats.todayMinutes, 0);
    });

    test('the chart has seven buckets ending today', () {
      final ReadingStats stats = computeReadingStats(<ReadingSession>[
        session(start: DateTime(2026, 11, 22, 8), minutes: 60),
        session(start: DateTime(2026, 11, 16, 8), minutes: 10, id: 'old'),
      ], now);

      expect(stats.dailyLabels.last, 22);
      expect(stats.dailyLabels.first, 16);
      expect(stats.dailyMinutes.last, 60);
      expect(stats.dailyMinutes.first, 10);
    });

    test('an absurdly long session is clamped', () {
      final ReadingStats stats = computeReadingStats(<ReadingSession>[
        session(start: DateTime(2026, 11, 22, 0), minutes: 24 * 60),
      ], now);
      expect(stats.totalMinutes, lessThanOrEqualTo(360));
    });

    test('pace is pages per hour', () {
      final ReadingStats stats = computeReadingStats(<ReadingSession>[
        session(start: DateTime(2026, 11, 22, 9), minutes: 60, pages: 30),
      ], now);
      expect(stats.pagesPerHour.round(), 30);
    });

    test('a session round-trips through storage', () {
      final ReadingSession original = session(start: DateTime(2026, 11, 22, 9));
      final ReadingSession restored = ReadingSessionDto.fromMap(
        ReadingSessionDto.toMap(original),
      );
      expect(restored, original);
      expect(restored.minutes, 30);
      expect(restored.day, DateTime(2026, 11, 22));
    });
  });
}
