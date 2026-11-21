import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'domain/entities/app_settings.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/shell/app_shell.dart';

class WaraqApp extends ConsumerWidget {
  const WaraqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Waraq',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: WaraqTheme.lightTheme(
            settings: settings,
            dynamicScheme: lightDynamic,
          ),
          darkTheme: WaraqTheme.darkTheme(
            settings: settings,
            dynamicScheme: darkDynamic,
          ),
          // Material 3 cross-fades the whole palette when the mode changes.
          themeAnimationDuration: Motion.theme,
          themeAnimationCurve: Motion.emphasized,
          locale: locale,
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (BuildContext context, Widget? child) {
            final MediaQueryData media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.35,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppShell(),
        );
      },
    );
  }
}
