import React from 'react';
import { View } from 'react-native';
import { Text } from 'react-native-paper';
import Svg, { Circle, Line, Path, Polyline } from 'react-native-svg';
import { useAppTheme } from '../theme/ThemeProvider';

export type StatsChartPoint = { label: string; value: number };

const VIEW_WIDTH = 320;
const VIEW_HEIGHT = 168;
const PADDING_X = 16;
const PADDING_TOP = 12;
const PADDING_BOTTOM = 28;

export function StatsChart({ data }: { data: StatsChartPoint[] }) {
  const { colors, spacing } = useAppTheme();
  const maxValue = Math.max(...data.map((point) => point.value), 1);
  const chartWidth = VIEW_WIDTH - PADDING_X * 2;
  const chartHeight = VIEW_HEIGHT - PADDING_TOP - PADDING_BOTTOM;
  const step = chartWidth / Math.max(data.length - 1, 1);
  const points = data.map((point, index) => {
    const x = PADDING_X + index * step;
    const y = PADDING_TOP + chartHeight - (point.value / maxValue) * chartHeight;
    return { ...point, x, y };
  });
  const baseline = PADDING_TOP + chartHeight;
  const linePoints = points.map((point) => `${point.x},${point.y}`).join(' ');
  const areaPath = points.length
    ? `M ${points[0].x} ${baseline} L ${points.map((point) => `${point.x} ${point.y}`).join(' L ')} L ${points[points.length - 1].x} ${baseline} Z`
    : '';

  return (
    <View style={{ marginTop: spacing.m }}>
      <Svg width="100%" height={VIEW_HEIGHT} viewBox={`0 0 ${VIEW_WIDTH} ${VIEW_HEIGHT}`}>
        {[0, 0.5, 1].map((ratio) => {
          const y = PADDING_TOP + chartHeight * ratio;
          return <Line key={ratio} x1={PADDING_X} x2={VIEW_WIDTH - PADDING_X} y1={y} y2={y} stroke={colors.outlineVariant} strokeWidth={1} opacity={0.7} />;
        })}
        {areaPath ? <Path d={areaPath} fill={colors.primaryContainer} opacity={0.38} /> : null}
        {points.length > 1 ? <Polyline points={linePoints} fill="none" stroke={colors.primary} strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" /> : null}
        {points.map((point) => (
          <Circle key={`${point.label}-${point.x}`} cx={point.x} cy={point.y} r={5} fill={colors.surfaceContainerLow} stroke={colors.primary} strokeWidth={3} />
        ))}
      </Svg>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: spacing.s, direction: 'ltr' }}>
        {data.map((point) => (
          <Text key={point.label} variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'center' }}>
            {point.label}
          </Text>
        ))}
      </View>
    </View>
  );
}
