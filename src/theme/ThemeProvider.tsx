// Ported from app/src/main/java/com/waraq/app/util/Prefs.java
import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { useColorScheme } from 'react-native';
import { MD3DarkTheme, MD3LightTheme, configureFonts, type MD3Theme } from 'react-native-paper';
import { md3DarkColors } from './md3Dark';
import { md3LightColors } from './md3Light';
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

const fontConfig = {
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

function makePaperTheme(colors: Palette, dark: boolean): MD3Theme {
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
      onSecondary: colors.onPrimary,
      secondaryContainer: colors.surfaceContainerHigh,
      onSecondaryContainer: colors.onSurface,
      tertiary: colors.tertiary,
      onTertiary: colors.onPrimary,
      background: colors.background,
      onBackground: colors.onSurface,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceVariant: colors.surfaceContainerHigh,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outline,
      error: colors.error,
      onError: colors.onError,
      elevation: {
        ...base.colors.elevation,
        level0: 'transparent',
        level1: colors.surface,
        level2: colors.surface,
        level3: colors.surface,
        level4: colors.surface,
        level5: colors.surface,
      },
    },
  };
}

export function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const system = useColorScheme();
  const [mode, setModeState] = useState<ThemeMode>(() => getThemeMode());
  const dark = mode === 'dark' || (mode === 'system' && system === 'dark');
  const colors = dark ? md3DarkColors : md3LightColors;
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
      paper: makePaperTheme(colors, dark),
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
