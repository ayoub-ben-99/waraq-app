// Ported from app/src/main/java/com/waraq/app/data/repo/StatsRepository.java
import { addDays, endOfDay, startOfDay, today as todayStart } from '../../lib/dates';
import { getSqlite } from '../db/client';

export type Period = 'week' | 'month';

export type IntKeyCount = { key: number; count: number };
export type CategoryCount = { id: number | null; name: string | null; count: number };
export type DayMinutes = { day: number; minutes: number };

export type Stats = {
  totalBooks: number;
  readingBooks: number;
  completedBooks: number;
  toReadBooks: number;
  pausedBooks: number;
  abandonedBooks: number;
  sessionsCount: number;
  pagesLogged: number;
  netProgress: number;
  minutes: number;
  entriesTotal: number;
  reviewsDone: number;
  reviewsUnique: number;
  dueNow: number;
  entriesPerType: IntKeyCount[];
  booksPerCategory: CategoryCount[];
  reviewResults: IntKeyCount[];
  tagUsage: { id: number; name: string; count: number }[];
  periodMinutes: number;
  previousPeriodMinutes: number;
  periodActiveDays: number;
  periodDays: number;
  periodDaysMinutes: DayMinutes[];
  hasAnySession: boolean;
};

async function scalar(sql: string, params: (string | number)[] = []): Promise<number> {
  const row = await getSqlite().getFirstAsync<{ v: number | null }>(sql, params);
  return row?.v ?? 0;
}

export async function loadStats(period: Period): Promise<Stats> {
  const raw = getSqlite();
  const days = period === 'week' ? 7 : 30;
  const today = todayStart();
  const from = addDays(today, -(days - 1));
  const to = addDays(today, 1);
  const prevFrom = addDays(from, -days);
  const statusRows = await raw.getAllAsync<{ status: number; count: number }>(
    'SELECT status, COUNT(*) AS count FROM books GROUP BY status',
  );
  const status = new Map(statusRows.map((r) => [r.status, r.count]));
  const byDay = await raw.getAllAsync<{ day: number; minutes: number }>(
    `SELECT date AS day, COALESCE(SUM(durationMinutes),0) AS minutes
     FROM sessions WHERE date>=? AND date<? GROUP BY date ORDER BY date`,
    [from, to],
  );
  const periodMinutes = byDay.reduce((n, r) => n + r.minutes, 0);
  const previousPeriodMinutes = await scalar(
    'SELECT COALESCE(SUM(durationMinutes),0) AS v FROM sessions WHERE date>=? AND date<?',
    [prevFrom, from],
  );
  const entriesPerType = await raw.getAllAsync<IntKeyCount>(
    'SELECT type AS key, COUNT(*) AS count FROM entries GROUP BY type',
  );
  const booksPerCategory = await raw.getAllAsync<CategoryCount>(
    `SELECT c.id AS id, c.name AS name, COUNT(b.id) AS count
     FROM categories c LEFT JOIN books b ON b.categoryId=c.id GROUP BY c.id
     UNION ALL
     SELECT NULL, NULL, COUNT(*) FROM books WHERE categoryId IS NULL`,
  );
  const reviewResults = await raw.getAllAsync<IntKeyCount>(
    'SELECT result AS key, COUNT(*) AS count FROM review_logs GROUP BY result',
  );
  const tagUsage = await raw.getAllAsync<{ id: number; name: string; count: number }>(
    `SELECT t.id,t.name,COUNT(et.entryId) AS count FROM tags t
     LEFT JOIN entry_tags et ON et.tagId=t.id GROUP BY t.id ORDER BY count DESC`,
  );
  return {
    totalBooks: await scalar('SELECT COUNT(*) AS v FROM books'),
    readingBooks: status.get(1) ?? 0,
    completedBooks: status.get(2) ?? 0,
    toReadBooks: status.get(0) ?? 0,
    pausedBooks: status.get(3) ?? 0,
    abandonedBooks: status.get(4) ?? 0,
    sessionsCount: await scalar('SELECT COUNT(*) AS v FROM sessions'),
    pagesLogged: await scalar(
      'SELECT COALESCE(SUM(CASE WHEN endPage>startPage THEN endPage-startPage ELSE 0 END),0) AS v FROM sessions',
    ),
    netProgress: await scalar('SELECT COALESCE(SUM(currentPage),0) AS v FROM books'),
    minutes: await scalar('SELECT COALESCE(SUM(durationMinutes),0) AS v FROM sessions'),
    entriesTotal: await scalar('SELECT COUNT(*) AS v FROM entries'),
    reviewsDone: await scalar('SELECT COUNT(*) AS v FROM review_logs'),
    reviewsUnique: await scalar('SELECT COUNT(*) AS v FROM review_items WHERE lastReviewedAt IS NOT NULL'),
    dueNow: await scalar('SELECT COUNT(*) AS v FROM review_items WHERE dueDate<=?', [endOfDay(Date.now())]),
    entriesPerType,
    booksPerCategory,
    reviewResults,
    tagUsage,
    periodMinutes,
    previousPeriodMinutes,
    periodActiveDays: byDay.length,
    periodDays: days,
    periodDaysMinutes: byDay.map((r) => ({ day: startOfDay(r.day), minutes: r.minutes })),
    hasAnySession: (await raw.getFirstAsync<{ d: number | null }>('SELECT MIN(date) AS d FROM sessions'))?.d != null,
  };
}

export function minutesForDay(stats: Stats, day: number): number {
  return stats.periodDaysMinutes.find((d) => d.day === day)?.minutes ?? 0;
}
