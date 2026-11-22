# AGENTS.md

Working notes for anyone (human or agent) changing this repository.

## What this repo is

Waraq is a **Flutter 3.22+ / Dart 3.4+** application: a local-first PDF reader
with Material 3 (Material You) theming. Everything lives in `lib/`, plus
`assets/`, `test/` and `pubspec.yaml`.

**There are no platform folders in the repo.** `android/` and `ios/` are
generated once per checkout with:

```bash
flutter create . --platforms=android,ios --project-name waraq
```

That command never overwrites `lib/`, `test/`, `assets/` or `pubspec.yaml`. After
generating, the folders are normal project files and should be committed.

## Commands

```bash
flutter pub get          # dependencies
flutter analyze          # lints: flutter_lints + strict casts/raw types
flutter test             # pure-Dart unit tests in test/
flutter run              # device/emulator
flutter build apk --release
```

`analysis_options.yaml` enables `strict-casts`, `strict-raw-types`,
`single_quotes` and `unawaited_futures`. Fire-and-forget futures must be wrapped
in `unawaited(...)` — the linter will not accept a bare call in an async body.

## Layout rules

| Layer | May import | Must not import |
| --- | --- | --- |
| `domain/` | `dart:*`, other `domain/` | Flutter, Riverpod, `data/`, `presentation/` |
| `data/` | `domain/`, `dart:*`, `package:pdfx`, storage packages | `presentation/`, Flutter widgets |
| `core/` | Flutter, `package:flutter_riverpod` (providers only) | `presentation/screens`, `data/local` |
| `presentation/` | everything | — |

`data/pdf/pdf_renderer.dart` is the **only** file allowed to import
`package:pdfx`. Swapping engines should touch that file and `pdf_page_cache.dart`
only.

## Conventions

- **Style**: 2-space indent, single quotes, trailing commas, `final` locals,
  explicit types on public API (`final String title`), `const` wherever allowed.
- **Design tokens** live in `lib/core/theme/tokens.dart` (`Gap`, `Radii`,
  `Motion`, `Sizes`). Never hard-code a spacing, radius or duration; add a token
  instead. Colours come from `Theme.of(context).colorScheme` or the
  `WaraqPalette` theme extension — never a literal hex in a widget.
- **Opacity**: use the `withFraction(double)` extension from
  `core/theme/app_theme.dart` (`color.withFraction(0.6)`), not the deprecated
  `withOpacity`. Any file using it must import `app_theme.dart` directly —
  extensions are not transitive.
- **Strings**: every user-visible string comes from `AppStrings.of(context)` in
  `core/l10n/app_strings.dart`, in **both** English and Arabic. No inline text,
  no `intl` codegen.
- **Direction**: use edge-aware APIs (`EdgeInsetsDirectional`,
  `PositionedDirectional`, `AlignmentDirectional`, `start`/`end`). Mirror icons
  (`Icons.arrow_back_rounded` ↔ `arrow_forward_rounded`) when the direction
  flips; `Directionality.of(context) == TextDirection.rtl` is the test.
- **Icons go through `WaraqIcon`** (`core/widgets/waraq_icon.dart`) whenever a
  size or colour is set explicitly. Pass `mirrorInRtl: true` for directional
  glyphs (chevrons, arrows); the framework then flips them in Arabic.
- **Strings** live in `AppStrings` with English + Arabic inline and French/Spanish
  overlays keyed by the English text. A new string falls back to English until it
  is added to `_fr`/`_es`.
- **Shape & motion are theme extensions.** Never hard-code a radius or duration in
  a new widget: read `WaraqShape.of(context)` (`xs/sm/md/lg/xl`, `pill`, `allMd`,
  `topXl`) and `WaraqMotion.of(context)` (`tap/fast/base/slow/theme`, `stagger`,
  `enabled`). The user's Shape/Motion settings then apply everywhere for free.
  `const` corners from `Radii` stay only where a value is genuinely fixed (for
  example a 2 dp progress cap).
- **Fonts**: Rubik carries Latin, Cairo is the `fontFamilyFallback` for Arabic.
  Add weights by instancing the variable original, not by mixing families.
- **Motion**: 120–360 ms, `Motion.emphasized` for transforms,
  `Motion.decelerate` for entrances. Everything animates with `Animated*`
  widgets or implicit `Tween`s — no janky `setState` position changes.
- **Safe areas**: the app shell owns the bottom `NavigationBar` inside a
  `SafeArea`; overlay chrome in the reader offsets by
  `MediaQuery.padding.bottom` explicitly.

## Riverpod

- `flutter_riverpod` 2.x, **no codegen**. `NotifierProvider` /
  `AsyncNotifierProvider` / `Provider.family`.
- Repository providers live in `data/data_providers.dart`; view state lives in
  `presentation/providers/`.
- `main.dart` overrides `sharedPreferencesProvider` and
  `initialSettingsProvider` before `runApp`, so the first frame already has the
  user's theme.
- Reader-scoped state is **not** a provider. `ReaderController` is a plain
  `ChangeNotifier` created by `ReaderScreen`, so it is disposed with the route.

## Reader internals (read before touching scroll math)

`ReaderController` is the single source of truth for: current page, progress,
zoom, scroll mode, page filter, dim level, auto-scroll, chrome visibility and
the scrub preview. The widget tree reads it through `AnimatedBuilder`.

- **Geometry**: `PageLayout` (`domain/entities/page_geometry.dart`) maps page
  sizes to offsets. `contentWidth / aspectRatio` per page, `spacing` between
  pages, `topInset` above the first. Pure and unit-tested — extend the tests in
  `test/page_geometry_test.dart` rather than adding untested maths.
- **Progress** is page-counted: `(pageIndex + fractionWithinPage) / pageCount`,
  so it always agrees with the "12 / 340" indicator.
- **Persistence** is debounced (650 ms) and also flushed in `dispose()`; the
  position stores the page *and* `offsetFraction`.
- **Rendering**: `PdfPageCache` keys bitmaps by `page@widthBucket`, serialises
  renders through `PdfRenderer`'s queue and prefetches ±2 pages around the
  current one. Do not render directly from widgets.
- **Gestures**: `ReaderGestureLayer` uses a raw `Listener` on purpose — pinch
  zoom must not fight the scroll view's gesture arena. Single taps are delayed
  200 ms and cancelled by a second tap; double tap is only reported in vertical
  mode (paged mode zooms inside `ZoomablePage`).

## Release signing

- Key material lives **only** in the `WARAQ_SIGNING_B64` repository secret and in
  `signing/` on a developer machine. `signing/` is git-ignored; never commit a
  `.p12`, `.jks`, `key.properties` or a password.
- `tool/android/install_signing.py` turns that secret into
  `android/keystore/release.p12` + `android/key.properties` and applies
  `tool/android/release-signing.gradle.kts` to the generated host project.
- Missing secret ⇒ debug signing, with a `::warning::` in the log. Don't "fix"
  that by hard-coding a key: forks must build without one.
- The workflow verifies every APK with `apksigner --print-certs` and publishes the
  certificate SHA-256 in the release notes. A build whose fingerprint changes
  silently is a bug, not a detail.
- Changing the key breaks in-place updates for installed APKs; that is a product
  decision, not a CI tweak.

## Testing

`test/` must stay runnable with `flutter test` and no device:

- `page_geometry_test.dart` — layout, scrub, page lookup.
- `formatters_test.dart` — byte/date/speed formatting, greetings, clamping.
- `settings_dto_test.dart` — JSON round-trip, tolerant defaults, clamping.
- `reading_position_test.dart` — percent maths, copy semantics, value equality.

Anything that needs a renderer or a plugin belongs behind an interface in
`data/` so it can be faked, not in `test/` as an integration test.

## Common pitfalls

- `pdfx` returns **raster** pages; there is no text layer. Search/selection is
  intentionally out of scope until a text engine is added.
- `LinearProgressIndicator.value` must be `0..1` or `null`; `.clamp()` returns
  `num`, so follow it with `.toDouble()`.
- Don't call `Navigator`/`ScaffoldMessenger`/`Theme` lookups from `domain/` or
  `data/`; pass plain values in.
- `ReaderCanvas` is only rebuilt for scroll mode, zoom, pinch and filter
  changes. If you add state that changes layout, extend
  `_onControllerChanged`'s comparison or the canvas will go stale.
- Avoid `Opacity` on the page stack; `AnimatedOpacity` on the chrome and
  `RepaintBoundary` per page keep the reader at frame rate.

## Verification before handing work back

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

If the environment has no Flutter SDK, say so explicitly instead of claiming the
build passes — static parsing is not a build.
