import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/shape_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/backup/backup_format.dart';
import '../../data/backup/backup_service.dart';
import '../providers/backup_providers.dart';
import '../providers/bookmark_providers.dart';
import '../providers/library_providers.dart';
import '../providers/settings_providers.dart';

/// Export and restore the local library as one portable file.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _includePdfs = true;

  Future<void> _export() async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BackupService service = ref.read(backupServiceProvider);
    ref.read(backupBusyProvider.notifier).state = true;
    try {
      final BackupExport result = await service.export(
        includePdfs: _includePdfs,
        appVersion: AppInfo.version,
      );
      if (!mounted) {
        return;
      }
      if (result.cancelled) {
        return;
      }
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              strings.backupExported(
                formatBytes(result.bytes),
                result.documents,
              ),
            ),
          ),
        );
    } on BackupException {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.backupFailed)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.backupFailed)),
      );
    } finally {
      ref.read(backupBusyProvider.notifier).state = false;
    }
  }

  Future<void> _restore() async {
    final AppStrings strings = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BackupService service = ref.read(backupServiceProvider);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(strings.backupRestoreTitle),
        content: Text(strings.backupRestoreBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    ref.read(backupBusyProvider.notifier).state = true;
    try {
      final BackupRestore? result = await service.restoreFromPicker();
      if (!mounted || result == null) {
        return;
      }
      ref.invalidate(documentsProvider);
      ref.invalidate(bookmarksProvider);
      await ref.read(positionsProvider.notifier).refresh();
      if (result.settingsApplied) {
        await ref.read(settingsProvider.notifier).reload();
      }
      if (!mounted) {
        return;
      }
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              strings.backupRestored(
                result.documentsAdded,
                result.notes,
                result.documentsSkipped,
              ),
            ),
          ),
        );
    } on BackupException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'newerSchema'
                ? strings.backupNewerVersion
                : strings.backupNotAFile,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.backupFailed)));
    } finally {
      ref.read(backupBusyProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool busy = ref.watch(backupBusyProvider);
    final int documents =
        ref.watch(documentsProvider).valueOrNull?.length ?? 0;
    final int notes = ref.watch(notesProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.backupTitle),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xs, Gap.xl, Gap.xxl),
          children: <Widget>[
            Text(
              strings.backupIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Gap.l),
            _Card(
              children: <Widget>[
                SwitchListTile.adaptive(
                  value: _includePdfs,
                  onChanged: busy
                      ? null
                      : (bool value) => setState(() => _includePdfs = value),
                  title: Text(strings.backupIncludePdfs),
                  subtitle: Text(strings.backupIncludePdfsBody),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.l,
                    vertical: Gap.xs,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          strings.backupContentsSummary(documents, notes),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: busy ? null : () => unawaited(_export()),
                        icon: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text(strings.exportBackup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.l),
            _Card(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              strings.backupRestoreSection,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.backupRestoreHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Gap.m),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => unawaited(_restore()),
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(strings.restore),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.l),
            Text(
              strings.backupPrivacyNote,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withFraction(0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: WaraqShape.of(context).allLg,
        border: Border.all(color: scheme.outlineVariant.withFraction(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
