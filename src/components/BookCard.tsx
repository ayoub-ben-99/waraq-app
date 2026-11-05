// Ported from app/src/main/java/com/waraq/app/ui/library/BookAdapter.java
import React from 'react';
import { Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import { Text } from 'react-native-paper';
import * as FS from 'expo-file-system/legacy';
import type { Book } from '../data/db/schema';
import { progressPercent } from '../data/repos/books';
import { bookStatusLabel } from '../lib/labels';
import { useAppTheme } from '../theme/ThemeProvider';

export function coverUri(coverPath: string | null): string | null {
  if (!coverPath) return null;
  return `${FS.documentDirectory}${coverPath}`;
}

export function BookCover({ book, size = 64 }: { book: Book; size?: number }) {
  const { colors } = useAppTheme();
  const uri = coverUri(book.coverPath);
  return (
    <View
      style={[
        styles.cover,
        {
          width: size,
          height: size * 1.4,
          backgroundColor: colors.surfaceAlt,
          borderColor: colors.outline,
        },
      ]}
    >
      {uri ? (
        <Image source={{ uri }} style={styles.image} resizeMode="cover" />
      ) : (
        <Text variant="headlineSmall" style={{ color: colors.accent, fontFamily: 'Amiri' }}>
          {book.title.trim().charAt(0) || 'و'}
        </Text>
      )}
    </View>
  );
}

export function BookCard({
  book,
  grid,
  onPress,
  onLongPress,
}: {
  book: Book;
  grid?: boolean;
  onPress: () => void;
  onLongPress?: () => void;
}) {
  const { colors, spacing, fonts } = useAppTheme();
  const percent = progressPercent(book);
  if (grid) {
    return (
      <TouchableOpacity
        onPress={onPress}
        onLongPress={onLongPress}
        accessibilityRole="button"
        accessibilityLabel={book.title}
        style={[styles.grid, { backgroundColor: colors.surface, borderColor: colors.outline }]}
      >
        <View style={{ alignItems: 'center' }}>
          <BookCover book={book} size={88} />
        </View>
        <Text
          variant="titleSmall"
          numberOfLines={2}
          style={{ color: colors.textPrimary, fontFamily: fonts.medium, marginTop: spacing.s, textAlign: 'right' }}
        >
          {book.title}
        </Text>
        <Text variant="bodySmall" numberOfLines={1} style={{ color: colors.textSecondary, textAlign: 'right' }}>
          {book.author || bookStatusLabel(book.status)}
        </Text>
        {percent >= 0 ? (
          <View style={{ marginTop: 6 }}>
            <View style={[styles.track, { backgroundColor: colors.surfaceAlt }]}>
              <View style={[styles.fill, { width: `${percent}%`, backgroundColor: colors.accent }]} />
            </View>
          </View>
        ) : null}
      </TouchableOpacity>
    );
  }
  return (
    <TouchableOpacity
      onPress={onPress}
      onLongPress={onLongPress}
      accessibilityRole="button"
      accessibilityLabel={book.title}
      style={[styles.row, { backgroundColor: colors.surface, borderColor: colors.outline }]}
    >
      <BookCover book={book} />
      <View style={{ flex: 1, marginStart: spacing.m }}>
        <Text variant="titleMedium" numberOfLines={2} style={{ color: colors.textPrimary }}>
          {book.title}
        </Text>
        <Text variant="bodySmall" numberOfLines={1} style={{ color: colors.textSecondary, marginTop: 2 }}>
          {book.author || ''}
        </Text>
        <Text variant="labelSmall" style={{ color: colors.textSecondary, marginTop: 6 }}>
          {bookStatusLabel(book.status)}
          {percent >= 0 ? ` • ${percent}%` : ''}
        </Text>
      </View>
      {book.favorite ? (
        <Text variant="bodyMedium" style={{ color: colors.gold }}>
          ★
        </Text>
      ) : null}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  cover: {
    borderRadius: 10,
    borderWidth: StyleSheet.hairlineWidth,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  image: { width: '100%', height: '100%' },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 16,
    padding: 12,
    marginBottom: 10,
  },
  grid: {
    flex: 1,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 16,
    padding: 12,
    margin: 5,
  },
  track: { height: 4, borderRadius: 2, overflow: 'hidden' },
  fill: { height: 4, borderRadius: 2 },
});
