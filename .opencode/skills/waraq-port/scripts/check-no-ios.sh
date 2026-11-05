#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
FAILED=0

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  FAILED=1
}

if [ -d "$ROOT/ios" ]; then
  fail "iOS directory exists: $ROOT/ios"
fi

for file in app.json app.config.js app.config.ts app.config.mjs app.config.cjs; do
  path="$ROOT/$file"
  [ -f "$path" ] || continue
  if grep -Eq '"ios"[[:space:]]*:|'"'"'ios'"'"'[[:space:]]*:|^[[:space:]]*ios[[:space:]]*:' "$path"; then
    fail "iOS configuration found in $file"
  fi
  if grep -Eq '"platforms"[[:space:]]*:[[:space:]]*\[[^]]*"ios"' "$path" \
    || grep -Eq '"platforms"[[:space:]]*:[[:space:]]*\[[^]]*'"'"'ios'"'"'' "$path"; then
    fail "iOS listed in platforms in $file"
  fi
done

if [ -f "$ROOT/package.json" ]; then
  if ! node - "$ROOT/package.json" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
const deps = {
  ...(pkg.dependencies || {}),
  ...(pkg.devDependencies || {}),
  ...(pkg.peerDependencies || {}),
  ...(pkg.optionalDependencies || {}),
};
const prefixes = ['react-native-ios-', '@react-native-ios/'];
const exact = new Set([
  'expo-apple-authentication',
  'react-native-apple-authentication',
  'react-native-safari-view',
  'react-native-health',
  'react-native-healthkit',
  'react-native-homekit',
  'react-native-watch-connectivity',
  'react-native-carplay',
  'react-native-live-activity',
  'react-native-app-clip',
  'react-native-widget-extension',
  'react-native-share-extension',
]);
const bad = Object.keys(deps).filter(
  (name) => prefixes.some((prefix) => name.startsWith(prefix)) || exact.has(name),
);
if (bad.length > 0) {
  console.error(`ERROR: iOS-only packages found: ${bad.join(', ')}`);
  process.exit(1);
}
NODE
  then
    FAILED=1
  fi

  if grep -Eq '"(react-native-ios-[^"]*|@react-native-ios/[^"]*|expo-apple-authentication)"[[:space:]]*:' "$ROOT/package.json"; then
    fail "iOS-only package found in package.json"
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  printf 'FAILED: iOS configuration detected in %s\n' "$ROOT" >&2
  exit 1
fi

printf 'OK: no iOS configuration or iOS-only packages in %s\n' "$ROOT"
