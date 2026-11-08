import React from 'react';
import { Pressable, View } from 'react-native';
import { Text } from 'react-native-paper';
import type { KnowledgeEntry } from '../data/db/schema';
import { formatShort } from '../lib/dates';
import { entryDisplayText, entryTypeLabel } from '../lib/labels';
import { useAppTheme } from '../theme/ThemeProvider';

export function EntryCard({
  entry,
  bookName,
  tags,
  hasAudio,
  onPress,
  onLongPress,
}: {
  entry: KnowledgeEntry;
  bookName?: string;
  tags?: string[];
  hasAudio?: boolean;
  onPress: () => void;
  onLongPress?: () => void;
}) {
  const { colors, spacing, fonts, radius } = useAppTheme();
  const body = entryDisplayText(entry);
  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      accessibilityRole="button"
      accessibilityLabel={entry.title?.trim() || body || entryTypeLabel(entry.type)}
      style={({ pressed }) => ({
        marginBottom: spacing.s,
        borderRadius: radius.card,
        padding: spacing.m,
        backgroundColor: pressed ? colors.surfaceContainer : colors.surfaceContainerLow,
      })}
    >
      <View className="flex-row-reverse items-center justify-between">
        <Text variant="labelSmall" style={{ color: colors.primary }}>
          {entryTypeLabel(entry.type)}
        </Text>
        <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
          {formatShort(entry.date)}
        </Text>
      </View>
      {entry.title?.trim() ? (
        <Text variant="titleMedium" numberOfLines={2} style={{ color: colors.onSurface, marginTop: spacing.xs }}>
          {entry.title}
        </Text>
      ) : null}
      {body ? (
        <Text
          numberOfLines={4}
          style={{
            color: colors.onSurface,
            marginTop: spacing.xs,
            fontFamily: entry.type === 0 ? fonts.quote : fonts.regular,
            fontSize: entry.type === 0 ? 20 : 15,
            lineHeight: entry.type === 0 ? 32 : 24,
            textAlign: 'right',
          }}
        >
          {body}
        </Text>
      ) : null}
      <View className="mt-2 flex-row-reverse items-center flex-wrap gap-2">
        {entry.page != null ? (
          <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
            صفحة {entry.page}
          </Text>
        ) : null}
        {bookName ? (
          <Text variant="labelSmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant, flexShrink: 1 }}>
            {bookName}
          </Text>
        ) : null}
        {hasAudio ? <Text style={{ color: colors.primary }}>◉</Text> : null}
        {entry.favorite ? <Text style={{ color: colors.secondary }}>★</Text> : null}
        {tags?.length ? (
          <Text variant="labelSmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant, flexShrink: 1 }}>
            {tags.map((x) => `#${x}`).join(' ')}
          </Text>
        ) : null}
      </View>
    </Pressable>
  );
}
