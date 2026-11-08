import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { Card, Text, TextInput } from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { searchAll } from '../data/repos/search';
import { formatShort } from '../lib/dates';
import { entryDisplayText, entryTypeLabel } from '../lib/labels';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import type { KnowledgeEntry } from '../data/db/schema';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function SearchScreen() {
  const navigation = useNavigation<Nav>();
  const { colors, spacing } = useAppTheme();
  const [text, setText] = useState('');
  const query = useQuery({
    queryKey: ['search', text],
    queryFn: () => searchAll(text),
    enabled: text.trim().length >= 2,
  });
  const result = query.data;

  const rows = (items: KnowledgeEntry[], title: string) =>
    items.length ? (
      <View style={{ marginTop: spacing.m }}>
        <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginBottom: spacing.s }}>
          {title} · {items.length}
        </Text>
        {items.map((entry) => (
          <Card
            key={entry.id}
            style={{ backgroundColor: colors.surfaceContainerLow, marginBottom: spacing.s }}
            onPress={() => navigation.navigate('EntryEdit', { entryId: entry.id })}
          >
            <Card.Content>
              <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between' }}>
                <Text variant="labelSmall" style={{ color: colors.primary }}>{entryTypeLabel(entry.type)}</Text>
                <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>{formatShort(entry.date)}</Text>
              </View>
              {entry.title?.trim() ? (
                <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>{entry.title}</Text>
              ) : null}
              <Text numberOfLines={3} style={{ color: colors.onSurface, textAlign: 'right' }}>
                {entryDisplayText(entry)}
              </Text>
            </Card.Content>
          </Card>
        ))}
      </View>
    ) : null;

  return (
    <ScrollView style={{ backgroundColor: colors.background }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }} keyboardShouldPersistTaps="handled">
      <TextInput
        mode="outlined"
        autoFocus
        placeholder={t.searchHint}
        value={text}
        onChangeText={setText}
        right={<TextInput.Icon icon="magnify" />}
        style={{ backgroundColor: colors.surface, textAlign: 'right' }}
        outlineColor={colors.outline}
        activeOutlineColor={colors.primary}
      />
      {text.trim().length < 2 ? (
        <Text style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.m }}>{t.searchTypeWords}</Text>
      ) : null}
      {result ? (
        <Text variant="labelMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.s }}>
          {t.searchResults(result.total)}
        </Text>
      ) : null}

      {result?.books.length ? (
        <View style={{ marginTop: spacing.m }}>
          <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginBottom: spacing.s }}>
            {t.searchBooks} · {result.books.length}
          </Text>
          {result.books.map((book) => (
            <Card
              key={book.id}
              style={{ backgroundColor: colors.surfaceContainerLow, marginBottom: spacing.s }}
              onPress={() => navigation.navigate('BookDetail', { bookId: book.id })}
            >
              <Card.Content>
                <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>{book.title}</Text>
                <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>{book.author || '—'}</Text>
              </Card.Content>
            </Card>
          ))}
        </View>
      ) : null}

      {result ? rows(result.quotes, t.searchQuotes) : null}
      {result ? rows(result.benefits, t.searchBenefits) : null}
      {result ? rows(result.summaries, t.searchSummaries) : null}
      {result ? rows(result.notes, t.searchNotes) : null}

      {result?.tags.length ? (
        <View style={{ marginTop: spacing.m }}>
          <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginBottom: spacing.s }}>
            {t.searchTags} · {result.tags.length}
          </Text>
          <View style={{ flexDirection: 'row-reverse', flexWrap: 'wrap', gap: spacing.s }}>
            {result.tags.map((tag) => (
              <Card
                key={tag.id}
                style={{ backgroundColor: colors.surfaceContainerHigh }}
                onPress={() => navigation.navigate('Tabs', { screen: 'Knowledge', params: { tag: tag.name } })}
              >
                <Card.Content style={{ paddingVertical: 6, paddingHorizontal: 10 }}>
                  <Text style={{ color: colors.onSurface }}>#{tag.name}</Text>
                </Card.Content>
              </Card>
            ))}
          </View>
        </View>
      ) : null}
    </ScrollView>
  );
}
