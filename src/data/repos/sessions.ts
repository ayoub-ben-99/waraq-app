// Ported from app/src/main/java/com/waraq/app/data/repo/SessionRepository.java
import { addDays, startOfDay, today as todayStart } from '../../lib/dates';
import { getSqlite } from '../db/client';
import { bookStatuses } from '../../lib/arabicText';
import type { ReadingSession } from '../db/schema';

export const DUPLICATE_WINDOW_MS = 3000;

export type SaveSessionResult = {
  sessionId: number;
  duplicate: boolean;
  historical: boolean;
  bookCurrentPage: number;
};

export async function saveSession(
  bookId: number,
  startPage: number,
  endPage: number,
  durationMinutes: number,
  date: number,
  note: string | null,
  historical: boolean,
): Promise<SaveSessionResult> {
  const raw = getSqlite();
  const book = await raw.getFirstAsync<{ currentPage: number; totalPages: number | null; status: number; startedAt: number | null }>(
    'SELECT currentPage,totalPages,status,startedAt FROM books WHERE id = ?',
    [bookId],
  );
  if (!book) throw new Error('book-not-found');
  if (startPage < 0) throw new Error('bad-start');
  if (endPage < startPage) throw new Error('bad-end');
  if (durationMinutes <= 0) throw new Error('bad-duration');
  if (book.totalPages != null && endPage > book.totalPages) throw new Error('beyond-total');
  const now = Date.now();
  const day = startOfDay(date);
  const duplicate = await raw.getFirstAsync<{ id: number }>(
    `SELECT id FROM sessions
     WHERE bookId=? AND date=? AND startPage=? AND endPage=? AND durationMinutes=? AND createdAt>=?
     ORDER BY id DESC LIMIT 1`,
    [bookId, day, startPage, endPage, durationMinutes, now - DUPLICATE_WINDOW_MS],
  );
  if (duplicate) {
    return { sessionId: duplicate.id, duplicate: true, historical, bookCurrentPage: book.currentPage };
  }
  let sessionId = 0;
  let currentPage = book.currentPage;
  await raw.withTransactionAsync(async () => {
    const result = await raw.runAsync(
      'INSERT INTO sessions (bookId,startPage,endPage,durationMinutes,date,note,historical,createdAt) VALUES (?,?,?,?,?,?,?,?)',
      [bookId, startPage, endPage, durationMinutes, day, note, historical ? 1 : 0, now],
    );
    sessionId = Number(result.lastInsertRowId);
    if (!historical) {
      currentPage = Math.max(book.currentPage, endPage);
      let status = book.status;
      if (status === bookStatuses.TO_READ || status === bookStatuses.PAUSED) status = bookStatuses.READING;
      await raw.runAsync(
        'UPDATE books SET currentPage=?, status=?, startedAt=?, updatedAt=? WHERE id=?',
        [currentPage, status, book.startedAt ?? now, now, bookId],
      );
    }
  });
  return { sessionId, duplicate: false, historical, bookCurrentPage: currentPage };
}

export async function sessionsForBook(bookId: number): Promise<ReadingSession[]> {
  return getSqlite().getAllAsync<ReadingSession>(
    'SELECT * FROM sessions WHERE bookId=? ORDER BY date DESC, id DESC',
    [bookId],
  );
}

export async function deleteSession(sessionId: number): Promise<void> {
  await getSqlite().runAsync('DELETE FROM sessions WHERE id=?', [sessionId]);
}

export async function todayActivity(): Promise<[number, number]> {
  const from = todayStart();
  const to = addDays(from, 1);
  const row = await getSqlite().getFirstAsync<{ minutes: number; pages: number }>(
    `SELECT COALESCE(SUM(durationMinutes),0) AS minutes,
            COALESCE(SUM(CASE WHEN endPage > startPage THEN endPage-startPage ELSE 0 END),0) AS pages
     FROM sessions WHERE date>=? AND date<?`,
    [from, to],
  );
  return [row?.minutes ?? 0, row?.pages ?? 0];
}

export async function totals(): Promise<[number, number, number]> {
  const row = await getSqlite().getFirstAsync<{ sessions: number; pages: number; minutes: number }>(
    `SELECT COUNT(*) AS sessions,
      COALESCE(SUM(CASE WHEN endPage > startPage THEN endPage-startPage ELSE 0 END),0) AS pages,
      COALESCE(SUM(durationMinutes),0) AS minutes FROM sessions`,
  );
  return [row?.sessions ?? 0, row?.pages ?? 0, row?.minutes ?? 0];
}
