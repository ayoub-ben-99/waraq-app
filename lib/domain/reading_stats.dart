import 'entities/reading_session.dart';

/// Aggregates the reading history into the numbers the stats screen shows.
class ReadingStats {
  const ReadingStats({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.totalMinutes,
    required this.totalPages,
    required this.sessionCount,
    required this.streakDays,
    required this.dailyMinutes,
    required this.dailyLabels,
  });

  final int todayMinutes;
  final int weekMinutes;
  final int totalMinutes;
  final int totalPages;
  final int sessionCount;

  /// Consecutive days with at least one session, ending today (or yesterday,
  /// so a streak is not lost before the reader opens the app in the morning).
  final int streakDays;

  /// Minutes per day for the last seven days, oldest first.
  final List<int> dailyMinutes;

  /// Day-of-month labels matching [dailyMinutes].
  final List<int> dailyLabels;

  double get pagesPerHour {
    if (totalMinutes <= 0) {
      return 0;
    }
    return totalPages / (totalMinutes / 60);
  }

  static const ReadingStats empty = ReadingStats(
    todayMinutes: 0,
    weekMinutes: 0,
    totalMinutes: 0,
    totalPages: 0,
    sessionCount: 0,
    streakDays: 0,
    dailyMinutes: <int>[0, 0, 0, 0, 0, 0, 0],
    dailyLabels: <int>[0, 0, 0, 0, 0, 0, 0],
  );
}

DateTime dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

/// Pure so it can be tested without storage.
ReadingStats computeReadingStats(
  List<ReadingSession> sessions,
  DateTime now, {
  int chartDays = 7,
}) {
  if (sessions.isEmpty) {
    return ReadingStats.empty;
  }

  final DateTime today = dayOf(now);
  final Map<DateTime, int> perDaySeconds = <DateTime, int>{};
  int totalSeconds = 0;
  int pages = 0;

  for (final ReadingSession session in sessions) {
    final int seconds = session.duration.inSeconds.clamp(0, 6 * 3600).toInt();
    final DateTime day = session.day;
    perDaySeconds[day] = (perDaySeconds[day] ?? 0) + seconds;
    totalSeconds += seconds;
    pages += session.pages;
  }

  int minutesOf(DateTime day) => ((perDaySeconds[day] ?? 0) / 60).round();

  final List<int> dailyMinutes = <int>[];
  final List<int> dailyLabels = <int>[];
  for (int offset = chartDays - 1; offset >= 0; offset--) {
    final DateTime day = DateTime(today.year, today.month, today.day - offset);
    dailyMinutes.add(minutesOf(day));
    dailyLabels.add(day.day);
  }

  int weekMinutes = 0;
  for (final int value in dailyMinutes) {
    weekMinutes += value;
  }

  // A streak survives until today ends, so it is not lost before the reader
  // opens the app in the morning.
  int streak = 0;
  DateTime cursor = today;
  if ((perDaySeconds[cursor] ?? 0) == 0) {
    cursor = DateTime(today.year, today.month, today.day - 1);
  }
  if ((perDaySeconds[cursor] ?? 0) > 0) {
    while ((perDaySeconds[cursor] ?? 0) > 0) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
  }

  return ReadingStats(
    todayMinutes: minutesOf(today),
    weekMinutes: weekMinutes,
    totalMinutes: (totalSeconds / 60).round(),
    totalPages: pages,
    sessionCount: sessions.length,
    streakDays: streak,
    dailyMinutes: dailyMinutes,
    dailyLabels: dailyLabels,
  );
}
