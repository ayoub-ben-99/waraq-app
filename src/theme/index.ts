// Ported from app/src/main/res/values/themes.xml
import {
  MD3DarkTheme,
  MD3LightTheme,
  configureFonts,
  type MD3Theme,
} from 'react-native-paper';
import { darkColors, fonts, lightColors, radius, spacing } from './tokens';

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
  default: { fontFamily: fonts.regular, fontWeight: '400' as const },
};

const makeTheme = (dark: boolean): MD3Theme => {
  const colors = dark ? darkColors : lightColors;
  const base = dark ? MD3DarkTheme : MD3LightTheme;
  return {
    ...base,
    roundness: radius.control,
    fonts: configureFonts({ config: fontConfig }),
    colors: {
      ...base.colors,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      primaryContainer: colors.accentContainer,
      onPrimaryContainer: colors.onAccentContainer,
      secondary: colors.gold,
      onSecondary: colors.onAccent,
      secondaryContainer: colors.surfaceAlt,
      onSecondaryContainer: colors.textPrimary,
      tertiary: colors.accentVariant,
      background: colors.bg,
      onBackground: colors.textPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      surfaceVariant: colors.surfaceAlt,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.outline,
      outlineVariant: colors.outline,
      error: colors.danger,
      onError: colors.onDanger,
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
};

export const lightTheme = makeTheme(false);
export const darkTheme = makeTheme(true);
export { fonts, lightColors, darkColors, spacing, radius };
export type AppColors = typeof lightColors;
