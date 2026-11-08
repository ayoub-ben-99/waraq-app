import { createPaperTheme } from './ThemeProvider';
import { md3DarkColors as darkColors, md3LightColors as lightColors } from './md3Colors';
import { fonts, radius, spacing } from './tokens';

export const lightTheme = createPaperTheme(lightColors, false);
export const darkTheme = createPaperTheme(darkColors, true);
export { fonts, lightColors, darkColors, spacing, radius };
export type AppColors = typeof lightColors;
