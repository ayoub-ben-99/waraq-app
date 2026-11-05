# waraq-native Module
Contents: Module layout · Dependencies · Move list · Hard boundary · API · Events · TS wrapper · Verification

Source: `app/src/main/java/com/waraq/app/pdf/`, `app/src/main/java/com/waraq/app/ui/pdf/`, `app/src/main/assets/ocr/`.
Target: `modules/waraq-native/`.

Android only. `expo-module.config.json` must declare Android only:

```json
{
  "platforms": ["android"],
  "android": { "modules": ["com.waraq.native.WaraqNativeModule"] }
}
```

Porting the Java PDF stack to TypeScript would change rendering and Arabic behavior. Keep it native and expose a thin Kotlin Expo module.

## Module layout

```
modules/waraq-native/
  expo-module.config.json
  android/build.gradle
  android/src/main/AndroidManifest.xml
  android/src/main/assets/ocr/ara.traineddata
  android/src/main/assets/ocr/eng.traineddata
  android/src/main/java/com/waraq/app/pdf/*.java
  android/src/main/java/com/waraq/app/ui/pdf/*.java
  android/src/main/java/com/waraq/native/WaraqNativeModule.kt
  android/src/main/java/com/waraq/native/WaraqReaderActivity.kt
  android/src/main/java/com/waraq/native/WaraqNativeView.kt
  src/WaraqNative.ts
  src/WaraqNative.types.ts
```

The Java engine classes keep their source logic. Only package declarations, imports, and resource references may change. Never rewrite bidi, line layout, OCR, text extraction, or selection logic.

`WaraqNativeModule.kt` is the only new logic. It copies streams, launches the reader, emits events, and clears caches. It does not open the database.

## Dependencies

In `modules/waraq-native/android/build.gradle`:

```gradle
dependencies {
  implementation project(':expo-modules-core')
  implementation 'com.tom-roush:pdfbox-android:2.0.27.0'
  implementation 'cz.adaptech.tesseract4android:tesseract4android:4.8.0'
}
```

Required Android config:

```gradle
android {
  namespace "com.waraq.native"
  compileSdk 36
  defaultConfig {
    minSdk 24
    ndk { abiFilters 'arm64-v8a', 'armeabi-v7a' }
  }
}
```

Use the same two ABIs in `expo-build-properties`. Do not add `x86` or `x86_64`.

If PdfBox requires it, call `PDFBoxResourceLoader.init(context)` once in the module or reader. Tesseract copies `ocr/ara.traineddata` and `ocr/eng.traineddata` into `filesDir/tessdata` and initializes with `ara+eng`, exactly as `TessOcrEngine` does. Do not add another OCR dependency.

## Move list

Copy these unchanged, preserving paths under `com/waraq/app/`:

`pdf/AndroidPdfPageRenderer.java`, `pdf/BidiText.java`, `pdf/CancelFlag.java`, `pdf/OcrCache.java`, `pdf/OcrTextBridge.java`, `pdf/PageCache.java`, `pdf/PdfBoxTextEngine.java`, `pdf/PdfImporter.java`, `pdf/PdfLineLayout.java`, `pdf/PdfLink.java`, `pdf/PdfPageRenderer.java`, `pdf/PdfRenderers.java`, `pdf/PdfRenderSession.java`, `pdf/PdfSearcher.java`, `pdf/PdfSearch.java`, `pdf/PdfSelection.java`, `pdf/PdfTextEngine.java`, `pdf/PdfText.java`, `pdf/PdfTextReader.java`, `pdf/PdfTextSession.java`, `pdf/ReflowText.java`, `pdf/TessOcrEngine.java`, `pdf/VerticalStrip.java`.

Also copy `ui/pdf/PdfIntake.java`, `PdfPageView.java`, `PdfVerticalView.java`, `PdfReaderActivity.java`, `ReaderPrefs.java`.

Copy the OCR models byte-for-byte from `app/src/main/assets/ocr/`.

## Hard boundary

The reader must never write the database.

- Remove repository and DAO calls from the reader shell.
- Replace `savePosition` with `onProgress` and `onReaderClosed` events.
- Replace highlight insert and entry creation with `onHighlightAdded` and `onEntryRequested` events.
- JS reads the DB, passes existing highlights in, and persists every change.
- PDF engine, rendering, bidi, OCR, search, and selection code remain native and unchanged.

The original `PdfReaderActivity` writes through `Waraq.get(...)`. Adapt only those call sites. Do not alter the rendering engine.

## API

```ts
import { NativeModule } from 'expo';

export type ImportedPdf = {
  localPath: string; displayName: string; sourceUri: string | null;
  pageCount: number; sizeBytes: number; sha256: string;
};

export declare class WaraqNativeModule extends NativeModule<WaraqNativeEvents> {
  importPdf(uri: string): Promise<ImportedPdf>;
  extractCover(localPath: string): Promise<string | null>;
  openReader(bookId: number, localPath: string, lastPage: number, highlights: string): Promise<boolean>;
  clearOcrCache(docId: number): Promise<void>;
}
```

`importPdf(uri)`:

- Open the content URI with `ContentResolver`.
- Stream-copy into `filesDir/pdfs/<random>.pdf` with an 8 KiB buffer.
- Reject an empty stream and delete partial files.
- Compute SHA-256, page count, display name, and size.
- Return the app-relative `localPath`, for example `pdfs/<name>.pdf`.
- Do not write a row. JS inserts `pdf_docs` and may insert `books`.

`extractCover(localPath)`:

- Render page 0 to a bitmap, save a cover image under `filesDir/covers/`, and return the app-relative path.
- Return `null` when the file is missing or rendering fails.
- Do not write a row. JS updates `books.coverPath`.

`openReader(bookId, localPath, lastPage, highlights)`:

- Launch `WaraqReaderActivity` with the app context.
- Pass `bookId`, absolute path derived from `filesDir`, `lastPage`, and the highlights JSON string.
- `highlights` is the JSON array of rows already in the DB: `id`, `page`, `rects`, `text`, `color`, `entryId`.
- Ship a standalone Activity first. An embedded `WaraqNativeView` is an optional follow-up; keep the same functions and events.
- Return `true` after launch.

`clearOcrCache(docId)`:

- Delete `filesDir/ocr-cache/<docId>` recursively.
- Delete nothing else. Do not touch PDFs, DB rows, or OCR model assets.

## Events

```ts
export type WaraqNativeEvents = {
  onProgress: (payload: { bookId: number; page: number; offset: number }) => void;
  onHighlightAdded: (payload: {
    bookId: number;
    page: number;
    rects: string;
    text: string;
    color: number;
  }) => void;
  onEntryRequested: (payload: {
    bookId: number;
    page: number;
    text: string;
    entryType: number;
  }) => void;
  onReaderClosed: (payload: { bookId: number; page: number; offset: number }) => void;
};
```

- `onProgress` fires on page change and at a throttled interval while scrolling. It is not written by native.
- `onHighlightAdded` fires when the user finishes a highlight. JS inserts `pdf_highlights` with the current `pdfDocId`; optional `entryId` is set by JS when an entry is created.
- `onEntryRequested` fires when the user asks to create a quote, benefit, summary, question, or opinion from selected text. JS opens `EntryEditScreen` and writes the entry and highlight.
- `onReaderClosed` fires before the Activity finishes. JS persists final `lastPage` and `lastOffset`.

Native keeps the last emitted position in memory so closing without a page change still sends the current value.

## TS wrapper

```ts
import { requireNativeModule, EventSubscription } from 'expo-modules-core';

const native = requireNativeModule('WaraqNative');

export const importPdf = (uri: string) => native.importPdf(uri);
export const extractCover = (localPath: string) => native.extractCover(localPath);
export const openReader = (
  bookId: number,
  localPath: string,
  lastPage: number,
  highlights: string,
) => native.openReader(bookId, localPath, lastPage, highlights);
export const clearOcrCache = (docId: number) => native.clearOcrCache(docId);

export function addReaderListener<K extends keyof WaraqNativeEvents>(
  event: K,
  listener: WaraqNativeEvents[K],
): EventSubscription {
  return native.addListener(event, listener);
}
```

Register a development build, not Expo Go. Run `npx expo run:android` after adding the module.

## Verification

- Build only `arm64-v8a` and `armeabi-v7a`.
- Confirm both `ocr/ara.traineddata` and `ocr/eng.traineddata` are packaged.
- Open a PDF, change pages, add a highlight, request an entry, close.
- Confirm the reader emitted events and wrote nothing directly; JS rows are the only writes.
- Confirm OCR works offline and `clearOcrCache(docId)` removes only that document's cache.
