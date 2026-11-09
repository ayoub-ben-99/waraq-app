import React from 'react';
import { Card, Text } from 'react-native-paper';
import { useAppTheme } from '../theme/ThemeProvider';

export function StatCard({
    label,
    value,
    hint,
    onPress,
}: {
    label: string;
    value: string;
    hint: string;
    onPress: () => void;
}) {
    const { colors, spacing, radius } = useAppTheme();

    return (
        <Card mode="contained" className='flex-1' onPress={onPress} style={{ flex: 1, overflow: 'hidden', borderRadius: radius.card, backgroundColor: colors.secondaryContainer }}>
            <Card.Content style={{ minHeight: 96, alignItems: 'flex-end', justifyContent: 'center', paddingHorizontal: spacing.m, paddingVertical: spacing.m }}>
                <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
                    {label}
                </Text>
                <Text variant="headlineMedium" style={{ color: colors.onSurface }}>
                    {value}
                </Text>
                <Text variant="labelSmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant }}>
                    {hint}
                </Text>
            </Card.Content>
        </Card>
    );
}
