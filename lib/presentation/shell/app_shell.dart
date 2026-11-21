import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/settings_screen.dart';

/// Four top-level destinations. Each keeps its scroll position because the
/// shell uses an [IndexedStack].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _select(int index) {
    if (index == _index) {
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeScreen(),
          LibraryScreen(),
          NotesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: WaraqBottomDock(
        index: _index,
        onSelected: _select,
      ),
    );
  }
}

/// Material 3 [NavigationBar] whose surface extends behind the gesture bar
/// while its content respects the safe-area inset.
class WaraqBottomDock extends StatelessWidget {
  const WaraqBottomDock({
    required this.index,
    required this.onSelected,
    super.key,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withFraction(0.45)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelected,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: strings.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.library_books_outlined),
              selectedIcon: const Icon(Icons.library_books_rounded),
              label: strings.navLibrary,
            ),
            NavigationDestination(
              icon: const Icon(Icons.sticky_note_2_outlined),
              selectedIcon: const Icon(Icons.sticky_note_2_rounded),
              label: strings.navNotes,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: strings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
