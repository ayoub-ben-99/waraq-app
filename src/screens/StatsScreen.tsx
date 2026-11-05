// Ported from app/src/main/java/com/waraq/app/ui/stats/StatsFragment.java
import React, { useMemo, useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Text } from 'react-native-paper';
import { useQuery } from '@tanstack/react-query';
import * as FS from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { loadStats, minutesForDay, type Period, type Stats } from '../data/repos/stats';
import { addDays, formatDuration, formatShort, today } from '../lib/dates';
import { entryTypeLabel } from '../lib/labels';
import { t } from '../lib/strings';
import { useRefreshOnFocus } from '../lib/useRefreshOnFocus';
import { useAppTheme } from '../theme/ThemeProvider';
import { EmptyState, Loading } from '../components/Layout';

const DAY_LETTERS = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

export function StatsScreen() {
  const { colors, spacing, shape } = useAppTheme();
  const [period, setPeriod] = useState<Period>('week');
  const query = useQuery({ queryKey: ['stats', period], queryFn: () => loadStats(period) });
  useRefreshOnFocus(query.refetch);
  const stats = query.data;

  const exportCsv = async () => {
    try {
      const fresh = await loadStats(period);
      if (fresh.totalBooks === 0 && fresh.entriesTotal === 0 && fresh.sessionsCount === 0) {
        Alert.alert(t.statsExportEmpty);
        return;
      }
      const lines: string[] = [];
      lines.push(`وَرَق,إحصاءات`);
      lines.push(`الفترة,${period === 'week' ? t.statsWeek : t.statsMonth}`);
      lines.push(`الكتب,${fresh.totalBooks}`);
      lines.push(`كتب مكتملة,${fresh.completedBooks}`);
      lines.push(`الصفحات المسجلة,${fresh.pagesLogged}`);
      lines.push(`التقدم الصافي,${fresh.netProgress}`);
      lines.push(`مدة القراءة,${fresh.minutes}`);
      lines.push(`الإدخالات,${fresh.entriesTotal}`);
      lines.push(`المراجعات,${fresh.reviewsDone}`);
      lines.push('');
      lines.push('النوع,العدد');
      for (const row of fresh.entriesPerType) lines.push(`${entryTypeLabel(row.key)},${row.count}`);
      const path = `${FS.cacheDirectory}waraq-stats-${Date.now()}.csv`;
      await FS.writeAsStringAsync(path, `\uFEFF${lines.join('\n')}`);
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(path, { mimeType: 'text/csv', dialogTitle: t.statsExport });
      } else {
        Alert.alert(t.statsExportFailed);
      }
      await FS.deleteAsync(path, { idempotent: true });
    } catch {
      Alert.alert(t.statsExportFailed);
    }
  };

  if (query.isLoading) return <Loading />;
  if (query.isError || !stats) {
    return (
      <View style={{ padding: spacing.m }}>
        <EmptyState title={t.statsError} action={<Button onPress={() => query.refetch()}>{t.retry}</Button>} />
      </View>
    );
  }
  const hasData = stats.totalBooks > 0 || stats.entriesTotal > 0 || stats.sessionsCount > 0;
  if (!hasData) {
    return (
      <View style={{ padding: spacing.m }}>
        <EmptyState title={t.statsBooks} body={t.emptyLibraryBody} />
      </View>
    );
  }

  const bars = buildBars(stats, period);

  return (
    <ScrollView
      style={{ backgroundColor: colors.background }}
      contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}
    >
      <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginBottom: spacing.m }}>
        <Button mode={period === 'week' ? 'contained' : 'outlined'} onPress={() => setPeriod('week')} style={{ flex: 1 }}>
          {t.statsWeek}
        </Button>
        <Button mode={period === 'month' ? 'contained' : 'outlined'} onPress={() => setPeriod('month')} style={{ flex: 1 }}>
          {t.statsMonth}
        </Button>
      </View>

      <View style={{ flexDirection: 'row-reverse', flexWrap: 'wrap', gap: spacing.s }}>
        <Kpi label={t.statsBooks} value={String(stats.totalBooks)} />
        <Kpi label={t.statsCompleted} value={String(stats.completedBooks)} />
        <Kpi label={t.statsPagesLogged} value={String(stats.pagesLogged)} />
        <Kpi label={t.statsNetProgress} value={String(stats.netProgress)} />
        <Kpi label={t.statsEntries} value={String(stats.entriesTotal)} />
        <Kpi label={t.statsReadingTime} value={formatDuration(stats.minutes)} />
      </View>

      <Card style={{ backgroundColor: colors.surface, marginTop: spacing.m, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth }}>
        <Card.Content>
          <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between' }}>
            <Text variant="titleMedium" style={{ color: colors.onSurface }}>
              {t.statsChartTitle}
            </Text>
            <Button compact mode="text" icon="share-variant" onPress={exportCsv}>
              {t.statsExport}
            </Button>
          </View>
          <Text variant="headlineSmall" style={{ color: colors.onSurface, textAlign: 'right', marginTop: spacing.s }}>
            {formatDuration(stats.periodMinutes)}
          </Text>
          <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
            {formatShort(addDays(today(), -(stats.periodDays - 1)))} — {formatShort(today())}
          </Text>
          <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 4 }}>
            {stats.previousPeriodMinutes <= 0
              ? t.statsCompareNone
              : stats.periodMinutes === stats.previousPeriodMinutes
                ? t.statsCompareSame
                : stats.periodMinutes > stats.previousPeriodMinutes
                  ? t.statsCompareUp(formatDuration(stats.periodMinutes - stats.previousPeriodMinutes))
                  : t.statsCompareDown(formatDuration(stats.previousPeriodMinutes - stats.periodMinutes))}
          </Text>
          {stats.periodMinutes <= 0 ? (
            <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: spacing.m }}>
              {stats.hasAnySession ? t.statsChartEmpty : t.statsChartNoHistory}
            </Text>
          ) : (
            <View style={{ flexDirection: 'row-reverse', alignItems: 'flex-end', height: 150, gap: 6, marginTop: spacing.m }}>
              {bars.map((bar, index) => {
                const max = Math.max(...bars.map((b) => b.minutes), 1);
                return (
                  <View key={`${bar.label}-${index}`} style={{ flex: 1, alignItems: 'center' }}>
                    <View
                      style={{
                        width: '70%',
                        height: Math.max(3, (bar.minutes / max) * 110),
                        borderRadius: shape.s4,
                        backgroundColor: index === bars.length - 1 ? colors.primary : colors.primaryContainer,
                      }}
                    />
                    <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, marginTop: 4 }}>
                      {bar.label}
                    </Text>
                  </View>
                );
              })}
            </View>
          )}
          <View style={{ flexDirection: 'row-reverse', justifyContent: 'space-between', marginTop: spacing.m }}>
            <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
              {t.statsDaysRead}: {stats.periodActiveDays}/{stats.periodDays}
            </Text>
            <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant }}>
              {t.statsDailyAverage}: {formatDuration(Math.round(stats.periodMinutes / Math.max(1, stats.periodDays)))}
            </Text>
          </View>
        </Card.Content>
      </Card>

      <Breakdown title={t.statsByType} rows={(stats.entriesPerType ?? []).map((r) => ({ label: entryTypeLabel(r.key), value: r.count }))} />
      <Breakdown
        title={t.statsByCategory}
        rows={(stats.booksPerCategory ?? []).filter((r) => r.count > 0).map((r) => ({ label: r.name ?? t.statsNoCategory, value: r.count }))}
      />
      <Breakdown
        title={t.statsReviewResults}
        rows={(stats.reviewResults ?? []).map((r) => ({
          label: r.key === 0 ? t.reviewForgot : r.key === 1 ? t.reviewPartial : t.reviewGood,
          value: r.count,
        }))}
      />
      <Breakdown title={t.settingsReview} rows={(stats.tagUsage ?? []).filter((r) => r.count > 0).map((r) => ({ label: `#${r.name}`, value: r.count }))} />
    </ScrollView>
  );
}

function Kpi({ label, value }: { label: string; value: string }) {
  const { colors } = useAppTheme();
  return (
    <Card style={{ width: '31%', backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth }}>
      <Card.Content style={{ paddingVertical: 12 }}>
        <Text variant="labelSmall" numberOfLines={1} style={{ color: colors.onSurfaceVariant }}>
          {label}
        </Text>
        <Text variant="titleLarge" numberOfLines={1} style={{ color: colors.onSurface, marginTop: 4 }}>
          {value}
        </Text>
      </Card.Content>
    </Card>
  );
}

function Breakdown({ title, rows }: { title: string; rows: { label: string; value: number }[] }) {
  const { colors, spacing, shape } = useAppTheme();
  return (
    <Card style={{ backgroundColor: colors.surface, marginTop: spacing.m, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth }}>
      <Card.Content>
        <Text variant="titleMedium" style={{ color: colors.onSurface, textAlign: 'right', marginBottom: spacing.s }}>
          {title}
        </Text>
        {rows.length === 0 ? (
          <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
            {t.none}
          </Text>
        ) : (
          rows.map((row) => (
            <View key={row.label} style={{ flexDirection: 'row-reverse', justifyContent: 'space-between', paddingVertical: 4 }}>
              <Text variant="bodyMedium" style={{ color: colors.onSurface }}>
                {row.label}
              </Text>
              <Text variant="labelMedium" style={{ color: colors.onSurfaceVariant }}>
                {row.value}
              </Text>
            </View>
          ))
        )}
      </Card.Content>
    </Card>
  );
}

function buildBars(stats: Stats, period: Period): { label: string; minutes: number }[] {
  const end = today();
  if (period === 'week') {
    return Array.from({ length: 7 }, (_, i) => {
      const day = addDays(end, i - 6);
      return { label: DAY_LETTERS[new Date(day).getDay()], minutes: minutesForDay(stats, day) };
    });
  }
  const start = addDays(end, -29);
  return Array.from({ length: 5 }, (_, i) => {
    const from = addDays(start, i * 6);
    const to = i === 4 ? addDays(end, 1) : addDays(from, 6);
    let minutes = 0;
    for (let d = from; d < to; d = addDays(d, 1)) minutes += minutesForDay(stats, d);
    return { label: `${i + 1}`, minutes };
  });
}
