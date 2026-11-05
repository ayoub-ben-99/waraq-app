import { themeFromSourceColor, argbFromHex, hexFromArgb } from '@material/material-color-utilities';
import { writeFileSync } from 'fs';
import { dirname, resolve } from 'path';

// Primary seed colour – replace with the desired primary colour.
const PRIMARY_COLOR = '#2F6B5E';

function generate(): void {
  const primaryArgb = argbFromHex(PRIMARY_COLOR);
  const theme = themeFromSourceColor(primaryArgb);

  // Helper to convert a map of ARGB values to hex strings
  const mapToHex = (source: Record<string, number>) => {
    const out: Record<string, string> = {};
    for (const [k, v] of Object.entries(source)) {
      out[k] = hexFromArgb(v);
    }
    return out;
  };

  // Light and dark schemes
  const light = mapToHex(theme.schemes.light.toJSON());
  const dark = mapToHex(theme.schemes.dark.toJSON());

  // Surface container levels – neutral palette tones
  const neutral = theme.palettes.neutral.tone;
  const lightContainers = {
    surfaceContainerLowest: hexFromArgb(theme.palettes.neutral.tone(98)),
    surfaceContainerLow: hexFromArgb(theme.palettes.neutral.tone(96)),
    surfaceContainer: hexFromArgb(theme.palettes.neutral.tone(94)),
    surfaceContainerHigh: hexFromArgb(theme.palettes.neutral.tone(92)),
    surfaceContainerHighest: hexFromArgb(theme.palettes.neutral.tone(90)),
  };
  const darkContainers = {
    surfaceContainerLowest: hexFromArgb(theme.palettes.neutral.tone(6)),
    surfaceContainerLow: hexFromArgb(theme.palettes.neutral.tone(10)),
    surfaceContainer: hexFromArgb(theme.palettes.neutral.tone(12)),
    surfaceContainerHigh: hexFromArgb(theme.palettes.neutral.tone(17)),
    surfaceContainerHighest: hexFromArgb(theme.palettes.neutral.tone(22)),
  };

  const write = (name: string, scheme: Record<string, string>, containers: Record<string, string>) => {
    const lines = ['// GENERATED – DO NOT EDIT MANUALLY', `export const ${name} = {`];
    const keys = [
      'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
      'secondary', 'onSecondary', 'secondaryContainer', 'onSecondaryContainer',
      'tertiary', 'onTertiary', 'tertiaryContainer', 'onTertiaryContainer',
      'error', 'onError', 'errorContainer', 'onErrorContainer',
      'background', 'onBackground',
      'surface', 'onSurface',
      'surfaceVariant', 'onSurfaceVariant',
      'outline', 'outlineVariant',
      'inverseSurface', 'inverseOnSurface', 'inversePrimary',
      'shadow', 'scrim',
    ];
    for (const k of keys) {
      if (scheme[k]) lines.push(`  ${k}: '${scheme[k]}',`);
    }
    // Add containers
    for (const [k, v] of Object.entries(containers)) {
      lines.push(`  ${k}: '${v}',`);
    }
    lines.push('} as const;');
    const content = lines.join('\n') + '\n';
    const outPath = resolve(dirname(__dirname), `src/theme/${name}.ts`);
    writeFileSync(outPath, content, 'utf8');
    console.log(`Wrote ${outPath}`);
  };

  write('md3LightColors', light, lightContainers);
  write('md3DarkColors', dark, darkContainers);
}

generate();
