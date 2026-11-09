import React from 'react';
import type { StyleProp, ViewStyle } from 'react-native';
import { Card } from 'react-native-paper';
import { useAppTheme } from '../theme/ThemeProvider';

export function SurfaceCard({
    style,
    children,
    ...props
}: { style?: StyleProp<ViewStyle>; children?: React.ReactNode } & Record<string, any>) {
    const { colors, radius } = useAppTheme();

    return (
        <Card
            {...props}
            mode="contained"
            style={[{ overflow: 'hidden', borderRadius: radius.card, backgroundColor: "transparent", shadowColor: "transparent" }, style]}
        >
            {children}
        </Card>
    );
}
