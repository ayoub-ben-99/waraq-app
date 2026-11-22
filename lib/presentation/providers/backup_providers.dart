import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_service.dart';
import '../../data/data_providers.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    documents: ref.watch(documentRepositoryProvider),
    reading: ref.watch(readingStateRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    tags: ref.watch(tagRepositoryProvider),
  );
});

/// True while an export or a restore is running, so the buttons can lock.
final backupBusyProvider = StateProvider<bool>((ref) => false);
