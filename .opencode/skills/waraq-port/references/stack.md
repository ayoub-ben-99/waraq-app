# Stack
Contents: Runtime · Create the project · Build configuration · Install rules · Required packages · Fonts · Android manifest · TypeScript · Commands

Source: `/home/johan/Documents/waraq-github/app/build.gradle`, `app/src/main/res/font/`.
Target: Expo SDK 58 Development Build, Android only.

## Runtime

| Item | Value |
|---|---|
| Expo SDK | 58 |
| React Native | 0.88 |
| Node | 22 LTS |
| JDK | 17 |
| JS engine | Hermes V1 |
| Architecture | New Architecture only |
| compileSdk | 36 |
| targetSdk | 36 |
| minSdk | 24 |
| ABIs | `arm64-v8a`, `armeabi-v7a` |

Source note: the Java app uses compile/target 34. The React Native target above is intentional. Keep `minSdk 24` and the two ABIs to match the source APK.

## Create the project

```bash
npx create-expo-app@latest waraq-rn --template blank-typescript
cd waraq-rn
npx expo install expo-dev-client
```

`app.json` must contain no `ios` key. Never run `expo prebuild` for iOS.

## Build configuration

Install `expo-build-properties` and set:

```json
{
  "expo": {
    "plugins": [
      ["expo-build-properties", {
        "android": {
          "compileSdkVersion": 36,
          "targetSdkVersion": 36,
          "minSdkVersion": 24,
          "buildToolsVersion": "36.0.0",
          "enableProguardInReleaseBuilds": false
        }
      }]
    ]
  }
}
```

Add `expo-dev-client`, `expo-splash-screen`, `expo-localization`, and `expo-font` plugins as needed. Add no iOS plugin configuration.

## Install rules

- Install Expo-managed packages with `npx expo install`.
- Install all other packages with `npm install`.
- Use the latest stable version at install time, then keep the exact lockfile pin.
- Do not use `~` or `^` ranges in `package.json`.
- Do not add a package that is iOS-only.

## Required packages

Expo-managed:

- `expo-font`, `expo-splash-screen`, `expo-localization`
- `expo-sqlite`
- `expo-file-system`, `expo-document-picker`, `expo-sharing`
- `expo-image-picker`, `expo-clipboard`
- `expo-audio`
- `expo-dev-client`

React Native and libraries:

- `@react-navigation/native`, `@react-navigation/bottom-tabs`, `@react-navigation/native-stack`
- `react-native-pager-view`
- `react-native-paper`
- `@shopify/flash-list`
- `react-native-svg`
- `drizzle-orm`, `drizzle-kit`
- `@tanstack/react-query`
- `zustand`
- `react-native-mmkv`
- `react-hook-form`, `zod`
- `date-fns`
- `@react-native-community/datetimepicker`
- `react-native-zip-archive`

Use `java.util.zip` behavior as the compatibility fallback only if `react-native-zip-archive` cannot reproduce the backup format exactly.

Testing:

- `jest-expo`
- `@testing-library/react-native`
- Maestro CLI for end-to-end flows

## Fonts

Source: `app/src/main/res/font/`.

| File | Use |
|---|---|
| `plex_regular.ttf` | Body and most UI |
| `plex_medium.ttf` | Medium emphasis |
| `plex_semibold.ttf` | Headings and buttons |
| `amiri_regular.ttf` | Quote and book text |

Copy these files into `waraq-rn/assets/fonts/` unchanged. Load them with `expo-font`. The Java docs call them assets, but the source stores them in `res/font`; use the actual files, not generated fonts.

## Android manifest

Set `android.permissions` to `["RECORD_AUDIO"]` only. Do not add `INTERNET`, `READ_EXTERNAL_STORAGE`, or `WRITE_EXTERNAL_STORAGE`. Use the Storage Access Framework through `expo-document-picker` for backup import and `expo-sharing` for export.

Set `android.package` to `com.waraq.app`.

## TypeScript

`tsconfig.json` must use `"strict": true`. Enable `noUncheckedIndexedAccess` if the existing project already does. Do not add path aliases that conflict with `waraq-rn` conventions.

## Commands

```bash
npx expo install --check
npx tsc --noEmit
npx eslint .
npx jest
npx expo run:android
```

Run `npx tsc --noEmit`, `npx eslint .`, and `npx jest` only in phase 9, not before.
