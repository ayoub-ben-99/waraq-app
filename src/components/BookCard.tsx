import React from 'react';
import { Image, Pressable, View } from 'react-native';
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
  const { colors, fonts } = useAppTheme();
  const uri = coverUri(book.coverPath);
  return (
    <View
      className="items-center justify-center overflow-hidden rounded-lg border-0"
      style={[
        {
          width: size,
          height: size * 1.4,
          backgroundColor: colors.surfaceContainerHigh,
        },
      ]}
    >
      {uri ? (
        <Image source={{ uri }} className="h-full w-full" resizeMode="cover" />
      ) : (
        <Text variant="headlineSmall" style={{ color: colors.primary, fontFamily: fonts.quote }}>
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
  const { colors, spacing, fonts, radius } = useAppTheme();
  const percent = progressPercent(book);
  if (grid) {
    return (
      <Pressable
        onPress={onPress}
        onLongPress={onLongPress}
        accessibilityRole="button"
        accessibilityLabel={book.title}
        style={({ pressed }) => ({
          flex: 1,
          margin: spacing.s,
          borderRadius: radius.card,
          padding: spacing.m,
          backgroundColor: pressed ? colors.surfaceContainer : colors.surfaceContainerLow,
        })}
      >
        <View className="items-center">
          <BookCover book={book} size={88} />
        </View>
        <Text
          variant="titleSmall"
          numberOfLines={2}
          style={{ color: colors.onSurface, fontFamily: fonts.medium, marginTop: spacing.s, textAlign: 'right' }}
        >
          {book.title}
        </Text>
        <Text variant="bodySmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
          {book.author || bookStatusLabel(book.status)}
        </Text>
        {percent >= 0 ? (
          <View className="mt-1.5">
            <View className="h-1.25 overflow-hidden rounded-full" style={{ backgroundColor: colors.surfaceContainerHigh }}>
              <View className="h-1.25 rounded-full" style={{ width: `${percent}%`, backgroundColor: colors.primary }} />
            </View>
          </View>
        ) : null}
      </Pressable>
    );
  }
  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      accessibilityRole="button"
      accessibilityLabel={book.title}
      style={({ pressed }) => ({
        marginBottom: spacing.s,
        flexDirection: 'row',
        alignItems: 'center',
        borderRadius: radius.card,
        padding: spacing.m,
        backgroundColor: pressed ? colors.surfaceContainer : colors.surfaceContainerLow,
      })}
    >
      <BookCover book={book} />
      <View style={{ flex: 1, marginStart: spacing.m }}>
        <Text variant="titleMedium" numberOfLines={2} style={{ color: colors.onSurface }}>
          {book.title}
        </Text>
        <Text variant="bodySmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant, marginTop: 2 }}>
          {book.author || ''}
        </Text>
        <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, marginTop: 6 }}>
          {bookStatusLabel(book.status)}
          {percent >= 0 ? ` • ${percent}%` : ''}
        </Text>
      </View>
      {book.favorite ? (
        <Text variant="bodyMedium" style={{ color: colors.secondary }}>
          ★
        </Text>
      ) : null}
    </Pressable>
  );
}


