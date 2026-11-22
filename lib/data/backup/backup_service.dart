import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/pdf_document.dart';
import '../../domain/entities/reading_position.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/reading_state_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/entities/note_tag.dart';
import '../models/app_settings_dto.dart';
import '../models/bookmark_dto.dart';
import '../models/json_utils.dart';
import '../models/note_tag_dto.dart';
import '../models/pdf_document_dto.dart';
import '../models/reading_position_dto.dart';
import 'backup_format.dart';

/// What an export produced. [path] is `null` when the reader cancelled the
/// system save dialog.
class BackupExport {
  const BackupExport({
    required this.path,
    required this.bytes,
    required this.documents,
    required this.notes,
    required this.includesPdfs,
  });

  final String? path;
  final int bytes;
  final int documents;
  final int notes;
  final bool includesPdfs;

  bool get cancelled => path == null;
}

/// What a restore merged into the current library.
class BackupRestore {
  const BackupRestore({
    required this.documentsAdded,
    required this.documentsSkipped,
    required this.notes,
    required this.settingsApplied,
  });

  final int documentsAdded;

  /// Documents whose PDF was missing from a data-only backup.
  final int documentsSkipped;
  final int notes;
  final bool settingsApplied;
}

/// Reads the whole local library, settings and notes into one `.waraq.zip`
/// file, and merges such a file back. Restoring never deletes anything: it adds
/// what is missing and keeps the newer reading position of the two.
class BackupService {
  BackupService({
    required DocumentRepository documents,
    required ReadingStateRepository reading,
    required SettingsRepository settings,
    required TagRepository tags,
  })  : _documents = documents,
        _reading = reading,
        _settings = settings,
        _tags = tags;

  final DocumentRepository _documents;
  final ReadingStateRepository _reading;
  final SettingsRepository _settings;
  final TagRepository _tags;

  Future<BackupExport> export({
    required bool includePdfs,
    required String appVersion,
  }) async {
    final List<PdfDocument> documents = await _documents.listDocuments();
    final Map<String, ReadingPosition> positions = await _reading.loadPositions();
    final List<Bookmark> bookmarks = await _reading.loadBookmarks();
    final AppSettings settings = await _settings.load();
    final List<NoteTag> tags = await _tags.load();

    final Map<String, Uint8List> pdfs = <String, Uint8List>{};
    if (includePdfs) {
      for (final PdfDocument document in documents) {
        final File file = File(document.filePath);
        if (await file.exists()) {
          pdfs[document.id] = await file.readAsBytes();
        }
      }
    }

    final Uint8List bytes = encodeBackup(
      BackupContents(
        createdAt: DateTime.now(),
        appVersion: appVersion,
        settings: AppSettingsDto.toMap(settings),
        documents: <Map<String, Object?>>[
          for (final PdfDocument document in documents)
            PdfDocumentDto.toMap(document),
        ],
        positions: <Map<String, Object?>>[
          for (final ReadingPosition position in positions.values)
            ReadingPositionDto.toMap(position),
        ],
        bookmarks: <Map<String, Object?>>[
          for (final Bookmark bookmark in bookmarks) BookmarkDto.toMap(bookmark),
        ],
        tags: <Map<String, Object?>>[
          for (final NoteTag tag in tags) NoteTagDto.toMap(tag),
        ],
        pdfs: pdfs,
      ),
    );

    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Waraq backup',
      fileName: backupFileName(DateTime.now()),
      bytes: bytes,
    );

    return BackupExport(
      path: path,
      bytes: bytes.length,
      documents: documents.length,
      notes: bookmarks.where((Bookmark bookmark) => bookmark.hasNote).length,
      includesPdfs: pdfs.isNotEmpty,
    );
  }

  /// Lets the reader pick a backup and merges it into the current data.
  Future<BackupRestore?> restoreFromPicker() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final Uint8List? bytes = result.files.first.bytes;
    if (bytes == null) {
      throw const BackupException('unreadable');
    }
    return restore(bytes);
  }

  Future<BackupRestore> restore(Uint8List bytes) async {
    final BackupContents contents = decodeBackup(bytes);
    final List<PdfDocument> existing = await _documents.listDocuments();
    final Set<String> existingIds = <String>{
      for (final PdfDocument document in existing) document.id,
    };

    final Map<String, String> idMap = <String, String>{};
    int added = 0;
    int skipped = 0;
    for (final Map<String, Object?> map in contents.documents) {
      final String oldId = readString(map['id'], '');
      if (oldId.isEmpty) {
        continue;
      }
      if (existingIds.contains(oldId)) {
        idMap[oldId] = oldId;
        continue;
      }
      final Uint8List? pdf = contents.pdfs[oldId];
      if (pdf == null) {
        skipped++;
        continue;
      }
      try {
        final PdfDocument imported = await _documents.importPdf(
          bytes: pdf,
          displayName: readString(map['title'], 'Document'),
        );
        idMap[oldId] = imported.id;
        added++;
      } catch (_) {
        skipped++;
      }
    }

    int notes = 0;
    final List<Bookmark> localBookmarks = await _reading.loadBookmarks();
    final Map<String, Bookmark> byId = <String, Bookmark>{
      for (final Bookmark bookmark in localBookmarks) bookmark.id: bookmark,
    };
    for (final Map<String, Object?> map in contents.bookmarks) {
      final Bookmark bookmark = BookmarkDto.fromMap(map);
      final String? newId = idMap[bookmark.documentId];
      if (newId == null) {
        continue;
      }
      final Bookmark remapped = Bookmark(
        id: '${newId}_${bookmark.page}',
        documentId: newId,
        page: bookmark.page,
        createdAt: bookmark.createdAt,
        note: bookmark.note,
        updatedAt: bookmark.updatedAt,
      );
      final Bookmark? local = byId[remapped.id];
      // A local note written after the backup wins; otherwise the file wins.
      if (local != null &&
          local.hasNote &&
          local.touchedAt.isAfter(remapped.touchedAt)) {
        continue;
      }
      await _reading.saveBookmark(remapped);
      if (remapped.hasNote) {
        notes++;
      }
    }

    final Map<String, ReadingPosition> localPositions =
        await _reading.loadPositions();
    for (final Map<String, Object?> map in contents.positions) {
      final ReadingPosition position = ReadingPositionDto.fromMap(map);
      final String? newId = idMap[position.documentId];
      if (newId == null) {
        continue;
      }
      final ReadingPosition? local = localPositions[newId];
      if (local != null && local.updatedAt.isAfter(position.updatedAt)) {
        continue;
      }
      await _reading.savePosition(
        ReadingPosition(
          documentId: newId,
          page: position.page,
          progress: position.progress,
          offsetFraction: position.offsetFraction,
          updatedAt: position.updatedAt,
        ),
      );
    }

    if (contents.tags.isNotEmpty) {
      final List<NoteTag> localTags = await _tags.load();
      final Set<String> known = <String>{
        for (final NoteTag tag in localTags) tag.id,
      };
      final List<NoteTag> merged = <NoteTag>[...localTags];
      for (final Map<String, Object?> map in contents.tags) {
        final NoteTag tag = NoteTagDto.fromMap(map);
        if (tag.id.isNotEmpty && tag.name.isNotEmpty && !known.contains(tag.id)) {
          merged.add(tag);
          known.add(tag.id);
        }
      }
      if (merged.length != localTags.length) {
        await _tags.save(merged);
      }
    }

    final bool settingsApplied = contents.settings.isNotEmpty;
    if (settingsApplied) {
      await _settings.save(AppSettingsDto.fromMap(contents.settings));
    }

    return BackupRestore(
      documentsAdded: added,
      documentsSkipped: skipped,
      notes: notes,
      settingsApplied: settingsApplied,
    );
  }
}

/// `waraq-2026-11-21.zip`
String backupFileName(DateTime now) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'waraq-${now.year}-${two(now.month)}-${two(now.day)}.waraq.zip';
}
