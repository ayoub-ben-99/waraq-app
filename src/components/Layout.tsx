// Ported from app/src/main/java/com/waraq/app/ui/Ui.java
import React from 'react';
import { StyleSheet, View, type ViewStyle } from 'react-native';
import { ActivityIndicator, Text } from 'react-native-paper';
import { shape, useAppTheme } from '../theme/ThemeProvider';

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
  const { colors, spacing, shape } = useAppTheme();
  return (
    <View style={[styles.empty, { padding: spacing.l, backgroundColor: colors.surface, borderColor: colors.outline }, style]}>
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
  const { colors, spacing, shape } = useAppTheme();
  return (
    <View style={styles.loading}>
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
  const { colors, spacing, shape } = useAppTheme();
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
  return <View style={{ height: StyleSheet.hairlineWidth, backgroundColor: colors.outline }} />;
}

export function Card({ children, style }: { children: React.ReactNode; style?: ViewStyle }) {
  const { colors } = useAppTheme();
  return (
    <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.outline }, style]}>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  empty: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: shape.s16,
    alignItems: 'center',
    marginVertical: 12,
  },
  loading: { paddingVertical: 32, alignItems: 'center' },
  card: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: shape.s16,
    padding: 16,
  },
});
