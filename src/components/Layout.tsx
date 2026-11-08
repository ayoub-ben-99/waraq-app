import React from 'react';
import { View, type ViewStyle } from 'react-native';
import { ActivityIndicator, Text } from 'react-native-paper';
import { useAppTheme } from '../theme/ThemeProvider';

export function EmptyState({
  title,
  body,
  action,
  style,
}: {
  title: string;
  body?: string;
  action?: React.ReactNode;
  style?: ViewStyle;
}) {
  const { colors, spacing, radius } = useAppTheme();
  return (
    <View style={[{ marginVertical: spacing.m, alignItems: 'center', borderRadius: radius.card, padding: spacing.l, backgroundColor: colors.surfaceContainerLow }, style]}>
      <Text variant="titleMedium" style={{ color: colors.onSurface, textAlign: 'center' }}>
        {title}
      </Text>
      {body ? (
        <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'center', marginTop: spacing.s }}>
          {body}
        </Text>
      ) : null}
      {action ? <View style={{ marginTop: spacing.m }}>{action}</View> : null}
    </View>
  );
}
export function Loading({ label }: { label?: string }) {
  const { colors, spacing } = useAppTheme();
  return (
    <View className="items-center py-8">
      <ActivityIndicator color={colors.primary} />
      {label ? (
        <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, marginTop: spacing.s }}>
          {label}
        </Text>
      ) : null}
    </View>
  );
}

export function SectionHeader({ title, hint }: { title: string; hint?: string }) {
  const { colors, spacing } = useAppTheme();
  return (
    <View style={{ marginBottom: spacing.s }}>
      <Text variant="titleMedium" style={{ color: colors.onSurface }}>
        {title}
      </Text>
      {hint ? (
        <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, marginTop: 2 }}>
          {hint}
        </Text>
      ) : null}
    </View>
  );
}

export function Divider() {
  const { colors } = useAppTheme();
  return <View className="h-px w-full" style={{ backgroundColor: colors.outlineVariant }} />;
}

export function Card({ children, style }: { children: React.ReactNode; style?: ViewStyle }) {
  const { colors, radius, spacing } = useAppTheme();
  return (
    <View style={[{ borderRadius: radius.card, padding: spacing.m, backgroundColor: colors.surfaceContainerLow }, style]}>
      {children}
    </View>
  );
}

