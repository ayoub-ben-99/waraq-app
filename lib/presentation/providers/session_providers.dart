import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_providers.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/reading_stats.dart';

/// Reading history: one entry per stretch spent inside the reader.
class SessionsNotifier extends AsyncNotifier<List<ReadingSession>> {
  @override
  Future<List<ReadingSession>> build() {
    return ref.watch(sessionRepositoryProvider).load();
  }

  /// Anything shorter than this is a glance, not a session.
  static const Duration minimum = Duration(seconds: 20);

  Future<void> record({
    required String documentId,
    required DateTime startedAt,
    int pages = 0,
  }) async {
    final DateTime now = DateTime.now();
    if (now.difference(startedAt) < minimum) {
      return;
    }
    final ReadingSession session = ReadingSession(
      id: 's${now.microsecondsSinceEpoch.toRadixString(36)}',
      documentId: documentId,
      startedAt: startedAt,
      endedAt: now,
      pages: pages < 0 ? 0 : pages,
    );
    await ref.read(sessionRepositoryProvider).add(session);
    final List<ReadingSession> current = state.valueOrNull ?? const <ReadingSession>[];
    state = AsyncData<List<ReadingSession>>(<ReadingSession>[
      ...current,
      session,
    ]);
  }

  Future<void> clear() async {
    await ref.read(sessionRepositoryProvider).clear();
    state = const AsyncData<List<ReadingSession>>(<ReadingSession>[]);
  }
}

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<ReadingSession>>(
  SessionsNotifier.new,
);

/// Everything the stats screen needs, recomputed when the history changes.
final readingStatsProvider = Provider<ReadingStats>((ref) {
  final List<ReadingSession> sessions =
      ref.watch(sessionsProvider).valueOrNull ?? const <ReadingSession>[];
  return computeReadingStats(sessions, DateTime.now());
});
