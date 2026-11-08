import React from 'react';
import { View } from 'react-native';
import { useAppTheme } from '../theme/ThemeProvider';

export function ProgressBar({ value, color }: { value: number; color?: string }) {
    const { colors } = useAppTheme();
    const percent = `${Math.max(0, Math.min(value, 100))}%`;

    return (
        <View style={{ height: 4, overflow: 'hidden', borderRadius: 999, backgroundColor: colors.surfaceContainerHigh }}>
            <View style={{ height: 4, borderRadius: 999, width: percent, backgroundColor: color ?? colors.primary }} />
        </View>
    );
}
