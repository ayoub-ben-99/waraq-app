import '../../domain/entities/reading_session.dart';
import 'json_utils.dart';

class ReadingSessionDto {
  const ReadingSessionDto._();

  static ReadingSession fromMap(Map<String, Object?> map) {
    final DateTime startedAt = readDate(map['startedAt'], DateTime.now());
    return ReadingSession(
      id: readString(map['id'], ''),
      documentId: readString(map['documentId'], ''),
      startedAt: startedAt,
      endedAt: readDate(map['endedAt'], startedAt),
      pages: readInt(map['pages'], 0),
    );
  }

  static Map<String, Object?> toMap(ReadingSession session) {
    return <String, Object?>{
      'id': session.id,
      'documentId': session.documentId,
      'startedAt': session.startedAt.toIso8601String(),
      'endedAt': session.endedAt.toIso8601String(),
      'pages': session.pages,
    };
  }
}
