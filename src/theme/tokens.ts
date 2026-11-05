// Ported from app/src/main/res/values/colors.xml, dimens.xml
export const lightColors = {
  bg: '#FAF7F1',
  surface: '#FFFFFF',
  surfaceAlt: '#F1ECE1',
  textPrimary: '#221F1A',
  textSecondary: '#5F594E',
  accent: '#2F6B54',
  accentVariant: '#245542',
  onAccent: '#FFFFFF',
  accentContainer: '#DDEAE2',
  onAccentContainer: '#163326',
  outline: '#DCD5C6',
  danger: '#A33A2E',
  onDanger: '#FFFFFF',
  gold: '#A9812F',
  scrim: '#66000000',
} as const;

export const darkColors = {
  bg: '#101310',
  surface: '#1C211C',
  surfaceAlt: '#262C26',
  textPrimary: '#E8E6DE',
  textSecondary: '#B7B5A8',
  accent: '#7CC3A1',
  accentVariant: '#93D4B4',
  onAccent: '#10261C',
  accentContainer: '#25362C',
  onAccentContainer: '#C9E7D7',
  outline: '#3B443A',
  danger: '#E08A7C',
  onDanger: '#2A1009',
  gold: '#D3B169',
  scrim: '#99000000',
} as const;

export const spacing = { xs: 4, s: 8, m: 16, l: 24, xl: 32 } as const;
export const radius = { card: 16, control: 12 } as const;
export const fonts = {
  regular: 'PlexRegular',
  medium: 'PlexMedium',
  semibold: 'PlexSemiBold',
  quote: 'Amiri',
} as const;

export const shade = (hex: string, amount: number) => {
  const n = parseInt(hex.replace('#', '').slice(0, 6), 16);
  const r = Math.max(0, Math.min(255, (n >> 16) + amount));
  const g = Math.max(0, Math.min(255, ((n >> 8) & 0xff) + amount));
  const b = Math.max(0, Math.min(255, (n & 0xff) + amount));
  return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, '0')}`;
};
