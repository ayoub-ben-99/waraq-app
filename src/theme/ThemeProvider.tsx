import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useColorScheme } from 'react-native';
import { MD3DarkTheme, MD3LightTheme, configureFonts, type MD3Theme } from 'react-native-paper';
import { Uniwind } from 'uniwind';
import { md3DarkColors } from './md3Colors';
import { md3LightColors } from './md3Colors';
import { fonts, spacing, radius } from './tokens';
import { getThemeMode, setThemeMode as persistThemeMode, type ThemeMode } from '../lib/prefs';

export type Palette = { [K in keyof typeof md3LightColors]: string };

export const shape = { s4: 4, s8: 8, s12: 12, s16: 16, s28: 28 } as const;

type AppTheme = {
  mode: ThemeMode;
  dark: boolean;
  colors: Palette;
  spacing: typeof spacing;
  radius: typeof radius;
  shape: typeof shape;
  fonts: typeof fonts;
  paper: MD3Theme;
  setMode: (mode: ThemeMode) => void;
};

const ThemeContext = createContext<AppTheme | null>(null);

export const fontConfig = {
  displayLarge: { fontFamily: fonts.semibold, fontSize: 54, fontWeight: '600' as const },
  displayMedium: { fontFamily: fonts.semibold, fontSize: 44, fontWeight: '600' as const },
  displaySmall: { fontFamily: fonts.semibold, fontSize: 36, fontWeight: '600' as const },
  headlineLarge: { fontFamily: fonts.semibold, fontSize: 30, fontWeight: '600' as const },
  headlineMedium: { fontFamily: fonts.semibold, fontSize: 26, fontWeight: '600' as const },
  headlineSmall: { fontFamily: fonts.semibold, fontSize: 23, fontWeight: '600' as const },
  titleLarge: { fontFamily: fonts.semibold, fontSize: 21, fontWeight: '600' as const },
  titleMedium: { fontFamily: fonts.medium, fontSize: 17, fontWeight: '500' as const },
  titleSmall: { fontFamily: fonts.medium, fontSize: 15, fontWeight: '500' as const },
  labelLarge: { fontFamily: fonts.medium, fontSize: 15, fontWeight: '500' as const },
  labelMedium: { fontFamily: fonts.medium, fontSize: 13, fontWeight: '500' as const },
  labelSmall: { fontFamily: fonts.medium, fontSize: 11, fontWeight: '500' as const },
  bodyLarge: { fontFamily: fonts.regular, fontSize: 17, fontWeight: '400' as const },
  bodyMedium: { fontFamily: fonts.regular, fontSize: 15, fontWeight: '400' as const },
  bodySmall: { fontFamily: fonts.regular, fontSize: 13, fontWeight: '400' as const },
};

export function createPaperTheme(colors: Palette, dark: boolean): MD3Theme {
  const base = dark ? MD3DarkTheme : MD3LightTheme;
  return {
    ...base,
    roundness: radius.control,
    dark,
    fonts: configureFonts({ config: fontConfig }),
    colors: {
      ...base.colors,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      background: colors.background,
      onBackground: colors.onSurface,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceVariant: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      elevation: {
        ...base.colors.elevation,
        level0: 'transparent',
        level1: colors.surfaceContainerLow,
        level2: colors.surfaceContainer,
        level3: colors.surfaceContainerHigh,
        level4: colors.surfaceContainerHighest,
        level5: colors.surfaceContainerHighest,
      },
    },
  };
}

export function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const system = useColorScheme();
  const [mode, setModeState] = useState<ThemeMode>(() => getThemeMode());
  const dark = mode === 'dark' || (mode === 'system' && system === 'dark');
  const colors = dark ? md3DarkColors : md3LightColors;

  useEffect(() => {
    Uniwind.setTheme(mode);
  }, [mode]);

  const setMode = useCallback((next: ThemeMode) => {
    persistThemeMode(next);
    setModeState(next);
  }, []);
  const value = useMemo<AppTheme>(
    () => ({
      mode,
      dark,
      colors,
      spacing,
      radius,
      shape,
      fonts,
      paper: createPaperTheme(colors, dark),
      setMode,
    }),
    [mode, dark, colors, setMode],
  );
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useAppTheme(): AppTheme {
  const value = useContext(ThemeContext);
  if (!value) throw new Error('useAppTheme outside AppThemeProvider');
  return value;
}
