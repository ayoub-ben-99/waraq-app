// Ported from app/src/main/java/com/waraq/app/ui/HomeFragment.java
import React from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Text } from 'react-native-paper';
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
      style={{ backgroundColor: colors.bg }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: spacing.xl }}
    >
      <Text style={{ color: colors.accent, fontSize: 32, fontFamily: 'Amiri', textAlign: 'right', marginTop: spacing.s }}>
        {t.homeGreeting}
      </Text>
      <Text variant="bodyMedium" style={{ color: colors.textSecondary, textAlign: 'right', marginBottom: spacing.l }}>
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

      <Card
        style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginBottom: spacing.m }}
        onPress={() => (book ? navigation.navigate('BookDetail', { bookId: book.id }) : navigation.navigate('BookEdit'))}
      >
        <Card.Content>
          <Text variant="labelMedium" style={{ color: colors.accent, textAlign: 'right' }}>
            {t.homeContinue}
          </Text>
          {book ? (
            <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.m, marginTop: spacing.s }}>
              <BookCover book={book} />
              <View style={{ flex: 1 }}>
                <Text variant="titleMedium" numberOfLines={2} style={{ color: colors.textPrimary, textAlign: 'right' }}>
                  {book.title}
                </Text>
                <Text variant="bodySmall" numberOfLines={1} style={{ color: colors.textSecondary, textAlign: 'right' }}>
                  {book.author || '—'}
                </Text>
                <Text variant="labelSmall" style={{ color: colors.textSecondary, textAlign: 'right', marginTop: 6 }}>
                  {t.homeLastPosition(book.currentPage)}
                </Text>
                {percent >= 0 ? (
                  <View style={[styles.track, { backgroundColor: colors.surfaceAlt, marginTop: 8 }]}>
                    <View style={[styles.fill, { width: `${percent}%`, backgroundColor: colors.accent }]} />
                  </View>
                ) : null}
              </View>
            </View>
          ) : (
            <Text variant="bodyMedium" style={{ color: colors.textSecondary, textAlign: 'right', marginTop: spacing.s }}>
              {t.homeNoReading}
            </Text>
          )}
        </Card.Content>
      </Card>

      <Card style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginBottom: spacing.m }}>
        <Card.Content>
          <Text variant="labelMedium" style={{ color: colors.accent, textAlign: 'right' }}>
            {t.homeToday}
          </Text>
          <Text variant="bodyMedium" style={{ color: colors.textPrimary, textAlign: 'right', marginTop: 4 }}>
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
      </Card>

      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginBottom: spacing.m }}>
        <Button mode="contained" onPress={() => navigation.navigate('BookEdit')} style={{ flex: 1 }}>
          {t.bookAdd}
        </Button>
        <Button
          mode="outlined"
          onPress={() => navigation.navigate('EntryEdit', { type: 1 })}
          style={{ flex: 1 }}
        >
          {t.entryNew}
        </Button>
      </View>

      <Text variant="titleMedium" style={{ color: colors.textPrimary, textAlign: 'right', marginBottom: spacing.s }}>
        {t.homeRecent}
      </Text>
      {recent.length === 0 ? (
        <Text variant="bodySmall" style={{ color: colors.textSecondary, textAlign: 'right' }}>
          {t.emptyKnowledgeBody}
        </Text>
      ) : (
        recent.map((entry) => {
          const body = entryDisplayText(entry);
          return (
            <Card
              key={entry.id}
              style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginBottom: spacing.s }}
              onPress={() => navigation.navigate('EntryEdit', { entryId: entry.id })}
            >
              <Card.Content>
                <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between' }}>
                  <Text variant="labelSmall" style={{ color: colors.accent }}>
                    {entryTypeLabel(entry.type)}
                  </Text>
                  <Text variant="labelSmall" style={{ color: colors.textSecondary }}>
                    {formatShort(entry.date)}
                  </Text>
                </View>
                <Text
                  numberOfLines={2}
                  style={{
                    color: colors.textPrimary,
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
            </Card>
          );
        })
      )}
    </ScrollView>
  );
}

function StatCard({
  label,
  value,
  hint,
  onPress,
}: {
  label: string;
  value: string;
  hint: string;
  onPress: () => void;
}) {
  const { colors, spacing } = useAppTheme();
  return (
    <Card
      onPress={onPress}
      style={{ flex: 1, backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth }}
    >
      <Card.Content style={{ alignItems: 'flex-end', paddingVertical: spacing.m }}>
        <Text variant="labelSmall" style={{ color: colors.textSecondary }}>
          {label}
        </Text>
        <Text variant="headlineMedium" style={{ color: colors.textPrimary }}>
          {value}
        </Text>
        <Text variant="labelSmall" numberOfLines={1} style={{ color: colors.textSecondary }}>
          {hint}
        </Text>
      </Card.Content>
    </Card>
  );
}

const styles = StyleSheet.create({
  track: { height: 5, borderRadius: 3, overflow: 'hidden' },
  fill: { height: 5, borderRadius: 3 },
});
