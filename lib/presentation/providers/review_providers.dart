import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/review_scheduler.dart';
import 'bookmark_providers.dart';
import 'library_providers.dart';

class ReviewSchedulesNotifier extends AsyncNotifier<Map<String, ReviewSchedule>> {
  @override
  Future<Map<String, ReviewSchedule>> build() {
    return ref.watch(reviewRepositoryProvider).load();
  }

  ReviewSchedule? scheduleFor(String bookmarkId) {
    return state.valueOrNull?[bookmarkId];
  }

  Future<void> _commit(Map<String, ReviewSchedule> next) async {
    state = AsyncData<Map<String, ReviewSchedule>>(next);
    await ref.read(reviewRepositoryProvider).save(next);
  }

  /// Records one answer and returns the new schedule.
  Future<ReviewSchedule> grade(String bookmarkId, ReviewGrade grade) async {
    final ReviewRepository repository = ref.read(reviewRepositoryProvider);
    final Map<String, ReviewSchedule> current =
        Map<String, ReviewSchedule>.of(
      state.valueOrNull ?? await repository.load(),
    );
    final ReviewSchedule next =
        scheduleAfter(current[bookmarkId], grade, DateTime.now());
    current[bookmarkId] = next;
    await _commit(current);
    return next;
  }

  Future<void> postpone(String bookmarkId, int days) async {
    final ReviewRepository repository = ref.read(reviewRepositoryProvider);
    final Map<String, ReviewSchedule> current =
        Map<String, ReviewSchedule>.of(
      state.valueOrNull ?? await repository.load(),
    );
    current[bookmarkId] = postponeSchedule(
      current[bookmarkId],
      days,
      DateTime.now(),
    );
    await _commit(current);
  }

  /// Forgets the ladder entirely, so everything becomes due again.
  Future<void> reset() async {
    await ref.read(reviewRepositoryProvider).clear();
    state = const AsyncData<Map<String, ReviewSchedule>>(
      <String, ReviewSchedule>{},
    );
  }
}

final reviewSchedulesProvider =
    AsyncNotifierProvider<ReviewSchedulesNotifier, Map<String, ReviewSchedule>>(
  ReviewSchedulesNotifier.new,
);

/// One note together with the book it belongs to and its ladder position.
class ReviewEntry {
  const ReviewEntry({
    required this.note,
    required this.document,
    required this.schedule,
  });

  final Bookmark note;
  final PdfDocument document;
  final ReviewSchedule schedule;

  bool isDueAt(DateTime now) => schedule.isDue(now);
}

final _reviewEntriesProvider = Provider<List<ReviewEntry>>((ref) {
  final List<Bookmark> notes = ref.watch(notesProvider);
  final List<PdfDocument> documents =
      ref.watch(documentsProvider).valueOrNull ?? const <PdfDocument>[];
  final Map<String, PdfDocument> byId = <String, PdfDocument>{
    for (final PdfDocument document in documents) document.id: document,
  };
  final Map<String, ReviewSchedule> schedules =
      ref.watch(reviewSchedulesProvider).valueOrNull ??
          const <String, ReviewSchedule>{};
  final DateTime now = DateTime.now();

  final List<ReviewEntry> entries = <ReviewEntry>[
    for (final Bookmark note in notes)
      if (byId[note.documentId] case final PdfDocument document)
        ReviewEntry(
          note: note,
          document: document,
          schedule: schedules[note.id] ?? initialSchedule(now),
        ),
  ];
  entries.sort((ReviewEntry a, ReviewEntry b) {
    final int byDue = a.schedule.dueAt.compareTo(b.schedule.dueAt);
    return byDue != 0 ? byDue : b.note.touchedAt.compareTo(a.note.touchedAt);
  });
  return entries;
});

/// Notes that are ready to be reviewed right now.
final reviewDueProvider = Provider<List<ReviewEntry>>((ref) {
  final DateTime now = DateTime.now();
  return <ReviewEntry>[
    for (final ReviewEntry entry in ref.watch(_reviewEntriesProvider))
      if (entry.isDueAt(now)) entry,
  ];
});

/// The next notes on the ladder, excluding what is already due.
final reviewUpcomingProvider = Provider<List<ReviewEntry>>((ref) {
  final DateTime now = DateTime.now();
  return <ReviewEntry>[
    for (final ReviewEntry entry in ref.watch(_reviewEntriesProvider))
      if (!entry.isDueAt(now)) entry,
  ].take(6).toList(growable: false);
});

final reviewDueCountProvider = Provider<int>(
  (ref) => ref.watch(reviewDueProvider).length,
);
