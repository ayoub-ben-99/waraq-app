import '../../domain/entities/note_tag.dart';
import 'json_utils.dart';

class NoteTagDto {
  const NoteTagDto._();

  static NoteTag fromMap(Map<String, Object?> map) {
    return NoteTag(
      id: readString(map['id'], ''),
      name: readString(map['name'], ''),
      colorIndex: readInt(map['colorIndex'], 0),
    );
  }

  static Map<String, Object?> toMap(NoteTag tag) {
    return <String, Object?>{
      'id': tag.id,
      'name': tag.name,
      'colorIndex': tag.colorIndex,
    };
  }
}
