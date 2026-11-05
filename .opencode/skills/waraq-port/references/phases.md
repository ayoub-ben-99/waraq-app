# Migration Phases
Contents: Phase 1 shell · Phase 2 data · Phase 3 library · Phase 4 knowledge · Phase 5 review/stats · Phase 6 backup · Phase 7 audio · Phase 8 native · Phase 9 tests · Phase 10 release

Work one phase at a time. Do not start the next phase until the current done criterion is met. Commit once at the end of each phase. Do not run tests, lint, or `tsc` before phase 9.

## Phase 1: Shell, theme, navigation

Read: `stack.md`, `java-to-rn-map.md`.

Scope:

- Create the Expo SDK 58 Development Build at `/home/johan/Documents/waraq-rn`.
- Android only. No `ios/`, no iOS config, no Expo Go.
- New Architecture, Hermes, TypeScript strict, `minSdk 24`, compile/target 36.
- Load the four source fonts from `assets/fonts/`.
- RTL Arabic UI. Use Latin digits in dates.
- Five bottom tabs: Home, Library, Knowledge, Review, Stats. Add Settings as the existing app does.
- Splash screen and status bar.
- Permissions: `RECORD_AUDIO` only.
- Empty screens with the source tab titles and icons. No fake data.

Java sources: `ui/MainActivity.java`, `ui/SplashActivity.java`, `ui/HomeFragment.java`, `ui/Ui.java`, `ui/FilterPill.java`, `ui/SwipeFrameLayout.java`, plus the source theme, colors, strings, and font resources.

Done: Android dev build runs; five tabs render RTL with source fonts; no iOS files; `scripts/check-no-ios.sh` prints OK.

## Phase 2: Data layer and utilities

Read: `schema.md`, `arabic-text.md`, `srs.md`, `java-to-rn-map.md`.

Scope:

- Drizzle schema for all 13 tables, 20 indexes, foreign keys, defaults.
- `expo-sqlite` client with foreign keys and WAL.
- Fresh database at schema 3. Do not port v1/v2 migrations.
- Core repositories for books, knowledge, search, summaries, sessions, reviews, settings, and stats. PDF and audio repositories belong to phases 8 and 7.
- `ArabicText`, `Dates`, `Validation`, `Prefs`, `DraftStore`, data bootstrap.
- SRS scheduler, interval parsing/sanitizing, settings keys.
- No sample rows.

Java sources: `data/WaraqDatabase.java`, `data/WaraqMigrations.java`, `data/DraftStore.java`, all `data/entity/*.java`, `data/repo/{Book,Knowledge,Search,Summary,Session,Review,Settings,Stats}Repository.java`, `data/repo/ReviewScheduler.java`, `util/ArabicText.java`, `util/Dates.java`, `util/Validation.java`, `util/Prefs.java`, `util/Async.java`, `util/Callback.java`, `Waraq.java`, `WaraqApp.java`.

Done: schema matches `3.json` by inspection; every repository method from the source exists; no screen still depends on a missing repository.

## Phase 3: Library

Read: `schema.md`, `arabic-text.md`.

Scope:

- Library list, search, sort, filters, status tabs.
- Add/edit/delete book. Cover pick and display.
- Book detail with progress, sessions, PDF status, actions.
- Categories list, create, rename, merge, delete behavior.
- Book status, rating, favorite, started/finished timestamps.

Java sources: `ui/library/LibraryFragment.java`, `BookAdapter.java`, `BookEditActivity.java`, `BookDetailActivity.java`, `CategoriesActivity.java`, `data/repo/BookRepository.java`, `util/Images.java`, `util/Dates.java`.

Done: all source library actions work; no source action is missing; empty states match the Java screens.

## Phase 4: Knowledge

Read: `schema.md`, `arabic-text.md`.

Scope:

- Knowledge list with type filters, book filter, tag filter, favorite, sorting.
- Entry create/edit/delete. Quote text and comment stay separate.
- Five entry types with the same fields and validation.
- Summary screen, one summary per book.
- Search grouped into books, quotes, benefits, summaries, notes, tags. Minimum 2 normalized characters.

Java sources: `ui/knowledge/KnowledgeFragment.java`, `EntryAdapter.java`, `EntryEditActivity.java`, `SummaryActivity.java`, `ui/search/SearchActivity.java`, `data/repo/KnowledgeRepository.java`, `SearchRepository.java`, `SummaryRepository.java`.

Done: all five types, tags, summaries, and search groups behave as in Java; search uses `ArabicText` and the stored norm columns.

## Phase 5: Review, stats, settings

Read: `srs.md`, `schema.md`.

Scope:

- Review due list, upcoming list, counts, overdue marking.
- Add/remove review, grade FORGOT/PARTIAL/GOOD, postpone.
- Review session flow and completion state.
- Stats ranges and numbers. Reading chart via `react-native-svg`.
- CSV export with the same columns as `StatsExport`.
- Settings for intervals and other source settings. Same validation.
- Clear data flow with the same confirmation and scope.

Java sources: `ui/review/ReviewFragment.java`, `ReviewSessionActivity.java`, `ui/stats/StatsFragment.java`, `ReadingChartView.java`, `StatsExport.java`, `ui/settings/SettingsActivity.java`, `ClearDataActivity.java`, `data/repo/ReviewRepository.java`, `ReviewScheduler.java`, `SettingsRepository.java`, `StatsRepository.java`, `SessionRepository.java`, `DataWiper.java`.

Done: scheduler vectors match `srs.md`; stats totals and CSV columns match Java; clear data removes exactly what `DataWiper` removes.

## Phase 6: Backup and restore

Read: `backup-format.md`, `schema.md`, `native-module.md` for PDF relink only.

Scope:

- Export ZIP with schema 3 `manifest.json`, `data.json`, covers, PDFs when chosen, audio.
- Import validation in the exact order in `backup-format.md`.
- Merge and replace modes, deduplication, orphan rejection, transactional restore.
- PDF relink by SHA-256 and page count.
- Backup screen, progress, errors, unencrypted warning, last backup timestamp.

Java sources: `ui/settings/BackupActivity.java`, `backup/BackupManager.java`, `backup/BackupData.java`, `data/repo/PdfRepository.java` (relink only).

Done: a schema 3 export re-imports with merge and replace; missing audio, bad counts, orphans, and newer schema are rejected before any DB write; cover and audio byte sizes are correct.

## Phase 7: Audio notes

Read: `schema.md`, `java-to-rn-map.md` audio section.

Scope:

- Record, stop, play, delete a single audio note per entry.
- `RECORD_AUDIO` runtime permission. No other permission.
- Store under `files/audio/<uuid>.m4a`, one row in `entry_audio`.
- Duration and size captured on stop.
- Export and restore audio through phase 6.
- Delete audio when its entry is deleted.

Java sources: `ui/knowledge/AudioNoteActivity.java`, `audio/AudioRecorder.java`, `AudioPlayer.java`, `RecordingSession.java`, `data/repo/AudioRepository.java`.

Done: record/play/delete works offline; one audio per entry; backup round-trip preserves bytes and duration; no audio leaves app storage.

## Phase 8: waraq-native, PDF reader, OCR

Read: `native-module.md`, `schema.md`.

Scope:

- Create `modules/waraq-native` with Android-only Expo module config.
- Copy the PDF, bidi, layout, selection, cache, and OCR Java classes.
- Add PdfBox and Tesseract dependencies, OCR assets, two ABIs.
- Expose `importPdf`, `extractCover`, `openReader`, `clearOcrCache`.
- Emit `onProgress`, `onHighlightAdded`, `onEntryRequested`, `onReaderClosed`.
- Reader never writes the DB. JS writes progress, highlights, and entries.
- Ship the reader as a standalone Activity first. An embedded View is optional after the standalone flow works.
- Import, cover, reader, search, selection, OCR, and relink screens.

Java sources: all `pdf/*.java`, all `ui/pdf/*.java`, `data/repo/PdfRepository.java`, `assets/ocr/ara.traineddata`, `assets/ocr/eng.traineddata`.

Done: PDF opens offline; page position persists through JS; highlights persist and link to entries; Arabic text order, selection, search, and OCR work; `clearOcrCache(docId)` removes only that document's cache; no direct DB writes in native.

## Phase 9: Port tests

Read: all references needed by failing tests.

Scope:

- Port the Java unit and Robolectric tests to `jest-expo` and React Native Testing Library.
- Keep test vectors and assertions. Do not weaken tests to make them pass.
- Cover Arabic normalization/search, SRS, backup round-trip, schema 3 audio, PDF text and bidi assets that can run in JS. Native-only rendering tests move to phase 10 device checks.
- Run:

```bash
npx tsc --noEmit
npx eslint .
npx jest
```

Java test sources: `app/src/test/java/com/waraq/app/`, especially `SearchTest.java`, `BooksTest.java`, `ReviewTest.java`, `IntegrationReviewTest.java`, `BackupRoundTripTest.java`, `BackupSchema3AudioTest.java`, `BackupTest.java`, `PdfBackupTest.java`, `PdfSearchPipelineTest.java`, `StatsExportTest.java`.

Done: all three commands pass; every ported test uses the same expected values as its Java source.

## Phase 10: End-to-end and release

Read: `stack.md`, `phases.md`.

Scope:

- Maestro flows for first launch, add book, add entry, search, review grade, backup export/import, audio note, PDF open/highlight/OCR.
- Android release build with the two ABIs.
- Confirm no network permission, no `INTERNET`, no iOS folder or config.
- Run `scripts/check-no-ios.sh` again.
- Manual device check of Arabic shaping, RTL, dates with Latin digits, and large PDFs.

Done: Maestro flows pass on a development build; release APK installs and runs offline; script prints OK; no iOS artifact exists.
