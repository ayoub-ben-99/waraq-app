<p align="center">
  <img src="./assets/readme-cover.png" alt="Waraq app cover" width="1600" />
</p>

<h1 align="center">وَرَق &nbsp;|&nbsp; Waraq</h1>

<p align="center">
  offline reading library and knowledge notebook. Organize books, save highlights, review with spaced repetition, attach audio notes, and read PDFs. No account, no sync. Currently in beta.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-beta-orange?style=for-the-badge" alt="Beta" />
  <img src="https://img.shields.io/badge/Expo-000020?style=for-the-badge&logo=expo&logoColor=white" alt="Expo" />
  <img src="https://img.shields.io/badge/React_Native-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" alt="React Native" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
</p>

---

## Overview

Waraq is an offline-first personal library. You import books, capture highlights and notes, attach audio, and review saved knowledge with spaced repetition. All data stays on your device.

The interface is Arabic-first with full RTL support. Targets: Android.

Waraq is in beta. Expect changes, and report issues on the [Issues](../../issues) page.

## Features

<table>
  <tr>
    <td width="48" align="center"><img src="https://api.iconify.design/lucide/library-big.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>Book library</b><br/>Searchable grid and list views.</td>
  </tr>
  <tr>
    <td align="center"><img src="https://api.iconify.design/lucide/brain.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>Knowledge entries</b><br/>Tags, summaries, and review scheduling with spaced repetition.</td>
  </tr>
  <tr>
    <td align="center"><img src="https://api.iconify.design/lucide/file-text.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>PDF reader</b><br/>Import and read PDFs on native Android.</td>
  </tr>
  <tr>
    <td align="center"><img src="https://api.iconify.design/lucide/mic.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>Audio notes</b><br/>Record and attach audio to any knowledge entry.</td>
  </tr>
  <tr>
    <td align="center"><img src="https://api.iconify.design/lucide/database.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>Local storage</b><br/>SQLite persistence with backup and restore.</td>
  </tr>
  <tr>
    <td align="center"><img src="https://api.iconify.design/lucide/shield-check.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>Private by design</b><br/>No account and no sync requirement.</td>
  </tr>
  <tr>
    <td align="center"><img src="https://api.iconify.design/lucide/languages.svg?color=%23888888" width="24" height="24" alt="" /></td>
    <td><b>Arabic and RTL</b><br/>Custom fonts and theme tokens.</td>
  </tr>
</table>

## Download

Get the latest Android APK from the [Releases](../../releases) page.

## Getting Started

### Prerequisites

- Node.js (compatible LTS version)
- Android Studio or a physical Android device (for native builds)

### Install and run

```bash
npm install
npm run start
```

Open the app from the Expo development server on a connected device or emulator.

### Native Android build

```bash
npm run android
```

### Web

```bash
npx expo start --web
```

## Development Commands

| Command | Description |
| --- | --- |
| `npm run start` | Start the Expo development server |
| `npm run android` | Build, install, and launch on Android |
| `npm run typecheck` | Run the strict TypeScript check |

No test or lint scripts are configured yet. Run `npm run typecheck` and verify affected flows manually before you submit changes.

## Project Layout

```text
src/
  screens/            Application screens
  components/         Reusable UI components
  ui/                 UI primitives
  data/               SQLite schema, migrations, repositories
  features/           PDF, audio, and backup integrations
  theme/              Design tokens and theme provider
modules/
  waraq-native/       Android native PDF and OCR module
assets/               Icons, splash artwork, fonts
```

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Expo, React Native |
| Language | TypeScript (strict) |
| Storage | SQLite |
| Native | Custom Android module (PDF, OCR) |
| Platforms | Android, Web |
