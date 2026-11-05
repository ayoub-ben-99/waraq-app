// Ported from app/src/main/java/com/waraq/app/data/repo/ReviewRepository.java
import { endOfDay, today as todayStart } from '../../lib/dates';
import { afterGrade, initial, type Schedule } from '../../lib/reviewScheduler';
import { getSqlite } from '../db/client';
import type { KnowledgeEntry, ReviewItem } from '../db/schema';
import { intervals } from './settings';

export type DueEntry = { item: ReviewItem; entry: KnowledgeEntry; overdue: boolean };

const joinSql = `SELECT ri.*, e.title, e.quoteText, e.comment, e.type, e.bookId, e.page, e.date,
  e.favorite AS entryFavorite, e.createdAt AS entryCreatedAt, e.updatedAt AS entryUpdatedAt
  FROM review_items ri JOIN entries e ON e.id = ri.entryId`;

function toDue(row: Record<string, unknown>, today: number): DueEntry {
  const item: ReviewItem = {
    id: row.id as number,
    entryId: row.entryId as number,
    dueDate: row.dueDate as number,
    intervalIndex: row.intervalIndex as number,
    lastReviewedAt: (row.lastReviewedAt as number | null) ?? null,
    lastResult: row.lastResult as number,
    totalReviews: row.totalReviews as number,
    createdAt: row.createdAt as number,
  };
  const entry: KnowledgeEntry = {
    id: row.entryId as number,
    type: row.type as number,
    title: (row.title as string | null) ?? null,
    quoteText: (row.quoteText as string | null) ?? null,
    comment: (row.comment as string | null) ?? null,
    bookId: (row.bookId as number | null) ?? null,
    page: (row.page as number | null) ?? null,
    date: row.date as number,
    favorite: row.entryFavorite as number,
    createdAt: row.entryCreatedAt as number,
    updatedAt: row.entryUpdatedAt as number,
    titleNorm: '',
    quoteNorm: null,
    commentNorm: null,
  };
  return { item, entry, overdue: item.dueDate < today };
}

export async function addToReview(entryId: number): Promise<ReviewItem> {
  const raw = getSqlite();
  const entry = await raw.getFirstAsync<{ id: number }>('SELECT id FROM entries WHERE id=?', [entryId]);
  if (!entry) throw new Error('entry-not-found');
  const existing = await raw.getFirstAsync<ReviewItem>('SELECT * FROM review_items WHERE entryId=?', [entryId]);
  if (existing) return existing;
  const today = todayStart();
  const schedule = initial(await intervals(), today);
  const result = await raw.runAsync(
    `INSERT INTO review_items (entryId,dueDate,intervalIndex,lastReviewedAt,lastResult,totalReviews,createdAt)
     VALUES (?,?,?,?,?,?,?)`,
    [entryId, schedule.dueDate, schedule.intervalIndex, null, -1, 0, Date.now()],
  );
  const item = await raw.getFirstAsync<ReviewItem>('SELECT * FROM review_items WHERE id=?', [Number(result.lastInsertRowId)]);
  return item as ReviewItem;
}

export async function removeFromReview(entryId: number): Promise<void> {
  await getSqlite().runAsync('DELETE FROM review_items WHERE entryId=?', [entryId]);
}

export async function isInReview(entryId: number): Promise<boolean> {
  const row = await getSqlite().getFirstAsync<{ id: number }>('SELECT id FROM review_items WHERE entryId=?', [entryId]);
  return row != null;
}

export async function dueList(): Promise<DueEntry[]> {
  const rows = await getSqlite().getAllAsync<Record<string, unknown>>(
    `${joinSql} WHERE ri.dueDate <= ? ORDER BY ri.dueDate ASC, ri.id ASC`,
    [endOfDay(Date.now())],
  );
  const today = todayStart();
  return rows.map((r) => toDue(r, today));
}

export async function upcoming(limit: number): Promise<DueEntry[]> {
  const rows = await getSqlite().getAllAsync<Record<string, unknown>>(
    `${joinSql} WHERE ri.dueDate > ? ORDER BY ri.dueDate ASC, ri.id ASC LIMIT ?`,
    [endOfDay(Date.now()), limit],
  );
  return rows.map((r) => toDue(r, todayStart()));
}

export async function grade(entryId: number, result: number): Promise<Schedule> {
  if (result < 0 || result > 2) throw new Error('bad-result');
  const raw = getSqlite();
  const item = await raw.getFirstAsync<ReviewItem>('SELECT * FROM review_items WHERE entryId=?', [entryId]);
  if (!item) throw new Error('not-in-review');
  const schedule = afterGrade(await intervals(), item.intervalIndex, result, todayStart());
  const now = Date.now();
  await raw.withTransactionAsync(async () => {
    await raw.runAsync(
      'UPDATE review_items SET intervalIndex=?, dueDate=?, lastReviewedAt=?, lastResult=?, totalReviews=? WHERE entryId=?',
      [schedule.intervalIndex, schedule.dueDate, now, result, item.totalReviews + 1, entryId],
    );
    await raw.runAsync(
      'INSERT INTO review_logs (entryId,reviewedAt,result,nextDueAt,intervalDays) VALUES (?,?,?,?,?)',
      [entryId, now, result, schedule.dueDate, schedule.intervalDays],
    );
  });
  return schedule;
}

export async function postpone(entryId: number, days: number): Promise<number> {
  if (days <= 0) throw new Error('bad-days');
  const raw = getSqlite();
  const item = await raw.getFirstAsync<ReviewItem>('SELECT * FROM review_items WHERE entryId=?', [entryId]);
  if (!item) throw new Error('not-in-review');
  const base = Math.max(item.dueDate, todayStart());
  const date = new Date(base);
  date.setDate(date.getDate() + days);
  date.setHours(0, 0, 0, 0);
  const due = date.getTime();
  await raw.runAsync('UPDATE review_items SET dueDate=? WHERE entryId=?', [due, entryId]);
  return due;
}

export async function reviewCounts(): Promise<[number, number, number, number]> {
  const end = endOfDay(Date.now());
  const row = await getSqlite().getFirstAsync<{
    due: number;
    upcoming: number;
    items: number;
    logs: number;
  }>(
    `SELECT
      (SELECT COUNT(*) FROM review_items WHERE dueDate <= ?) AS due,
      (SELECT COUNT(*) FROM review_items WHERE dueDate > ?) AS upcoming,
      (SELECT COUNT(*) FROM review_items) AS items,
      (SELECT COUNT(*) FROM review_logs) AS logs`,
    [end, end],
  );
  return [row?.due ?? 0, row?.upcoming ?? 0, row?.items ?? 0, row?.logs ?? 0];
}

export async function allReviewItems() {
  return getSqlite().getAllAsync<ReviewItem>('SELECT * FROM review_items');
}

export async function allReviewLogs() {
  return getSqlite().getAllAsync<import('../db/schema').ReviewLog>('SELECT * FROM review_logs');
}
