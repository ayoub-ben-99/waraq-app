# Repository Guidelines

## Project Structure & Module Organization

This is an Expo React Native application targeting Android and web. `App.tsx` and `index.ts` are the application entry points. Most product code lives under `src/`, organized by responsibility: `screens/` for user-facing views, `components/` and `ui/` for reusable presentation, `navigation/` for routing, `data/` for SQLite schema/migrations/repositories, `features/` for feature-specific integrations, `lib/` for shared utilities, and `theme/` for design tokens and providers. Native functionality is in `modules/waraq-native/`; Android project files are under `android/`. Put images and fonts in `assets/`, build/config helpers in `scripts/` and `plugins/`, and keep generated output such as `dist/` and Android build artifacts out of commits.

## Build, Test, and Development Commands

Run commands from the repository root:

- `npm install` — install the locked dependency set from `package-lock.json`.
- `npm run start` — start the Expo development server.
- `npm run android` — build/install the native Android app and launch it.
- `npm run typecheck` — run strict TypeScript checking without emitting files.
- `npx expo start --web` — run the web target locally when working on `webpack.config.js` or browser behavior.

There is currently no configured unit-test or lint script. For changes that affect native code, verify the relevant Android flow manually and run `npm run typecheck` before opening a PR.

## Coding Style & Naming Conventions

Use TypeScript with strict checking, two-space indentation, semicolons, and double-quoted strings to match the existing code. Name React components and screens in PascalCase, hooks with a `use` prefix, and utilities/repositories in camelCase. Keep data access in `src/data/` rather than issuing database calls directly from screens. Reuse theme tokens and shared UI components instead of introducing one-off colors or spacing values. Preserve Arabic/RTL behavior when changing user-visible text or layout.

## Testing Guidelines

No test framework or coverage threshold is currently configured. At minimum, run `npm run typecheck` and manually exercise the affected screen, navigation path, and persistence flow. If adding tests, keep them close to the feature they cover and use descriptive names such as `reviewScheduler.test.ts`.

## Commit & Pull Request Guidelines

Recent commits use short, imperative, sentence-style subjects (for example, `Fix nested NavigationContainer error`). Keep commits focused and avoid committing generated files. Pull requests should explain the user-visible or architectural change, list validation commands, link the relevant issue when one exists, and include screenshots or a short recording for UI changes. Call out Android/native-module or migration changes explicitly.
