/// One stretch of reading: opened a book, read for a while, left.
class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.documentId,
    required this.startedAt,
    required this.endedAt,
    this.pages = 0,
  });

  final String id;
  final String documentId;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Pages turned during the session (0 when the reader stayed on one page).
  final int pages;

  Duration get duration => endedAt.difference(startedAt);

  int get minutes => duration.inMinutes;

  /// Start day, used for streaks and the daily chart.
  DateTime get day => DateTime(startedAt.year, startedAt.month, startedAt.day);

  @override
  bool operator ==(Object other) {
    return other is ReadingSession &&
        other.id == id &&
        other.documentId == documentId &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.pages == pages;
  }

  @override
  int get hashCode =>
      Object.hash(id, documentId, startedAt, endedAt, pages);
}
