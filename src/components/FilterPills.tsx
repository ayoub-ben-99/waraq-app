// Ported from app/src/main/java/com/waraq/app/ui/FilterPill.java
import React from 'react';
import { ScrollView, StyleSheet, TouchableOpacity } from 'react-native';
import { Text } from 'react-native-paper';
import { useAppTheme } from '../theme/ThemeProvider';

export type FilterOption<T extends string | number> = { value: T; label: string };

export function FilterPills<T extends string | number>({
  options,
  value,
  onChange,
  scroll = true,
}: {
  options: FilterOption<T>[];
  value: T;
  onChange: (value: T) => void;
  scroll?: boolean;
}) {
  const { colors } = useAppTheme();
  const content = (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={{ gap: 8, paddingVertical: 4, flexDirection: 'row-reverse' }}
      scrollEnabled={scroll}
    >
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <TouchableOpacity
            key={String(option.value)}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(option.value)}
            style={[
              styles.pill,
              {
                backgroundColor: selected ? colors.accent : colors.surfaceAlt,
                borderColor: selected ? colors.accent : colors.outline,
              },
            ]}
          >
            <Text
              variant="labelMedium"
              style={{ color: selected ? colors.onAccent : colors.textSecondary }}
            >
              {option.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </ScrollView>
  );
  return content;
}

const styles = StyleSheet.create({
  pill: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
  },
});
