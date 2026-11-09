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

## Design System

The visual language is soft, calm, and based on Material Design 3 (Material You). Build every screen with `react-native-paper` components and the tokens in `src/theme/`. Do not hardcode colors, radii, spacing, or font sizes in screens.

### Softness

- Use rounded shapes from the theme: 8 for chips and small controls, 12 for inputs, 16 for cards, 28 for sheets, dialogs, and large containers.
- Separate surfaces with tonal color (Material 3 surface container levels) instead of hard borders. Use soft, low shadows only where elevation is needed.
- Use generous spacing on an 8dp grid. Keep at least 16dp of horizontal padding and 12 to 16dp of padding inside cards.
- Use muted, low-contrast backgrounds with one clear accent color for primary actions. Keep text contrast at WCAG AA or better.
- Keep touch targets at 48dp minimum.
- Support light and dark themes through theme tokens. Never assume one mode.
- Prefer ripple feedback on Android and avoid harsh borders, flat black, and pure white surfaces.

### Icons

- Use `@expo/vector-icons` (`MaterialCommunityIcons` first, `MaterialIcons` when a glyph is missing). Do not mix other icon sets.
- Put an icon on every element that carries importance or state:
  - Primary and destructive actions (add, save, delete, share).
  - Status messages: success, warning, error, info.
  - Navigation tabs and screen headers.
  - Empty states, with a large soft icon and one line of text.
  - List rows that open a detail view, import/export actions, and settings entries.
- Pair icons with a text label unless the meaning is universal (close, back, search).
- Give every icon-only button an `accessibilityLabel` in Arabic.
- Mirror directional icons (arrows, chevrons, back) in RTL.
- Keep sizes consistent: 20 for inline, 24 for buttons and rows, 48 to 64 for empty states. Tint with theme colors.
- Do not decorate every element. Use icons for emphasis only.

### Motion

Every important element has motion. Motion is smooth, short, and consistent.

Define motion tokens once in `src/theme/motion.ts` and reuse them:

```ts
import { Easing } from "react-native";

export const motion = {
  duration: { short: 150, medium: 280, long: 400 },
  easing: {
    emphasized: Easing.bezier(0.2, 0, 0, 1),
    decelerate: Easing.bezier(0.05, 0.7, 0.1, 1),
    accelerate: Easing.bezier(0.3, 0, 0.8, 0.15),
  },
  spring: { friction: 7, tension: 120 },
  stagger: 40,
  maxStaggered: 8,
};
```

The signature motion of the app:

- **Reveal:** elements fade in and rise 12dp with `decelerate` easing over `medium` duration.
- **Stagger:** list items and cards enter one after another, 40ms apart, for the first 8 items only.
- **Press:** pressable cards and buttons scale to 0.97 with a spring and return on release.
- **Pop:** icons that change state (done, favorite, saved) scale from 0.6 to 1 with a spring.
- **Transitions:** screens use native-stack transitions. Dialogs and sheets use `emphasized` easing.
- **Feedback:** success and error states shake or pulse once, never in a loop.

Rules:

- Build motion as shared components in `src/ui/motion/` (for example `Reveal`, `PressableScale`, `PopIcon`). Do not write ad hoc `Animated` code inside screens.
- Use the built-in `Animated` API with `useNativeDriver: true`. Animate `opacity` and `transform` only. Do not animate `width`, `height`, or `margin`.
- Do not add `react-native-reanimated` or other native animation dependencies without approval, because native changes affect the Android build.
- Flip horizontal slide directions in RTL: multiply the translateX value by `I18nManager.isRTL ? -1 : 1`.
- Respect reduced motion. Check `AccessibilityInfo.isReduceMotionEnabled()` and fall back to a plain fade or no animation.
- Keep animations under 400ms. Never block input while an animation runs.
- In `FlashList` and long lists, animate on first mount only. Do not re-run entry animations when rows are recycled or scrolled.
- Never loop animations on content screens. Looping is allowed for loading indicators only.

## Testing Guidelines

No test framework or coverage threshold is currently configured. At minimum, run `npm run typecheck` and manually exercise the affected screen, navigation path, and persistence flow. For UI changes, also check:

- Light and dark themes.
- RTL layout, mirrored icons, and animation direction.
- Reduced motion on and off.
- Smooth frame rate on a mid-range Android device in a release build.

If adding tests, keep them close to the feature they cover and use descriptive names such as `reviewScheduler.test.ts`.

## Commit & Pull Request Guidelines

Recent commits use short, imperative, sentence-style subjects (for example, `Fix nested NavigationContainer error`). Keep commits focused and avoid committing generated files. Pull requests should explain the user-visible or architectural change, list validation commands, link the relevant issue when one exists, and include screenshots or a short recording for UI changes. Screen recordings are required for any animation change. Call out Android/native-module or migration changes explicitly.