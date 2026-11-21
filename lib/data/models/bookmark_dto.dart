import '../../domain/entities/bookmark.dart';
import 'json_utils.dart';

class BookmarkDto {
  const BookmarkDto._();

  static Bookmark fromMap(Map<String, Object?> map) {
    return Bookmark(
      id: readString(map['id'], ''),
      documentId: readString(map['documentId'], ''),
      page: readInt(map['page'], 1),
      createdAt: readDate(map['createdAt'], DateTime.now()),
    );
  }

  static Map<String, Object?> toMap(Bookmark bookmark) {
    return <String, Object?>{
      'id': bookmark.id,
      'documentId': bookmark.documentId,
      'page': bookmark.page,
      'createdAt': bookmark.createdAt.toIso8601String(),
    };
  }
}
