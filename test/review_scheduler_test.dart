import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/data/models/review_schedule_dto.dart';
import 'package:waraq/domain/review_scheduler.dart';

void main() {
  final DateTime today = DateTime(2026, 11, 21, 14, 30);

  group('review ladder', () {
    test('a new note is due immediately and starts on the first rung', () {
      final ReviewSchedule schedule = initialSchedule(today);
      expect(schedule.intervalIndex, 0);
      expect(schedule.isDue(today), isTrue);
      expect(schedule.reviews, 0);
    });

    test('"good" climbs one rung and schedules the day it is due', () {
      ReviewSchedule schedule = initialSchedule(today);
      schedule = scheduleAfter(schedule, ReviewGrade.good, today);
      expect(schedule.intervalIndex, 1);
      expect(schedule.dueAt, DateTime(2026, 11, 24, 9));
      expect(schedule.isDue(today), isFalse);
      expect(schedule.reviews, 1);
    });

    test('"forgot" drops back to one day', () {
      final ReviewSchedule inTheMiddle = ReviewSchedule(
        intervalIndex: 3,
        dueAt: today,
        reviews: 6,
      );
      final ReviewSchedule next =
          scheduleAfter(inTheMiddle, ReviewGrade.forgot, today);
      expect(next.intervalIndex, 0);
      expect(next.dueAt, DateTime(2026, 11, 22, 9));
      expect(next.reviews, 7);
    });

    test('"almost" repeats the same rung', () {
      final ReviewSchedule inTheMiddle = ReviewSchedule(
        intervalIndex: 2,
        dueAt: today,
        reviews: 2,
      );
      final ReviewSchedule next =
          scheduleAfter(inTheMiddle, ReviewGrade.partial, today);
      expect(next.intervalIndex, 2);
      expect(next.dueAt, DateTime(2026, 11, 28, 9));
    });

    test('the ladder stops at the last interval', () {
      ReviewSchedule schedule = initialSchedule(today);
      for (int i = 0; i < 10; i++) {
        schedule = scheduleAfter(schedule, ReviewGrade.good, today);
      }
      expect(schedule.intervalIndex, kReviewIntervals.length - 1);
      expect(schedule.intervalDays, 35);
    });

    test('postponing keeps the rung and moves only the date', () {
      final ReviewSchedule schedule = ReviewSchedule(
        intervalIndex: 2,
        dueAt: today,
        reviews: 3,
      );
      final ReviewSchedule next = postponeSchedule(schedule, 7, today);
      expect(next.intervalIndex, 2);
      expect(next.reviews, 3);
      expect(next.dueAt, DateTime(2026, 11, 28, 9));
    });

    test('days until due counts calendar days', () {
      expect(
        daysUntilDue(DateTime(2026, 11, 25, 9), today),
        4,
      );
      expect(daysUntilDue(DateTime(2026, 11, 19, 9), today), -2);
    });

    test('a stored schedule round-trips', () {
      final ReviewSchedule schedule = ReviewSchedule(
        intervalIndex: 4,
        dueAt: DateTime(2027, 1, 2, 9),
        reviews: 12,
        lastReviewedAt: today,
      );
      expect(ReviewScheduleDto.fromMap(ReviewScheduleDto.toMap(schedule)),
          schedule);
    });

    test('a corrupted interval falls back inside the ladder', () {
      final ReviewSchedule schedule = ReviewScheduleDto.fromMap(
        <String, Object?>{
          'intervalIndex': 99,
          'dueAt': today.toIso8601String(),
        },
      );
      expect(schedule.intervalIndex, kReviewIntervals.length - 1);
    });
  });
}
