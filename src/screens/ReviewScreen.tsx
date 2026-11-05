// Ported from app/src/main/java/com/waraq/app/ui/review/ReviewFragment.java
import React, { useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Text } from 'react-native-paper';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useQuery } from '@tanstack/react-query';
import { dueList, postpone, upcoming, type DueEntry } from '../data/repos/review';
import { daysBetween, formatShort, today } from '../lib/dates';
import { entryDisplayText, entryTypeLabel } from '../lib/labels';
import { t } from '../lib/strings';
import { useRefreshOnFocus } from '../lib/useRefreshOnFocus';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';
import { EmptyState, Loading } from '../components/Layout';

type Nav = NativeStackNavigationProp<RootStackParamList>;

function displayTitle(d: DueEntry): string {
  if (d.entry.title?.trim()) return d.entry.title;
  const body = entryDisplayText(d.entry);
  if (body.length > 90) return `${body.slice(0, 90)}…`;
  return body || entryTypeLabel(d.entry.type);
}

export function ReviewScreen() {
  const navigation = useNavigation<Nav>();
  const { colors, spacing } = useAppTheme();
  const [busy, setBusy] = useState(false);
  const due = useQuery({ queryKey: ['review-due'], queryFn: dueList });
  const upcomingQuery = useQuery({ queryKey: ['review-upcoming'], queryFn: () => upcoming(20) });
  useRefreshOnFocus(due.refetch);
  useRefreshOnFocus(upcomingQuery.refetch);

  const dueItems = due.data ?? [];
  const later = upcomingQuery.data ?? [];
  const start = () => {
    if (dueItems.length === 0) {
      Alert.alert(t.reviewNoDueTitle);
      return;
    }
    navigation.navigate('ReviewSession');
  };

  const postponeItem = (item: DueEntry) => {
    Alert.alert(t.reviewPostpone, undefined, [
      {
        text: t.reviewPostponeDay,
        onPress: () => doPostpone(item, 1),
      },
      {
        text: t.reviewPostponeThree,
        onPress: () => doPostpone(item, 3),
      },
      {
        text: t.reviewPostponeWeek,
        onPress: () => doPostpone(item, 7),
      },
      { text: t.cancel, style: 'cancel' },
    ]);
  };

  const doPostpone = async (item: DueEntry, days: number) => {
    setBusy(true);
    try {
      await postpone(item.item.entryId, days);
      await due.refetch();
      await upcomingQuery.refetch();
    } finally {
      setBusy(false);
    }
  };

  if (due.isLoading) return <Loading />;
  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
    >
      <Card style={{ backgroundColor: colors.primaryContainer, marginBottom: spacing.m }}>
        <Card.Content style={{ alignItems: 'flex-end' }}>
          <Text variant="labelMedium" style={{ color: colors.onPrimaryContainer }}>
            {t.review}
          </Text>
          <Text variant="displaySmall" style={{ color: colors.onPrimaryContainer, fontFamily: 'PlexSemiBold' }}>
            {t.reviewCountDue(dueItems.length)}
          </Text>
          <Text variant="bodySmall" style={{ color: colors.onPrimaryContainer, textAlign: 'right', marginTop: 4 }}>
            {t.settingsIntervalsHelp}
          </Text>
          <Button
            mode="contained"
            onPress={start}
            disabled={dueItems.length === 0 || busy}
            style={{ marginTop: spacing.m, alignSelf: 'stretch' }}
          >
            {t.reviewStart}
          </Button>
        </Card.Content>
      </Card>

      {dueItems.length === 0 ? (
        <EmptyState title={t.reviewNoDueTitle} body={t.reviewNoDueBody} />
      ) : (
        <>
          <Text variant="titleMedium" style={{ color: colors.onSurface, marginBottom: spacing.s, textAlign: 'right' }}>
            {t.reviewDueToday}
          </Text>
          {dueItems.map((item) => {
            const late = daysBetween(item.item.dueDate, today());
            return (
              <Card
                key={item.item.entryId}
                style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginBottom: spacing.s }}
                onPress={() => navigation.navigate('EntryEdit', { entryId: item.entry.id })}
              >
                <Card.Content>
                  <Text variant="titleSmall" numberOfLines={2} style={{ color: colors.onSurface, textAlign: 'right' }}>
                    {displayTitle(item)}
                  </Text>
                  <View style={{ flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between', marginTop: spacing.s }}>
                    <Text variant="labelSmall" style={{ color: late > 0 ? colors.error : colors.onSurfaceVariant }}>
                      {late > 0 ? `${t.reviewOverdue} • ${late} يوم` : t.reviewDueToday}
                    </Text>
                    <Button compact mode="text" onPress={() => postponeItem(item)}>
                      {t.reviewPostpone}
                    </Button>
                  </View>
                </Card.Content>
              </Card>
            );
          })}
        </>
      )}

      {later.length > 0 ? (
        <>
          <Text variant="titleMedium" style={{ color: colors.onSurface, marginTop: spacing.l, marginBottom: spacing.s, textAlign: 'right' }}>
            {t.reviewUpcoming}
          </Text>
          {later.map((item) => {
            const days = daysBetween(today(), item.item.dueDate);
            return (
              <Card
                key={item.item.entryId}
                style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginBottom: spacing.s }}
                onPress={() => navigation.navigate('EntryEdit', { entryId: item.entry.id })}
              >
                <Card.Content>
                  <Text variant="titleSmall" numberOfLines={1} style={{ color: colors.onSurface, textAlign: 'right' }}>
                    {displayTitle(item)}
                  </Text>
                  <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 4 }}>
                    {t.reviewUpcomingItem(formatShort(item.item.dueDate), days)}
                  </Text>
                </Card.Content>
              </Card>
            );
          })}
        </>
      ) : null}
    </ScrollView>
  );
}
