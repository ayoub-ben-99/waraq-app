import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../screens/backup_screen.dart';
import '../screens/review_screen.dart';
import '../screens/search_screen.dart';
import '../screens/stats_screen.dart';
import '../widgets/import_document.dart';

/// One entry of the quick-action dial. Adding a feature means adding one row
/// here: the widget builds the buttons, labels and order from it.
class FeatureAction {
  const FeatureAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.invoke,
  });

  final String id;
  final IconData icon;
  final String Function(AppStrings strings) label;
  final Future<void> Function(BuildContext context, WidgetRef ref) invoke;
}

Future<void> _push(BuildContext context, Widget screen) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (BuildContext context) => screen),
  );
}

final List<FeatureAction> kFeatureActions = <FeatureAction>[
  FeatureAction(
    id: 'import',
    icon: Icons.upload_file_rounded,
    label: (AppStrings strings) => strings.importPdf,
    invoke: (BuildContext context, WidgetRef ref) async {
      await pickAndImportPdf(context, ref);
    },
  ),
  FeatureAction(
    id: 'search',
    icon: Icons.search_rounded,
    label: (AppStrings strings) => strings.searchEverything,
    invoke: (BuildContext context, WidgetRef ref) =>
        _push(context, const SearchScreen()),
  ),
  FeatureAction(
    id: 'review',
    icon: Icons.event_repeat_rounded,
    label: (AppStrings strings) => strings.reviewTitle,
    invoke: (BuildContext context, WidgetRef ref) =>
        _push(context, const ReviewScreen()),
  ),
  FeatureAction(
    id: 'stats',
    icon: Icons.insights_rounded,
    label: (AppStrings strings) => strings.statsTitle,
    invoke: (BuildContext context, WidgetRef ref) =>
        _push(context, const StatsScreen()),
  ),
  FeatureAction(
    id: 'backup',
    icon: Icons.backup_outlined,
    label: (AppStrings strings) => strings.backupTitle,
    invoke: (BuildContext context, WidgetRef ref) =>
        _push(context, const BackupScreen()),
  ),
];
