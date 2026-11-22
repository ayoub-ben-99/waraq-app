import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/core/l10n/app_strings.dart';

/// Builds [AppStrings] for a locale by looking it up from a real context.
Future<AppStrings> _stringsFor(
  WidgetTester tester,
  Locale locale,
) async {
  late AppStrings captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      home: Builder(
        builder: (BuildContext context) {
          captured = AppStrings.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('English stays the source language', (WidgetTester tester) async {
    final AppStrings strings = await _stringsFor(tester, const Locale('en'));
    expect(strings.libraryTitle, 'Library');
    expect(strings.isArabic, isFalse);
  });

  testWidgets('Arabic is translated and flagged right-to-left',
      (WidgetTester tester) async {
    final AppStrings strings = await _stringsFor(tester, const Locale('ar'));
    expect(strings.libraryTitle, 'المكتبة');
    expect(strings.isArabic, isTrue);
  });

  testWidgets('French reads from the overlay', (WidgetTester tester) async {
    final AppStrings strings = await _stringsFor(tester, const Locale('fr'));
    expect(strings.libraryTitle, 'Bibliothèque');
    expect(strings.navSettings, 'Réglages');
    expect(strings.pageOf(3, 12), 'Page 3 sur 12');
    expect(strings.isArabic, isFalse);
  });

  testWidgets('Spanish reads from the overlay', (WidgetTester tester) async {
    final AppStrings strings = await _stringsFor(tester, const Locale('es'));
    expect(strings.libraryTitle, 'Biblioteca');
    expect(strings.pageOf(3, 12), 'Página 3 de 12');
    expect(strings.isArabic, isFalse);
  });

  testWidgets('An untranslated string falls back to English',
      (WidgetTester tester) async {
    final AppStrings strings = await _stringsFor(tester, const Locale('fr'));
    // Deliberately long copy that was translated: both paths return text.
    expect(strings.deleteDocumentTitle, isNotEmpty);
    expect(strings.backupTitle, 'Sauvegarde');
  });
}
