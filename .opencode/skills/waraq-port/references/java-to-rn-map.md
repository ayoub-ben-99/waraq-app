# Java to React Native Map
Contents: UI classes · Repository classes · Utility classes · Audio classes · Backup classes · Core data classes · Native module classes · Library mapping

Source: `app/src/main/java/com/waraq/app/`. Read the Java class before creating its target file.

## UI classes

| Java source | TypeScript target | Notes |
|---|---|---|
| `ui/MainActivity.java` | `src/navigation/RootNavigator.tsx` | Five bottom tabs plus stacks |
| `ui/SplashActivity.java` | `src/screens/SplashScreen.tsx` | Use `expo-splash-screen`, not a JS delay |
| `ui/HomeFragment.java` | `src/screens/HomeScreen.tsx` | Preserve sections and order |
| `ui/Ui.java` | `src/theme/ui.ts` | Shared dimensions and helpers |
| `ui/FilterPill.java` | `src/components/FilterPill.tsx` | Same selected states |
| `ui/SwipeFrameLayout.java` | `src/components/SwipeFrame.tsx` | Keep gesture behavior |
| `ui/library/LibraryFragment.java` | `src/screens/library/LibraryScreen.tsx` | Tabs, filters, sorting |
| `ui/library/BookAdapter.java` | `src/components/library/BookList.tsx` | `FlashList` |
| `ui/library/BookEditActivity.java` | `src/screens/library/BookEditScreen.tsx` | Same validation |
| `ui/library/BookDetailActivity.java` | `src/screens/library/BookDetailScreen.tsx` | Same actions |
| `ui/library/CategoriesActivity.java` | `src/screens/library/CategoriesScreen.tsx` | Same merge rules |
| `ui/knowledge/KnowledgeFragment.java` | `src/screens/knowledge/KnowledgeScreen.tsx` | Filters and counts |
| `ui/knowledge/EntryAdapter.java` | `src/components/knowledge/EntryList.tsx` | `FlashList` |
| `ui/knowledge/EntryEditActivity.java` | `src/screens/knowledge/EntryEditScreen.tsx` | Type-specific fields |
| `ui/knowledge/SummaryActivity.java` | `src/screens/knowledge/SummaryScreen.tsx` | Summary sections |
| `ui/knowledge/AudioNoteActivity.java` | `src/screens/knowledge/AudioNoteScreen.tsx` | Phase 7 |
| `ui/review/ReviewFragment.java` | `src/screens/review/ReviewScreen.tsx` | Due and upcoming |
| `ui/review/ReviewSessionActivity.java` | `src/screens/review/ReviewSessionScreen.tsx` | Same grading flow |
| `ui/search/SearchActivity.java` | `src/screens/search/SearchScreen.tsx` | Same grouping |
| `ui/stats/StatsFragment.java` | `src/screens/stats/StatsScreen.tsx` | Same ranges |
| `ui/stats/ReadingChartView.java` | `src/components/stats/ReadingChart.tsx` | `react-native-svg` |
| `ui/stats/StatsExport.java` | `src/lib/stats/exportCsv.ts` | Same CSV columns |
| `ui/settings/SettingsActivity.java` | `src/screens/settings/SettingsScreen.tsx` | Same keys |
| `ui/settings/BackupActivity.java` | `src/screens/settings/BackupScreen.tsx` | Phase 6 |
| `ui/settings/ClearDataActivity.java` | `src/screens/settings/ClearDataScreen.tsx` | Same confirmation |
| `ui/pdf/PdfIntake.java` | native call in `src/features/pdf/importPdf.ts` | UI moves to native |
| `ui/pdf/PdfPageView.java` | native module | Do not port to TS |
| `ui/pdf/PdfVerticalView.java` | native module | Do not port to TS |
| `ui/pdf/PdfReaderActivity.java` | native module | Do not port to TS |
| `ui/pdf/ReaderPrefs.java` | native module | Do not port to TS |

## Repository classes

| Java source | TypeScript target |
|---|---|
| `data/repo/BookRepository.java` | `src/data/repos/bookRepository.ts` |
| `data/repo/KnowledgeRepository.java` | `src/data/repos/knowledgeRepository.ts` |
| `data/repo/SearchRepository.java` | `src/data/repos/searchRepository.ts` |
| `data/repo/SummaryRepository.java` | `src/data/repos/summaryRepository.ts` |
| `data/repo/SessionRepository.java` | `src/data/repos/sessionRepository.ts` |
| `data/repo/ReviewRepository.java` | `src/data/repos/reviewRepository.ts` |
| `data/repo/ReviewScheduler.java` | `src/lib/srs/scheduler.ts` |
| `data/repo/SettingsRepository.java` | `src/data/repos/settingsRepository.ts` |
| `data/repo/StatsRepository.java` | `src/data/repos/statsRepository.ts` |
| `data/repo/PdfRepository.java` | `src/data/repos/pdfRepository.ts` |
| `data/repo/AudioRepository.java` | `src/data/repos/audioRepository.ts` |
| `data/repo/DataWiper.java` | `src/data/dataWiper.ts` |

## Utility classes

| Java source | TypeScript target | Mapping |
|---|---|---|
| `util/ArabicText.java` | `src/lib/arabicText.ts` | Direct port |
| `util/Dates.java` | `src/lib/dates.ts` | `date-fns` plus local start/end of day |
| `util/Validation.java` | `src/lib/validation.ts` | `zod` |
| `util/Prefs.java` | `src/lib/prefs.ts` | `react-native-mmkv` |
| `util/Clip.java` | `src/lib/clipboard.ts` | `expo-clipboard` |
| `util/Images.java` | `src/lib/images.ts` | `expo-image-picker`, `expo-file-system` |
| `util/Async.java` | none | Replace with `async`/`await` and TanStack Query |
| `util/Callback.java` | none | Replace with `Promise` and query callbacks |

## Audio classes

| Java source | TypeScript target |
|---|---|
| `audio/AudioRecorder.java` | `src/features/audio/recorder.ts` |
| `audio/AudioPlayer.java` | `src/features/audio/player.ts` |
| `audio/RecordingSession.java` | `src/features/audio/recordingSession.ts` |

## Backup classes

| Java source | TypeScript target |
|---|---|
| `backup/BackupManager.java` | `src/features/backup/backupManager.ts` |
| `backup/BackupData.java` | `src/features/backup/types.ts` |

## Core data classes

| Java source | TypeScript target |
|---|---|
| `data/WaraqDatabase.java` | `src/data/db/client.ts` |
| `data/WaraqMigrations.java` | `src/data/db/migrations.ts` |
| `data/DraftStore.java` | `src/data/draftStore.ts` |
| `Waraq.java` | `src/data/bootstrap.ts` |
| `WaraqApp.java` | `src/app/App.tsx` |

## Native module classes

Move these unchanged into `modules/waraq-native/android/src/main/java/com/waraq/native/`:

`pdf/AndroidPdfPageRenderer.java`, `pdf/BidiText.java`, `pdf/CancelFlag.java`, `pdf/OcrCache.java`, `pdf/OcrTextBridge.java`, `pdf/PageCache.java`, `pdf/PdfBoxTextEngine.java`, `pdf/PdfImporter.java`, `pdf/PdfLineLayout.java`, `pdf/PdfLink.java`, `pdf/PdfPageRenderer.java`, `pdf/PdfRenderers.java`, `pdf/PdfRenderSession.java`, `pdf/PdfSearcher.java`, `pdf/PdfSearch.java`, `pdf/PdfSelection.java`, `pdf/PdfTextEngine.java`, `pdf/PdfText.java`, `pdf/PdfTextReader.java`, `pdf/PdfTextSession.java`, `pdf/ReflowText.java`, `pdf/TessOcrEngine.java`, `pdf/VerticalStrip.java`, plus all `ui/pdf/*.java`.

Do not translate or rewrite this code. Only add the Kotlin Expo module wrapper and adjust Android imports if the package changes.

## Library mapping

| Java | React Native |
|---|---|
| Room entities, DAOs, database | `expo-sqlite` plus Drizzle ORM |
| RecyclerView adapters | `@shopify/flash-list` |
| Material Components | `react-native-paper` |
| Fragment, AppCompat, Activity | `@react-navigation/native-stack`, `bottom-tabs` |
| MediaRecorder, MediaPlayer | `expo-audio` |
| `Callback`, `Async` | TanStack Query plus Promises |
| SharedPreferences | `react-native-mmkv` |
| Manual validation | `zod` |
| PdfRenderer, PdfBox, Tesseract | `waraq-native` |
| Custom chart view | `react-native-svg` |
| ZIP backup | `react-native-zip-archive` with `java.util.zip` semantics |
