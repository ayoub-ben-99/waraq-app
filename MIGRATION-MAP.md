# Waraq migration map

Source root: `/home/johan/Documents/waraq-github`
Target root: `/home/johan/Documents/waraq-rn`

## Build and configuration

| Java source | New file |
| --- | --- |
| `app/build.gradle` | `app.json`, `android/` (generated), `modules/waraq-native/android/build.gradle` |
| `app/src/main/AndroidManifest.xml` | `app.json`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/release/AndroidManifest.xml` |
| `app/src/main/res/values/colors.xml`, `dimens.xml` | `src/theme/tokens.ts` |
| `app/src/main/res/values/themes.xml` | `src/theme/index.ts` |
| `app/src/main/res/values/strings.xml` | `src/lib/strings.ts` |
| `app/src/main/res/font/*` | `assets/fonts/*`, `App.tsx` |
| `app/src/main/java/com/waraq/app/WaraqApp.java` | `App.tsx`, `src/lib/useRefreshOnFocus.ts` |
| `app/src/main/java/com/waraq/app/Waraq.java` | `src/data/db/client.ts`, `src/features/pdf/native.ts` |
| `app/src/main/java/com/waraq/app/ui/MainActivity.java` | `src/navigation/RootNavigator.tsx`, `src/navigation/types.ts` |

## Data and utilities

| Java source | New file |
| --- | --- |
| `app/src/main/java/com/waraq/app/data/WaraqDatabase.java` | `src/data/db/client.ts` |
| `app/src/main/java/com/waraq/app/data/WaraqMigrations.java` | `src/data/db/migrations.ts` |
| `app/src/main/java/com/waraq/app/data/entity/*.java` | `src/data/db/schema.ts` |
| `app/src/main/java/com/waraq/app/data/repo/BookRepository.java` | `src/data/repos/books.ts` |
| `app/src/main/java/com/waraq/app/data/repo/KnowledgeRepository.java` | `src/data/repos/knowledge.ts` |
| `app/src/main/java/com/waraq/app/data/repo/SessionRepository.java` | `src/data/repos/sessions.ts` |
| `app/src/main/java/com/waraq/app/data/repo/SettingsRepository.java` | `src/data/repos/settings.ts` |
| `app/src/main/java/com/waraq/app/data/repo/ReviewRepository.java` | `src/data/repos/review.ts` |
| `app/src/main/java/com/waraq/app/data/repo/ReviewScheduler.java` | `src/lib/reviewScheduler.ts` |
| `app/src/main/java/com/waraq/app/data/repo/SummaryRepository.java` | `src/data/repos/summaries.ts` |
| `app/src/main/java/com/waraq/app/data/repo/SearchRepository.java` | `src/data/repos/search.ts` |
| `app/src/main/java/com/waraq/app/data/repo/StatsRepository.java` | `src/data/repos/stats.ts` |
| `app/src/main/java/com/waraq/app/data/repo/DataWiper.java` | `src/data/repos/dataWiper.ts` |
| `app/src/main/java/com/waraq/app/data/repo/PdfRepository.java` | `src/data/repos/pdf.ts` |
| `app/src/main/java/com/waraq/app/data/repo/AudioRepository.java` | `src/features/audio/audioRepository.ts` |
| `app/src/main/java/com/waraq/app/data/DraftStore.java` | `src/data/draftStore.ts` |
| `app/src/main/java/com/waraq/app/util/ArabicText.java` | `src/lib/arabicText.ts` |
| `app/src/main/java/com/waraq/app/util/Dates.java` | `src/lib/dates.ts` |
| `app/src/main/java/com/waraq/app/util/Validation.java` | `src/lib/validation.ts` |
| `app/src/main/java/com/waraq/app/util/Prefs.java` | `src/lib/prefs.ts`, `src/theme/ThemeProvider.tsx` |
| `app/src/main/java/com/waraq/app/ui/Ui.java` | `src/components/Layout.tsx`, `src/components/ChoiceDialog.tsx`, `src/lib/labels.ts` |
| `app/src/main/java/com/waraq/app/backup/BackupData.java` | `src/features/backup/backupManager.ts` |
| `app/src/main/java/com/waraq/app/backup/BackupManager.java` | `src/features/backup/backupManager.ts` |

## UI

| Java source | New file |
| --- | --- |
| `app/src/main/java/com/waraq/app/ui/HomeFragment.java` | `src/screens/HomeScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/library/LibraryFragment.java` | `src/screens/LibraryScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/library/BookAdapter.java` | `src/components/BookCard.tsx` |
| `app/src/main/java/com/waraq/app/ui/library/BookDetailActivity.java` | `src/screens/BookDetailScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/library/BookEditActivity.java` | `src/screens/BookEditScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/library/CategoriesActivity.java` | `src/screens/CategoriesScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/knowledge/KnowledgeFragment.java` | `src/screens/KnowledgeScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/knowledge/EntryAdapter.java` | `src/components/EntryCard.tsx` |
| `app/src/main/java/com/waraq/app/ui/knowledge/EntryEditActivity.java` | `src/screens/EntryEditScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/knowledge/SummaryActivity.java` | `src/screens/SummaryScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/knowledge/AudioNoteActivity.java` | `src/screens/AudioNoteScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/review/ReviewFragment.java` | `src/screens/ReviewScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/review/ReviewSessionActivity.java` | `src/screens/ReviewSessionScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/stats/StatsFragment.java` | `src/screens/StatsScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/search/SearchActivity.java` | `src/screens/SearchScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/settings/SettingsActivity.java` | `src/screens/SettingsScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/settings/BackupActivity.java` | `src/screens/BackupScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/settings/ClearDataActivity.java` | `src/screens/ClearDataScreen.tsx` |
| `app/src/main/java/com/waraq/app/ui/FilterPill.java` | `src/components/FilterPills.tsx` |
| `app/src/main/java/com/waraq/app/ui/pdf/PdfReaderActivity.java` | `src/screens/PdfReaderScreen.tsx` |

## Native module

| Java source | New file |
| --- | --- |
| `app/src/main/java/com/waraq/app/pdf/PdfImporter.java` | `modules/waraq-native/android/src/main/java/com/waraq/rn/WaraqNativeModule.kt` |
| `app/src/main/java/com/waraq/app/ui/pdf/PdfReaderActivity.java` | `modules/waraq-native/android/src/main/java/com/waraq/rn/WaraqPdfReaderActivity.kt` |
| `app/src/main/java/com/waraq/app/pdf/OcrCache.java` | `WaraqNativeModule.kt` (`clearOcrCache`) |
| `app/src/main/assets/ocr/*` | `modules/waraq-native/android/src/main/assets/ocr/*` |

## Not ported yet

- PDF text selection, reflow, search, links, and highlight creation. The native reader currently renders pages with Android `PdfRenderer` and emits page progress only.
- OCR execution. The OCR model files are bundled, but `TessOcrEngine`, `OcrTextBridge`, and `PdfLineLayout` are not wired into the new reader.
- PDF highlight loading and `onHighlightAdded` / `onEntryRequested` events are declared in JS but the native reader does not emit them.
- Java unit and Robolectric tests.
- Release signing (`keystore.properties`) and a production build. No JDK/Android SDK is available in this environment.

`INTERNET` remains in the debug manifest for Metro. `android/app/src/release/AndroidManifest.xml` removes it from release builds. All other non-audio permissions are blocked.
