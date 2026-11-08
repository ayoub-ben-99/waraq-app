import React, { useMemo, useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Text } from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { allBooks } from '../data/repos/books';
import { dueList, grade, postpone } from '../data/repos/review';
import { reviewResults } from '../lib/reviewScheduler';
import { entryDisplayText, entryTypeLabel } from '../lib/labels';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { EmptyState, Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function ReviewSessionScreen() {
  const navigation = useNavigation<Nav>();
  const { colors, spacing, fonts } = useAppTheme();
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [finished, setFinished] = useState(false);
  const [lastInterval, setLastInterval] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);

  const query = useQuery({
    queryKey: ['review-session'],
    queryFn: async () => {
      const [items, books] = await Promise.all([dueList(), allBooks()]);
      return { items, bookNames: new Map(books.map((b) => [b.id, b.title])) };
    },
  });

  const current = useMemo(() => query.data?.items[index] ?? null, [query.data, index]);

  const answer = async (result: number) => {
    if (!current || busy) return;
    setBusy(true);
    try {
      const schedule = await grade(current.item.entryId, result);
      setLastInterval(schedule.intervalDays);
      setRevealed(false);
      if (index + 1 >= (query.data?.items.length ?? 0)) setFinished(true);
      else setIndex((v) => v + 1);
    } catch {
      Alert.alert(t.genericError);
    } finally {
      setBusy(false);
    }
  };

  const snooze = async (days: number) => {
    if (!current || busy) return;
    setBusy(true);
    try {
      await postpone(current.item.entryId, days);
      Alert.alert(t.reviewPostponed);
      if (index + 1 >= (query.data?.items.length ?? 0)) setFinished(true);
      else {
        setIndex((v) => v + 1);
        setRevealed(false);
      }
    } catch {
      Alert.alert(t.genericError);
    } finally {
      setBusy(false);
    }
  };

  if (query.isLoading) return <Loading />;
  if (!query.data?.items.length) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background, padding: spacing.m }}>
        <EmptyState title={t.reviewNoDueTitle} body={t.reviewNoDueBody} action={<Button onPress={() => navigation.goBack()}>{t.back}</Button>} />
      </View>
    );
  }

  if (finished) {
    return (
      <View style={{ flex: 1, backgroundColor: colors.background, padding: spacing.m, justifyContent: 'center' }}>
        <Text variant="headlineSmall" style={{ color: colors.onSurface, textAlign: 'center' }}>{t.reviewFinished}</Text>
        {lastInterval != null ? (
          <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'center', marginTop: spacing.s }}>
            {t.reviewNextDue(lastInterval)}
          </Text>
        ) : null}
        <Button mode="contained" onPress={() => navigation.goBack()} style={{ marginTop: spacing.l }}>
          {t.done}
        </Button>
      </View>
    );
  }

  const entry = current?.entry;
  const title = entry?.title?.trim() || (entry ? entryDisplayText(entry) : '');
  const book = entry?.bookId ? query.data.bookNames.get(entry.bookId) : null;

  return (
    <ScrollView style={{ backgroundColor: colors.background }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}>
      <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between', alignItems: 'center' }}>
        <Text variant="labelMedium" style={{ color: colors.onSurfaceVariant }}>
          {t.reviewCardOf(index + 1, query.data.items.length)}
        </Text>
        <Button compact onPress={() => navigation.goBack()}>{t.close}</Button>
      </View>

      <Card style={{ backgroundColor: colors.surfaceContainerLow, marginTop: spacing.s, minHeight: 320 }}>
        <Card.Content style={{ paddingVertical: spacing.l }}>
          <Text variant="labelSmall" style={{ color: colors.primary, textAlign: 'right' }}>
            {entry ? entryTypeLabel(entry.type) : ''}
            {book ? ` • ${book}` : ''}
          </Text>
          <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.s }}>
            {t.reviewQuestionPrompt}
          </Text>
          <Text
            style={{
              color: colors.onSurface,
              textAlign: 'right',
              marginTop: spacing.m,
              fontFamily: (entry?.type ?? 1) === 0 ? fonts.quote : fonts.regular,
              fontSize: (entry?.type ?? 1) === 0 ? 24 : 18,
              lineHeight: (entry?.type ?? 1) === 0 ? 40 : 30,
            }}
          >
            {revealed ? title : '••••••'}
          </Text>
          {revealed && entry ? (
            <>
              {entry.quoteText && entry.comment ? (
                <Text style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.m, lineHeight: 26 }}>
                  {entry.comment}
                </Text>
              ) : null}
              {entry.page != null ? (
                <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.s }}>
                  {t.entryPageValue(entry.page)}
                </Text>
              ) : null}
            </>
          ) : null}
        </Card.Content>
      </Card>

      {!revealed ? (
        <>
          <Button mode="contained" onPress={() => setRevealed(true)} style={{ marginTop: spacing.m }}>
            {t.reviewReveal}
          </Button>
          <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s }}>
            <Button mode="outlined" onPress={() => snooze(1)} style={{ flex: 1 }}>{t.reviewPostponeDay}</Button>
            <Button mode="outlined" onPress={() => snooze(3)} style={{ flex: 1 }}>{t.reviewPostponeThree}</Button>
            <Button mode="outlined" onPress={() => snooze(7)} style={{ flex: 1 }}>{t.reviewPostponeWeek}</Button>
          </View>
        </>
      ) : (
        <View style={{ gap: spacing.s, marginTop: spacing.m }}>
          <Button mode="contained" buttonColor={colors.error} textColor={colors.onError} disabled={busy} onPress={() => answer(reviewResults.FORGOT)}>
            {t.reviewForgot}
          </Button>
          <Button mode="contained-tonal" disabled={busy} onPress={() => answer(reviewResults.PARTIAL)}>
            {t.reviewPartial}
          </Button>
          <Button mode="contained" disabled={busy} onPress={() => answer(reviewResults.GOOD)}>
            {t.reviewGood}
          </Button>
        </View>
      )}
    </ScrollView>
  );
}
