/// Spaced repetition for notes, ported from the React Native app.
///
/// A note climbs a fixed ladder of intervals while the reader keeps answering
/// "I know", drops to the first rung on "I forgot" and stays put on "almost".
class ReviewGrade {
  const ReviewGrade._(this.name);

  final String name;

  static const ReviewGrade forgot = ReviewGrade._('forgot');
  static const ReviewGrade partial = ReviewGrade._('partial');
  static const ReviewGrade good = ReviewGrade._('good');
}

/// Default ladder in days. A note returns after 1, 3, 7, 16 and then 35 days.
const List<int> kReviewIntervals = <int>[1, 3, 7, 16, 35];

/// Where a note sits on the ladder, and when it comes back.
class ReviewSchedule {
  const ReviewSchedule({
    required this.intervalIndex,
    required this.dueAt,
    this.reviews = 0,
    this.lastReviewedAt,
  });

  final int intervalIndex;
  final DateTime dueAt;
  final int reviews;
  final DateTime? lastReviewedAt;

  int get intervalDays => kReviewIntervals[
      intervalIndex.clamp(0, kReviewIntervals.length - 1).toInt()];

  /// A schedule that has never been reviewed is due immediately.
  bool isDue(DateTime now) => !dueAt.isAfter(now);

  ReviewSchedule copyWith({
    int? intervalIndex,
    DateTime? dueAt,
    int? reviews,
    DateTime? lastReviewedAt,
  }) {
    return ReviewSchedule(
      intervalIndex: intervalIndex ?? this.intervalIndex,
      dueAt: dueAt ?? this.dueAt,
      reviews: reviews ?? this.reviews,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewSchedule &&
        other.intervalIndex == intervalIndex &&
        other.dueAt == dueAt &&
        other.reviews == reviews &&
        other.lastReviewedAt == lastReviewedAt;
  }

  @override
  int get hashCode =>
      Object.hash(intervalIndex, dueAt, reviews, lastReviewedAt);
}

DateTime _addDays(DateTime from, int days) {
  final DateTime day = DateTime(from.year, from.month, from.day);
  return DateTime(day.year, day.month, day.day + days, 9);
}

/// First schedule for a brand-new note: due now, then the ladder starts.
ReviewSchedule initialSchedule(DateTime now) {
  return ReviewSchedule(
    intervalIndex: 0,
    dueAt: DateTime(now.year, now.month, now.day, 9),
    reviews: 0,
  );
}

/// Applies one answer to [current] (or to a fresh note when `null`).
///
/// * [ReviewGrade.forgot] → back to 1 day.
/// * [ReviewGrade.partial] → repeat the current rung.
/// * [ReviewGrade.good] → climb one rung, capped at the last interval.
ReviewSchedule scheduleAfter(
  ReviewSchedule? current,
  ReviewGrade grade,
  DateTime now,
) {
  final int startIndex = current?.intervalIndex ?? 0;
  final int reviews = (current?.reviews ?? 0) + 1;
  final int lastIndex = kReviewIntervals.length - 1;

  int index;
  if (grade == ReviewGrade.forgot) {
    index = 0;
  } else if (grade == ReviewGrade.good) {
    index = (startIndex + 1).clamp(0, lastIndex).toInt();
  } else {
    index = startIndex.clamp(0, lastIndex).toInt();
  }

  return ReviewSchedule(
    intervalIndex: index,
    dueAt: _addDays(now, kReviewIntervals[index]),
    reviews: reviews,
    lastReviewedAt: now,
  );
}

/// Pushes a note into the future without touching its rung.
ReviewSchedule postponeSchedule(
  ReviewSchedule? current,
  int days,
  DateTime now,
) {
  final int safeDays = days.clamp(1, 365).toInt();
  return ReviewSchedule(
    intervalIndex: (current?.intervalIndex ?? 0)
        .clamp(0, kReviewIntervals.length - 1)
        .toInt(),
    dueAt: _addDays(now, safeDays),
    reviews: current?.reviews ?? 0,
    lastReviewedAt: current?.lastReviewedAt,
  );
}

/// Whole days between [dueAt] and [now]; negative when overdue.
int daysUntilDue(DateTime dueAt, DateTime now) {
  final DateTime a = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final DateTime b = DateTime(now.year, now.month, now.day);
  return a.difference(b).inDays;
}
