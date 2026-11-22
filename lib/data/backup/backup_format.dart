import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Version of the archive layout. Bump only for a breaking change; older
/// backups keep loading because the payload is plain JSON.
const int kBackupSchema = 1;

const String _manifestName = 'manifest.json';
const String _dataName = 'data.json';
const String _pdfPrefix = 'pdfs/';

/// A backup that cannot be read: wrong file, newer schema, missing entries.
class BackupException implements Exception {
  const BackupException(this.code);

  /// `notABackup`, `newerSchema` or `unreadable`.
  final String code;

  @override
  String toString() => 'BackupException: $code';
}

/// Everything a backup file carries, decoded into domain-neutral maps so the
/// format stays independent of the widgets that write it.
class BackupContents {
  const BackupContents({
    required this.createdAt,
    required this.appVersion,
    required this.settings,
    required this.documents,
    required this.positions,
    required this.bookmarks,
    required this.pdfs,
    this.tags = const <Map<String, Object?>>[],
  });

  final DateTime createdAt;
  final String appVersion;
  final Map<String, Object?> settings;
  final List<Map<String, Object?>> documents;
  final List<Map<String, Object?>> positions;
  final List<Map<String, Object?>> bookmarks;

  /// The reader's tag vocabulary, so a restore keeps the same labels.
  final List<Map<String, Object?>> tags;

  /// Document id → PDF bytes, empty for a data-only backup.
  final Map<String, Uint8List> pdfs;

  bool get includesPdfs => pdfs.isNotEmpty;

  int get noteCount => bookmarks
      .where((Map<String, Object?> map) {
        final Object? note = map['note'];
        return note is String && note.trim().isNotEmpty;
      })
      .length;
}

Uint8List encodeBackup(BackupContents contents) {
  final Map<String, Object?> payload = <String, Object?>{
    'schema': kBackupSchema,
    'createdAt': contents.createdAt.toIso8601String(),
    'appVersion': contents.appVersion,
    'settings': contents.settings,
    'documents': contents.documents,
    'positions': contents.positions,
    'bookmarks': contents.bookmarks,
    'tags': contents.tags,
  };
  final Map<String, Object?> manifest = <String, Object?>{
    'schema': kBackupSchema,
    'app': 'waraq',
    'createdAt': contents.createdAt.toIso8601String(),
    'appVersion': contents.appVersion,
    'includesPdfs': contents.includesPdfs,
    'counts': <String, Object?>{
      'documents': contents.documents.length,
      'positions': contents.positions.length,
      'bookmarks': contents.bookmarks.length,
      'notes': contents.noteCount,
      'tags': contents.tags.length,
      'pdfs': contents.pdfs.length,
    },
  };

  final Archive archive = Archive();
  void add(String name, List<int> bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add(_manifestName, utf8.encode(jsonEncode(manifest)));
  add(_dataName, utf8.encode(jsonEncode(payload)));
  contents.pdfs.forEach((String id, Uint8List bytes) {
    add('$_pdfPrefix$id.pdf', bytes);
  });

  final List<int>? encoded = ZipEncoder().encode(archive);
  if (encoded == null) {
    throw const BackupException('unreadable');
  }
  return Uint8List.fromList(encoded);
}

BackupContents decodeBackup(Uint8List bytes) {
  Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes, verify: false);
  } catch (_) {
    throw const BackupException('notABackup');
  }

  ArchiveFile? find(String name) {
    for (final ArchiveFile file in archive.files) {
      if (file.isFile && file.name == name) {
        return file;
      }
    }
    return null;
  }

  Map<String, Object?> readJson(String entry) {
    final ArchiveFile? file = find(entry);
    if (file == null) {
      throw const BackupException('notABackup');
    }
    final Object? decoded = jsonDecode(utf8.decode(file.content as List<int>));
    if (decoded is! Map) {
      throw const BackupException('notABackup');
    }
    return decoded.map<String, Object?>(
      (Object? key, Object? value) => MapEntry<String, Object?>('$key', value),
    );
  }

  final Map<String, Object?> manifest = readJson(_manifestName);
  final int schema = manifest['schema'] is num
      ? (manifest['schema']! as num).toInt()
      : 0;
  if (schema > kBackupSchema) {
    throw const BackupException('newerSchema');
  }

  final Map<String, Object?> data = readJson(_dataName);

  List<Map<String, Object?>> listOf(Object? value) {
    if (value is! List) {
      return const <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[
      for (final Object? item in value)
        if (item is Map)
          item.map<String, Object?>(
            (Object? key, Object? field) => MapEntry<String, Object?>('$key', field),
          ),
    ];
  }

  final Map<String, Uint8List> pdfs = <String, Uint8List>{};
  for (final ArchiveFile file in archive.files) {
    if (!file.isFile || !file.name.startsWith(_pdfPrefix)) {
      continue;
    }
    final String id = file.name
        .substring(_pdfPrefix.length)
        .replaceAll(RegExp(r'\.pdf$'), '');
    if (id.isEmpty) {
      continue;
    }
    pdfs[id] = Uint8List.fromList(file.content as List<int>);
  }

  final Object? createdAt = data['createdAt'] ?? manifest['createdAt'];
  return BackupContents(
    createdAt: createdAt is String
        ? (DateTime.tryParse(createdAt) ?? DateTime.now())
        : DateTime.now(),
    appVersion: data['appVersion'] is String
        ? data['appVersion']! as String
        : 'unknown',
    settings: data['settings'] is Map
        ? (data['settings']! as Map).map<String, Object?>(
            (Object? key, Object? value) => MapEntry<String, Object?>('$key', value),
          )
        : <String, Object?>{},
    documents: listOf(data['documents']),
    positions: listOf(data['positions']),
    bookmarks: listOf(data['bookmarks']),
    tags: listOf(data['tags']),
    pdfs: pdfs,
  );
}
