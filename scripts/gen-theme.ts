import { themeFromSourceColor, argbFromHex, hexFromArgb } from '@material/material-color-utilities';
import { writeFileSync } from 'fs';
import { dirname, resolve } from 'path';

const brandColors = {
  sand: '#E4DCC3',
  sage: '#A7C8A0',
  cream: '#F5EFDF',
  forest: '#275241',
} as const;

const PRIMARY_COLOR = brandColors.forest;

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

  Object.assign(light, {
    primary: brandColors.forest,
    onPrimary: brandColors.cream,
    primaryContainer: brandColors.sage,
    onPrimaryContainer: brandColors.forest,
    secondary: '#6B5E43',
    onSecondary: brandColors.cream,
    secondaryContainer: brandColors.sand,
    onSecondaryContainer: brandColors.forest,
    tertiary: brandColors.sand,
    onTertiary: brandColors.forest,
    tertiaryContainer: brandColors.cream,
    onTertiaryContainer: brandColors.forest,
    background: brandColors.cream,
    onBackground: brandColors.forest,
    surface: brandColors.cream,
    onSurface: brandColors.forest,
    surfaceVariant: brandColors.sand,
    onSurfaceVariant: '#4E5B4D',
    outline: '#7D8875',
    outlineVariant: '#C5BFA9',
    inverseSurface: brandColors.forest,
    inverseOnSurface: brandColors.cream,
    inversePrimary: brandColors.sage,
  });

  Object.assign(dark, {
    primary: brandColors.sage,
    onPrimary: brandColors.forest,
    primaryContainer: brandColors.forest,
    onPrimaryContainer: brandColors.cream,
    secondary: brandColors.sand,
    onSecondary: brandColors.forest,
    secondaryContainer: '#4A493B',
    onSecondaryContainer: brandColors.cream,
    tertiary: brandColors.cream,
    onTertiary: brandColors.forest,
    tertiaryContainer: '#454936',
    onTertiaryContainer: brandColors.cream,
    background: '#202A24',
    onBackground: brandColors.cream,
    surface: '#202A24',
    onSurface: brandColors.cream,
    surfaceVariant: '#45493D',
    onSurfaceVariant: '#D0CBB8',
    outline: '#9A9D87',
    outlineVariant: '#45493D',
    inverseSurface: brandColors.cream,
    inverseOnSurface: '#202A24',
    inversePrimary: brandColors.forest,
  });

  // Surface container levels – neutral palette tones
  const neutral = theme.palettes.neutral.tone;
  const lightContainers = {
    surfaceContainerLowest: '#FBF7EC',
    surfaceContainerLow: '#F8F2E5',
    surfaceContainer: brandColors.cream,
    surfaceContainerHigh: '#EEE7D5',
    surfaceContainerHighest: '#E8E0CB',
  };
  const darkContainers = {
    surfaceContainerLowest: '#19221D',
    surfaceContainerLow: '#202A24',
    surfaceContainer: '#263129',
    surfaceContainerHigh: '#303A31',
    surfaceContainerHighest: '#3A4338',
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
