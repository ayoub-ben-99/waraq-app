# Architecture

Waraq is split into four layers with a strict one-way dependency rule:
`presentation → data → domain`, and `core` shared by everything below
presentation. Nothing in `domain` knows that Flutter exists.

```
┌────────────────────────────────────────────────────────────────────┐
│ presentation/                                                      │
│   screens · shell · widgets · reader/ (controller + canvas + chrome)│
│   providers/ (settings, library, bookmarks)                        │
└───────────────▲──────────────────────────────┬─────────────────────┘
                │ watches                      │ calls
┌───────────────┴──────────────────────────────▼─────────────────────┐
│ data/                                                              │
│   local/ (files + SharedPreferences)  models/ (JSON)  pdf/ (pdfx)   │
└───────────────▲──────────────────────────────┬─────────────────────┘
                │ implements                   │ returns
┌───────────────┴──────────────────────────────▼─────────────────────┐
│ domain/                                                            │
│   entities/ (PdfDocument, ReadingPosition, Bookmark, settings)      │
│   repositories/ (abstract contracts)                               │
│   entities/page_geometry.dart — pure layout maths                  │
└────────────────────────────────────────────────────────────────────┘
```

## Boot sequence

1. `main()` awaits `SharedPreferences`, loads `AppSettings` **before**
   `runApp`, and overrides `sharedPreferencesProvider` +
   `initialSettingsProvider`. The first frame therefore already has the right
   theme and language — no flash of light mode on an AMOLED launch.
2. `WaraqApp` wraps `MaterialApp` in `DynamicColorBuilder`. When a wallpaper
   palette exists and the user allows dynamic colour, that `ColorScheme` is used
   verbatim; otherwise `ColorScheme.fromSeed` runs over the chosen accent seed.
   `themeAnimationDuration: Motion.theme` cross-fades the whole palette.
3. `AppShell` shows Home / Library / Settings in an `IndexedStack`, so each tab
   keeps its scroll position, above an M3 `NavigationBar` inside a `SafeArea`.
4. `documentsProvider` (an `AsyncNotifier`) seeds the bundled sample document on
   first run and then lists the library index.

## State ownership

| State | Owner | Lifetime |
| --- | --- | --- |
| Settings (theme, language, reader defaults) | `settingsProvider` | app |
| Library index | `documentsProvider` | app |
| Reading positions | `positionsProvider` | app |
| Bookmarks | `bookmarksProvider` + `documentBookmarksProvider(id)` | app |
| Scroll offsets, zoom, auto-scroll, chrome visibility, scrub preview | `ReaderController` | reader route |

`ReaderController` is a `ChangeNotifier`, not a provider, for three reasons:
it owns `ScrollController`/`PageController`/`Ticker` which want a route-scoped
`TickerProvider`; it must be disposed in lock-step with the PDF renderer; and
keeping it plain Dart makes the scroll mathematics unit-testable without a
widget tree.

## Reader lifecycle

```
openReader(context, ref, document)
  └─ push ReaderRoute (fade + scale, 260 ms)
       └─ ReaderScreen.initState → PdfRenderer.open(filePath, onProgress)
            ├─ measures every page once (PageSize list), yielding to the frame
            │   loop every 12 pages so the progress UI stays alive
            ├─ reads positionsProvider.future for the resume point
            └─ builds ReaderController(document, renderer, cache, settings…)
  └─ ReaderCanvas post-frame → controller.restoreInitialPosition()
  └─ on pop: positionsProvider.refresh()  (documents update via markOpened)
```

`ReaderScreen` also owns the immersive `SystemChrome` toggling: whenever
`controller.chromeVisible` flips it switches between `edgeToEdge` and
`immersiveSticky`, and restores `edgeToEdge` on dispose.

## Geometry and progress

`PageLayout` turns a list of intrinsic `PageSize`s into exact offsets:

```
top(n) = Σ (contentWidth / aspect(i) + spacing)     for i < n
extent = top(last) + height(last)
pageIndexForOffset(offset)   → binary search over top()
fractionWithinPage(i, off)   → (off − top(i)) / height(i)
```

The scroll view adds `topInset` above the first page, which the controller
subtracts before asking the layout. Because the maths is exact, three things
that usually drift stay in sync:

- **scrubbing** (`fraction → page = round(fraction × (n−1)) + 1`),
- **jump-to-page** (`offset = topInset + top(page) + fraction × height`),
- **progress** (`(pageIndex + fractionWithinPage) / pageCount`).

Resuming restores both the page and `offsetFraction`, so a document reopens
mid-page rather than at the top of it.

## Rendering pipeline

```
ReaderCanvas            ListView.builder / PageView.builder
   └─ PdfPageView       requests (pageIndex, width × devicePixelRatio)
        └─ PdfPageCache LRU keyed by `page@widthBucket` (96 px buckets)
             └─ PdfRenderer  serialised queue → pdfx → PNG bytes
```

- Renders are **serialised** inside `PdfRenderer` because the Android backend
  allows one open page per document at a time; the queue keeps interleaved
  requests correct instead of racing.
- The cache keeps 6 bitmaps (48 for the thumbnail grid) and prefetches ±2 pages
  around the current one, so normal scrolling hits memory.
- **Width bucketing** stops pinch gestures from queueing a dozen near-identical
  renders: a 3 px change reuses the same bitmap.
- Each page sits in a `RepaintBoundary` behind a rounded, bordered surface, so
  loading neighbours never repaints the page you are reading.

## Persistence

All storage is `SharedPreferences` plus the app support directory. Keys are
versioned (`waraq.*.v2`) so a migration can read the old shape:

| Key | Payload |
| --- | --- |
| `waraq.settings.v2` | `AppSettings` JSON (theme, dynamic colour, accent, language, reader defaults) |
| `waraq.documents.v2` | index of `PdfDocument` records |
| `waraq.positions.v2` | `documentId → {page, progress, offsetFraction, updatedAt}` |
| `waraq.bookmarks.v2` | list of `{id, documentId, page, createdAt}` |
| `waraq.sample-seeded.v2` | guard so the sample is imported once |

Imported PDFs, kept under `<app support>/library/<id>.pdf`, are copied in so the
library survives the original file moving; thumbnails sit beside them. Decoding
is tolerant by design — unknown enums, wrong types and out-of-range numbers fall
back to defaults (`data/models/json_utils.dart`) rather than throwing away the
user's settings.

## Theming

`WaraqPalette` is a `ThemeExtension` holding the handful of tones Material 3
does not name: page surface, page shadow, chrome surface/border, reader
backdrop, immersive hairline. `WaraqTheme.lightTheme/darkTheme` build the
`ThemeData` (typography scale, navigation bar, sliders, sheets, chips) from the
resolved `ColorScheme`, and AMOLED simply swaps surfaces to `#000000` while
keeping the same accents.

## Performance notes

- Chrome animates with `AnimatedSlide`/`AnimatedOpacity`; the page stack is
  never inside an `Opacity`.
- The reader only repaints chrome on controller notifications; the canvas
  rebuilds for scroll mode, zoom, pinch and filter changes only.
- Auto-scroll advances with `ScrollPosition.jumpTo` from a `Ticker`, which is
  cheaper than an animation controller and stops dead on touch.
- `Reveal` staggers list entrances once per item, not per rebuild, so recycled
  rows do not re-animate.
