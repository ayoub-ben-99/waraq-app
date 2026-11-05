// Ported from app/src/main/java/com/waraq/app/ui/knowledge/EntryAdapter.java
import React from 'react';
import { StyleSheet, TouchableOpacity, View } from 'react-native';
import { Text } from 'react-native-paper';
import type { KnowledgeEntry } from '../data/db/schema';
import { formatShort } from '../lib/dates';
import { entryDisplayText, entryTypeLabel } from '../lib/labels';
import { shape, useAppTheme } from '../theme/ThemeProvider';

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
  const { colors, spacing, fonts } = useAppTheme();
  const body = entryDisplayText(entry);
  return (
    <TouchableOpacity
      onPress={onPress}
      onLongPress={onLongPress}
      style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.outline }]}
    >
      <View style={styles.top}>
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
      <View style={[styles.meta, { marginTop: spacing.s }]}>
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
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: shape.s16,
    padding: 14,
    marginBottom: 10,
  },
  top: { flexDirection: 'row-reverse', justifyContent: 'space-between', alignItems: 'center' },
  meta: { flexDirection: 'row-reverse', alignItems: 'center', gap: 8, flexWrap: 'wrap' },
});
