import '../review_scheduler.dart';

/// Stores the review ladder position of every note, keyed by bookmark id.
abstract interface class ReviewRepository {
  Future<Map<String, ReviewSchedule>> load();

  Future<void> save(Map<String, ReviewSchedule> schedules);

  Future<void> clear();
}
