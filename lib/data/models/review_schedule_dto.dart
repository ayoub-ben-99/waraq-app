import '../../domain/review_scheduler.dart';
import 'json_utils.dart';

class ReviewScheduleDto {
  const ReviewScheduleDto._();

  static ReviewSchedule fromMap(Map<String, Object?> map) {
    return ReviewSchedule(
      intervalIndex: readInt(map['intervalIndex'], 0)
          .clamp(0, kReviewIntervals.length - 1)
          .toInt(),
      dueAt: readDate(map['dueAt'], DateTime.now()),
      reviews: readInt(map['reviews'], 0),
      lastReviewedAt: map['lastReviewedAt'] == null
          ? null
          : readDate(map['lastReviewedAt'], DateTime.now()),
    );
  }

  static Map<String, Object?> toMap(ReviewSchedule schedule) {
    return <String, Object?>{
      'intervalIndex': schedule.intervalIndex,
      'dueAt': schedule.dueAt.toIso8601String(),
      'reviews': schedule.reviews,
      if (schedule.lastReviewedAt != null)
        'lastReviewedAt': schedule.lastReviewedAt!.toIso8601String(),
    };
  }
}
