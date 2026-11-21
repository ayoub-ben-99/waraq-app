import '../../domain/entities/reading_position.dart';
import 'json_utils.dart';

class ReadingPositionDto {
  const ReadingPositionDto._();

  static ReadingPosition fromMap(Map<String, Object?> map) {
    return ReadingPosition(
      documentId: readString(map['documentId'], ''),
      page: readInt(map['page'], 1),
      progress: readDouble(map['progress'], 0).clamp(0.0, 1.0).toDouble(),
      offsetFraction:
          readDouble(map['offsetFraction'], 0).clamp(0.0, 1.0).toDouble(),
      updatedAt: readDate(map['updatedAt'], DateTime.now()),
    );
  }

  static Map<String, Object?> toMap(ReadingPosition position) {
    return <String, Object?>{
      'documentId': position.documentId,
      'page': position.page,
      'progress': position.progress,
      'offsetFraction': position.offsetFraction,
      'updatedAt': position.updatedAt.toIso8601String(),
    };
  }
}
