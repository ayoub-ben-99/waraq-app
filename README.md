<p align="center">
  <img src="./assets/readme-cover.png" alt="غلاف تطبيق وَرَق" width="1600" />
</p>

<p align="center">
  تطبيق عربي أولًا لإدارة الكتب، حفظ الفوائد، ومراجعة المعرفة — دون حساب أو مزامنة.
</p>

وَرَق is an offline-first personal reading library and knowledge notebook. It helps you organize books, capture highlights and notes, review saved knowledge with spaced repetition, attach audio notes, and read imported PDFs. The app is Arabic-first and currently targets Android and web.

## Features

- Book library with searchable grid and list views
- Personal knowledge entries with tags, summaries, and review scheduling
- PDF importing and reading on native Android
- Audio notes recorded and attached to knowledge entries
- Local SQLite persistence, backup/restore, and no account or sync requirement
- Arabic/RTL interface with custom fonts and theme tokens

## Getting Started

Install a compatible Node.js version, then install dependencies from the repository root:

```bash
npm install
npm run start
```

Use the Expo development server to open the app on a connected Android device or emulator. For a native Android build, run:

```bash
npm run android
```

To launch the web target, run `npx expo start --web`.

## Development Commands

```bash
npm run typecheck   # strict TypeScript check
npm run start       # Expo development server
npm run android     # build, install, and launch Android
```

There is currently no configured test or lint script. Run `npm run typecheck` and manually verify affected flows before submitting changes.

## Project Layout

- `src/screens/` — application screens
- `src/components/`, `src/ui/` — reusable UI
- `src/data/` — SQLite schema, migrations, and repositories
- `src/features/` — PDF, audio, and backup integrations
- `src/theme/` — design tokens and theme provider
- `modules/waraq-native/` — Android native PDF/OCR module
- `assets/` — icons, splash artwork, and fonts
