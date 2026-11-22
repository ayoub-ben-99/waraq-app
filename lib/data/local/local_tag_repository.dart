import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/note_tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../models/json_utils.dart';
import '../models/note_tag_dto.dart';
import 'prefs_keys.dart';

class LocalTagRepository implements TagRepository {
  LocalTagRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<List<NoteTag>> load() async {
    final String? raw = _prefs.getString(PrefsKeys.tags);
    if (raw == null || raw.isEmpty) {
      return const <NoteTag>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <NoteTag>[];
      }
      final List<NoteTag> tags = <NoteTag>[];
      for (final Object? item in decoded) {
        if (item is! Map) {
          continue;
        }
        final NoteTag tag = NoteTagDto.fromMap(readMap(item));
        if (tag.id.isNotEmpty && tag.name.isNotEmpty) {
          tags.add(tag);
        }
      }
      return tags;
    } catch (_) {
      return const <NoteTag>[];
    }
  }

  @override
  Future<void> save(List<NoteTag> tags) async {
    await _prefs.setString(
      PrefsKeys.tags,
      jsonEncode(<Object?>[
        for (final NoteTag tag in tags) NoteTagDto.toMap(tag),
      ]),
    );
  }
}
