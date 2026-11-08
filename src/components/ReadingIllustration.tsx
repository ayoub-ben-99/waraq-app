import React from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Circle, G, Line, Path, Rect } from 'react-native-svg';
import { useAppTheme } from '../theme/ThemeProvider';

export function ReadingIllustration({ variant = 'reading' }: { variant?: 'reading' | 'knowledge' }) {
  const { colors } = useAppTheme();
  const accent = colors.primary
  const onAccent = variant === 'knowledge' ? colors.surface : colors.onPrimary;
  const line = colors.outlineVariant;

  return (
    <View style={styles.container} pointerEvents="none">
      <Svg width={180} height={118} viewBox="0 0 180 118" accessible accessibilityLabel="رسم توضيحي للقراءة">
        <Circle cx="90" cy="60" r="48" fill={colors.secondaryContainer} />
        <Path d="M45 79c13-8 27-8 45 1V42c-15-8-30-8-45 0v37Z" fill={"transparent"} stroke={accent} strokeWidth="3" strokeLinejoin="round" />
        <Path d="M135 79c-13-8-27-8-45 1V42c15-8 30-8 45 0v37Z" fill={"transparent"} stroke={accent} strokeWidth="3" strokeLinejoin="round" />
        <Line x1="90" y1="42" x2="90" y2="80" stroke={accent} strokeWidth="3" />
        <Line x1="55" y1="53" x2="79" y2="58" stroke={accent} strokeWidth="2" strokeLinecap="round" />
        <Line x1="55" y1="62" x2="79" y2="67" stroke={accent} strokeWidth="2" strokeLinecap="round" />
        <Line x1="101" y1="58" x2="125" y2="53" stroke={accent} strokeWidth="2" strokeLinecap="round" />
        <Line x1="101" y1="67" x2="125" y2="62" stroke={accent} strokeWidth="2" strokeLinecap="round" />
        <G rotation={variant === 'knowledge' ? '-10' : '8'} origin="139,29">
          <Rect x="128" y="18" width="22" height="28" rx="4" fill={accent} opacity="0.9" />
          <Line x1="134" y1="27" x2="144" y2="27" stroke={onAccent} strokeWidth="2" strokeLinecap="round" />
          <Line x1="134" y1="34" x2="141" y2="34" stroke={onAccent} strokeWidth="2" strokeLinecap="round" />
        </G>
        <Circle cx="42" cy="28" r="5" fill={colors.secondary} opacity="0.8" />
        <Circle cx="31" cy="42" r="3" fill={accent} opacity="0.7" />
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { alignItems: 'center', height: 118 },
});
