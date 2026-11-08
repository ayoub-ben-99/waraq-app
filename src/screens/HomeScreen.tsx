import React from 'react';
import { ScrollView, View } from 'react-native';
import { Button, Card, Text } from 'react-native-paper';
import { ProgressBar, StatCard, SurfaceCard } from '../ui';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { bookSummaryCounts, currentReading, progressPercent } from '../data/repos/books';
import { entryCounts, recentEntries } from '../data/repos/knowledge';
import { reviewCounts } from '../data/repos/review';
import { todayActivity } from '../data/repos/sessions';
import { formatDuration, formatShort } from '../lib/dates';
import { entryDisplayText, entryTypeLabel } from '../lib/labels';
import { t } from '../lib/strings';
import { useRefreshOnFocus } from '../lib/useRefreshOnFocus';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { BookCover } from '../components/BookCard';
import { Loading } from '../components/Layout';
import { ReadingIllustration } from '../components/ReadingIllustration';
import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function HomeScreen() {
  const navigation = useNavigation<Nav>();
  const { colors, spacing, fonts } = useAppTheme();
  const query = useQuery({
    queryKey: ['home'],
    queryFn: async () => {
      const [book, counts, entries, today, reviews, recent] = await Promise.all([
        currentReading(),
        bookSummaryCounts(),
        entryCounts(),
        todayActivity(),
        reviewCounts(),
        recentEntries(3),
      ]);
      return { book, counts, entries, today, reviews, recent };
    },
  });
  useRefreshOnFocus(query.refetch);
  if (query.isLoading) return <Loading />;
  const data = query.data;
  const book = data?.book ?? null;
  const [totalBooks, reading, completed] = data?.counts ?? [0, 0, 0];
  const entriesTotal = data?.entries[0] ?? 0;
  const todayMinutes = data?.today[0] ?? 0;
  const todayPages = data?.today[1] ?? 0;
  const due = data?.reviews[0] ?? 0;
  const recent = data?.recent ?? [];
  const percent = book ? progressPercent(book) : -1;

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: spacing.xl }}
    >
      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginTop: spacing.s }}>
        <MaterialCommunityIcons name="book-open-page-variant-outline" size={26} color={colors.primary} />
        <Text style={{ color: colors.primary, fontSize: 32, fontFamily: 'Amiri', textAlign: 'right' }}>
          {t.homeGreeting}
        </Text>
      </View>
      <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginBottom: spacing.l }}>
        {t.homeSubtitle}
      </Text>

      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginBottom: spacing.s }}>
        <StatCard
          label={t.statsBooks}
          value={String(totalBooks)}
          hint={t.homeLibrarySummary(totalBooks, reading, completed)}
          onPress={() => navigation.navigate('Tabs', { screen: 'Library' })}
        />
        <StatCard
          label={t.statsEntries}
          value={String(entriesTotal)}
          hint={t.knowledge}
          onPress={() => navigation.navigate('Tabs', { screen: 'Knowledge' })}
        />
      </View>

      <SurfaceCard
        style={{ marginBottom: spacing.m }}
        onPress={() => (book ? navigation.navigate('BookDetail', { bookId: book.id }) : navigation.navigate('BookEdit'))}
      >
        <Card.Content>
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.xs }}>
            <MaterialCommunityIcons name="book-arrow-right-outline" size={19} color={colors.primary} />
            <Text variant="labelMedium" style={{ color: colors.primary, textAlign: 'right' }}>{t.homeContinue}</Text>
          </View>
          {book ? (
            <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.m, marginTop: spacing.s }}>
              <BookCover book={book} />
              <View style={{ flex: 1 }}>
                <Text variant="titleMedium" numberOfLines={2} style={{ color: colors.onSurface, textAlign: 'right' }}>
                  {book.title}
                </Text>
                <Text variant="bodySmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
                  {book.author || '—'}
                </Text>
                <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 6 }}>
                  {t.homeLastPosition(book.currentPage)}
                </Text>
                {percent >= 0 ? (
                  <View style={{ marginTop: 8 }}>
                    <ProgressBar value={percent} />
                  </View>
                ) : null}
              </View>
            </View>
          ) : (
            <View style={{ alignItems: 'center', marginTop: spacing.s }}>
              <ReadingIllustration />
              <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'center' }}>
                {t.homeNoReading}
              </Text>
            </View>
          )}
        </Card.Content>
      </SurfaceCard>

      <SurfaceCard style={{ marginBottom: spacing.m }}>
        <Card.Content>
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.xs }}>
            <MaterialCommunityIcons name="chart-timeline-variant" size={19} color={colors.primary} />
            <Text variant="labelMedium" style={{ color: colors.primary, textAlign: 'right' }}>{t.homeToday}</Text>
          </View>
          <Text variant="bodyMedium" style={{ color: colors.onSurface, textAlign: 'right', marginTop: 4 }}>
            {todayMinutes <= 0 && todayPages <= 0
              ? 'لا نشاط مسجّل اليوم'
              : `${formatDuration(todayMinutes)} · ${t.homeTodayPages(todayPages)}`}
          </Text>
          <Button
            mode="text"
            compact
            onPress={() => navigation.navigate('Tabs', { screen: 'Review' })}
            style={{ alignSelf: 'flex-end', marginTop: spacing.xs }}
          >
            {due > 0 ? t.homeDue(due) : t.reviewNoDueTitle}
          </Button>
        </Card.Content>
      </SurfaceCard>

      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginBottom: spacing.m }}>
        <Button mode="contained" icon="book-plus-outline" onPress={() => navigation.navigate('BookEdit')} style={{ flex: 1 }}>
          {t.bookAdd}
        </Button>
        <Button
          mode="outlined"
          icon="note-plus-outline"
          onPress={() => navigation.navigate('EntryEdit', { type: 1 })}
          style={{ flex: 1 }}
        >
          {t.entryNew}
        </Button>
      </View>

      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginBottom: spacing.s }}>
        <MaterialCommunityIcons name="book-multiple-outline" size={21} color={colors.onSurface} />
        <Text variant="titleMedium" style={{ color: colors.onSurface, textAlign: 'right' }}>{t.homeRecent}</Text>
      </View>
      {recent.length === 0 ? (
        <View style={{ alignItems: 'center' }}>
          <ReadingIllustration variant="knowledge" />
          <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'center' }}>
            {t.emptyKnowledgeBody}
          </Text>
        </View>
      ) : (
        recent.map((entry) => {
          const body = entryDisplayText(entry);
          return (
            <SurfaceCard
              key={entry.id}
              style={{ marginBottom: spacing.s }}
              onPress={() => navigation.navigate('EntryEdit', { entryId: entry.id })}
            >
              <Card.Content>
                <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between' }}>
                  <Text variant="labelSmall" style={{ color: colors.primary }}>
                    {entryTypeLabel(entry.type)}
                  </Text>
                  <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
                    {formatShort(entry.date)}
                  </Text>
                </View>
                <Text
                  numberOfLines={2}
                  style={{
                    color: colors.onSurface,
                    textAlign: 'right',
                    marginTop: 4,
                    fontFamily: entry.type === 0 ? fonts.quote : fonts.regular,
                    fontSize: entry.type === 0 ? 20 : 15,
                    lineHeight: entry.type === 0 ? 32 : 24,
                  }}
                >
                  {entry.title?.trim() || body}
                </Text>
              </Card.Content>
            </SurfaceCard>
          );
        })
      )}
    </ScrollView>
  );
}
