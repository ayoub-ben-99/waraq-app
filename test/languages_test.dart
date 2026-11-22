import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:waraq/core/l10n/app_strings.dart';

/// The catalog only needs a locale, so it is exercised without a widget tree.
AppStrings strings(Locale locale) => AppStrings(locale);

void main() {
  test('English stays the source language', () {
    final AppStrings en = strings(const Locale('en'));
    expect(en.libraryTitle, 'Library');
    expect(en.pageOf(3, 12), 'Page 3 of 12');
    expect(en.isArabic, isFalse);
  });

  test('Arabic is translated and flagged right-to-left', () {
    final AppStrings ar = strings(const Locale('ar'));
    expect(ar.libraryTitle, 'المكتبة');
    expect(ar.pageOf(3, 12), 'صفحة 3 من 12');
    expect(ar.isArabic, isTrue);
  });

  test('French reads from the overlay', () {
    final AppStrings fr = strings(const Locale('fr'));
    expect(fr.libraryTitle, 'Bibliothèque');
    expect(fr.navSettings, 'Réglages');
    expect(fr.backupTitle, 'Sauvegarde');
    expect(fr.pageOf(3, 12), 'Page 3 sur 12');
    expect(fr.isArabic, isFalse);
  });

  test('Spanish reads from the overlay', () {
    final AppStrings es = strings(const Locale('es'));
    expect(es.libraryTitle, 'Biblioteca');
    expect(es.navSettings, 'Ajustes');
    expect(es.pageOf(3, 12), 'Página 3 de 12');
    expect(es.isArabic, isFalse);
  });

  test('An untranslated string falls back to English', () {
    final AppStrings fr = strings(const Locale('fr'));
    expect(fr.documentsCount(1), '1 document');
    expect(fr.deleteDocumentTitle, isNotEmpty);
  });
}
