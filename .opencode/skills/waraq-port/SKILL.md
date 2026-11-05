---
name: waraq-port
description: Port the Waraq Java Android app to React Native with Expo SDK 58, Drizzle, and the waraq-native module. Use when porting any Waraq screen, repository, utility, backup/restore flow, PDF reader, OCR feature, or when working on any migration phase of the Waraq app.
---

# Waraq Port

Port Waraq from the Java Android source at `/home/johan/Documents/waraq-github` to the React Native app at `/home/johan/Documents/waraq-rn`. Reproduce existing behavior exactly. Do not redesign or add product features.

## Non-negotiables

- Android only. Never create `ios/`, `app.json.ios`, `app.config` iOS sections, or iOS-only dependencies.
- Development Build only. Never use Expo Go or Expo Go-compatible fallbacks.
- TypeScript strict. No `any` unless the original Java type is genuinely untyped.
- All data stays on device. Add no network calls, analytics, accounts, or cloud sync.
- Request only `RECORD_AUDIO`. Do not add `INTERNET` or storage permissions.
- Arabic UI and RTL everywhere. Use Latin digits in dates, as `Dates` does.
- Port behavior as is. Do not add, remove, or "improve" features.
- Never invent data, test fixtures, defaults, or fallback behavior. Read the Java source.
- Keep PDF, bidi, text-layout, and OCR Java code unchanged inside `waraq-native`.
- Leave a top comment in every ported TS file with the original Java path.
- Do not run tests, lint, or `tsc` before phase 9.

## Workflow

1. Read `references/phases.md` and identify the current phase.
2. Read only the references needed for this phase.
3. Port the phase files. For each file, open the Java source first and copy behavior.
4. Run `scripts/check-no-ios.sh` at the end of phase 1 and phase 10.
5. Commit once at the end of the phase.
6. Print one line: `Phase N: <status>` and stop.

When a source fact is missing, write `Not found` in the reference or ask. Never guess.

## Reference index

| File | Content | Read when |
|---|---|---|
| `references/phases.md` | Ten phases, file scope, done criteria | Start of every session |
| `references/stack.md` | Expo/RN versions, packages, native build config | Phase 1 and dependency changes |
| `references/java-to-rn-map.md` | Every Java class to TS target path and library mapping | Any phase, before porting files |
| `references/schema.md` | Room v3 schema, 13 tables, 20 indexes, enums | Phase 2 and backup work |
| `references/arabic-text.md` | `ArabicText` normalization rules and vectors | Phase 2, search, Arabic UI |
| `references/srs.md` | Review scheduling, intervals, due/overdue rules | Phase 2 and phase 5 |
| `references/backup-format.md` | ZIP layout, manifest, data.json, validation, restore | Phase 6 |
| `references/native-module.md` | `waraq-native` module, Kotlin wrapper, Java assets, API | Phase 8 |
| `scripts/check-no-ios.sh` | Fails on iOS folders, config keys, or packages | Phase 1 and phase 10 |

## Source rules

- The Java source is authoritative. Documentation in the Java repo is stale; ignore its claims when they conflict with code.
- Read the actual class, its repository, and its tests before porting a screen.
- Preserve field names, defaults, nullability, ordering, validation messages, and edge cases.
- Keep Arabic strings in the TS source or a locale file. Do not translate or rewrite them.
- Match existing TypeScript conventions in `waraq-rn` when they exist; otherwise use the paths in `java-to-rn-map.md`.

## Output rules

- One commit per phase, for example `phase 2: port data layer`.
- Do not commit generated build output, `node_modules`, or secrets.
- At the end of a phase, report only the phase line. Do not summarize every file.
