import React from 'react';
import { Pressable, ScrollView } from 'react-native';
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
  const { colors, radius, spacing } = useAppTheme();
  const content = (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      className="py-1"
      contentContainerClassName="flex-row-reverse gap-2"
      scrollEnabled={scroll}
    >
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <Pressable
            key={String(option.value)}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            onPress={() => onChange(option.value)}
            style={({ pressed }) => ({
              minHeight: 40,
              justifyContent: 'center',
              borderRadius: radius.control,
              paddingHorizontal: spacing.m,
              paddingVertical: spacing.s,
              backgroundColor: selected
                ? colors.primary
                : pressed
                  ? colors.surfaceContainer
                  : colors.surfaceContainerHigh,
            })}
          >
            <Text
              variant="labelMedium"
              style={{ color: selected ? colors.onPrimary : colors.onSurfaceVariant }}
            >
              {option.label}
            </Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
  return content;
}
