// Ported from app/src/main/java/com/waraq/app/data/repo/BookRepository.java
import { and, eq, sql } from 'drizzle-orm';
import * as FS from 'expo-file-system/legacy';
import { getDb, getSqlite } from '../db/client';
import { books, categories, entries, pdfDocs, summaries, type Book } from '../db/schema';
import { isBlank, likePattern, normalize } from '../../lib/arabicText';
import { bookStatuses } from '../../lib/arabicText';

export const SORT_RECENT = 0;
export const SORT_TITLE = 1;
export const SORT_AUTHOR = 2;
export const SORT_PROGRESS = 3;
export const SORT_RATING = 4;
export const SORT_LAST_READ = 5;
export const SORT_ADDED = 6;
export const FILTER_ALL = -1;

export type CategoryUsage = { id: number; name: string; nameNorm: string; createdAt: number; count: number };

export function progressPercent(book: Book): number {
  if (book.totalPages == null || book.totalPages <= 0) return -1;
  return Math.max(0, Math.min(100, Math.round((book.currentPage * 100) / book.totalPages)));
}

export async function loadBooks(
  query: string,
  status: number,
  categoryId: number | null,
  sort: number,
): Promise<Book[]> {
  let rows: Book[];
  if (!isBlank(query)) {
    const like = likePattern(query);
    rows = await getSqlite().getAllAsync<Book>(
      `SELECT * FROM books
       WHERE titleNorm LIKE ? OR authorNorm LIKE ? OR description LIKE ?
       ORDER BY updatedAt DESC`,
      [like, like, like],
    );
  } else {
    rows = await getSqlite().getAllAsync<Book>('SELECT * FROM books ORDER BY updatedAt DESC');
  }
  const filtered = rows.filter(
    (b) => (status === FILTER_ALL || b.status === status) && (categoryId == null || b.categoryId === categoryId),
  );
  if (sort === SORT_LAST_READ) {
    const readRows = await getSqlite().getAllAsync<{ bookId: number; value: number }>(
      'SELECT bookId, MAX(date) AS value FROM sessions GROUP BY bookId',
    );
    const lastRead = new Map(readRows.map((r) => [r.bookId, r.value]));
    filtered.sort((a, b) => {
      const x = lastRead.get(a.id) ?? Number.MIN_SAFE_INTEGER;
      const y = lastRead.get(b.id) ?? Number.MIN_SAFE_INTEGER;
      return x !== y ? y - x : b.createdAt - a.createdAt;
    });
  } else if (sort === SORT_TITLE) {
    filtered.sort((a, b) => a.title.localeCompare(b.title, 'ar', { sensitivity: 'base' }));
  } else if (sort === SORT_AUTHOR) {
    filtered.sort((a, b) => (a.author ?? '\uffff').localeCompare(b.author ?? '\uffff', 'ar', { sensitivity: 'base' }));
  } else if (sort === SORT_PROGRESS) {
    filtered.sort((a, b) => progressPercent(b) - progressPercent(a));
  } else if (sort === SORT_RATING) {
    filtered.sort((a, b) => (b.rating ?? -1) - (a.rating ?? -1));
  } else if (sort === SORT_ADDED) {
    filtered.sort((a, b) => b.createdAt - a.createdAt);
  } else {
    filtered.sort((a, b) => b.updatedAt - a.updatedAt);
  }
  return filtered;
}

export async function getBook(id: number): Promise<Book> {
  const row = await getDb().select().from(books).where(eq(books.id, id)).get();
  if (!row) throw new Error(`book-not-found:${id}`);
  return row;
}

export async function currentReading(): Promise<Book | null> {
  const rows = await getSqlite().getAllAsync<Book>(
    'SELECT * FROM books WHERE status = ? ORDER BY updatedAt DESC LIMIT 1',
    [bookStatuses.READING],
  );
  return rows[0] ?? null;
}

export async function loadCategories() {
  return getDb().select().from(categories).orderBy(categories.name);
}

export async function categoryUsage(): Promise<CategoryUsage[]> {
  return getSqlite().getAllAsync<CategoryUsage>(
    `SELECT c.*, COUNT(b.id) AS count
     FROM categories c LEFT JOIN books b ON b.categoryId = c.id
     GROUP BY c.id ORDER BY c.name`,
  );
}

export async function bookSummaryCounts(): Promise<[number, number, number]> {
  const row = await getSqlite().getFirstAsync<{ total: number; reading: number; completed: number }>(
    `SELECT COUNT(*) AS total,
      SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS reading,
      SUM(CASE WHEN status = 2 THEN 1 ELSE 0 END) AS completed
     FROM books`,
  );
  return [row?.total ?? 0, row?.reading ?? 0, row?.completed ?? 0];
}

export type BookInput = Omit<Book, 'id' | 'titleNorm' | 'authorNorm'> & { id?: number };

export async function saveBook(input: BookInput): Promise<number> {
  if (isBlank(input.title)) throw new Error('title-required');
  const now = Date.now();
  const titleNorm = normalize(input.title) ?? '';
  const authorNorm = input.author == null ? null : normalize(input.author);
  let status = input.status;
  let startedAt = input.startedAt;
  let finishedAt = input.finishedAt;
  let currentPage = input.currentPage;
  if (status === bookStatuses.READING && startedAt == null) startedAt = now;
  if (status === bookStatuses.COMPLETED && finishedAt == null) finishedAt = now;
  if (status !== bookStatuses.COMPLETED) finishedAt = null;
  if (status === bookStatuses.COMPLETED && input.totalPages != null) currentPage = input.totalPages;
  const createdAt = input.createdAt || now;
  if (!input.id) {
    const result = await getSqlite().runAsync(
      `INSERT INTO books
       (title, author, description, coverPath, categoryId, status, rating, totalPages, currentPage,
        favorite, createdAt, updatedAt, startedAt, finishedAt, titleNorm, authorNorm)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        input.title,
        input.author,
        input.description,
        input.coverPath,
        input.categoryId,
        status,
        input.rating,
        input.totalPages,
        currentPage,
        input.favorite ? 1 : 0,
        createdAt,
        now,
        startedAt,
        finishedAt,
        titleNorm,
        authorNorm,
      ],
    );
    return Number(result.lastInsertRowId);
  }
  await getSqlite().runAsync(
    `UPDATE books SET title=?, author=?, description=?, coverPath=?, categoryId=?, status=?,
      rating=?, totalPages=?, currentPage=?, favorite=?, updatedAt=?, startedAt=?, finishedAt=?,
      titleNorm=?, authorNorm=? WHERE id=?`,
    [
      input.title,
      input.author,
      input.description,
      input.coverPath,
      input.categoryId,
      status,
      input.rating,
      input.totalPages,
      currentPage,
      input.favorite ? 1 : 0,
      now,
      startedAt,
      finishedAt,
      titleNorm,
      authorNorm,
      input.id,
    ],
  );
  return input.id;
}

export async function setBookStatus(id: number, status: number): Promise<void> {
  if (status < 0 || status > 4) throw new Error('bad-status');
  const book = await getBook(id);
  const now = Date.now();
  let startedAt = book.startedAt;
  let finishedAt = book.finishedAt;
  let currentPage = book.currentPage;
  if (status === bookStatuses.READING && startedAt == null) startedAt = now;
  if (status === bookStatuses.COMPLETED) {
    finishedAt = now;
    if (book.totalPages != null) currentPage = book.totalPages;
  } else {
    finishedAt = null;
  }
  await getDb()
    .update(books)
    .set({ status, startedAt, finishedAt, currentPage, updatedAt: now })
    .where(eq(books.id, id));
}

export async function toggleBookFavorite(id: number): Promise<boolean> {
  const book = await getBook(id);
  const favorite = book.favorite ? 0 : 1;
  await getDb().update(books).set({ favorite, updatedAt: Date.now() }).where(eq(books.id, id));
  return favorite === 1;
}

export async function deleteBook(id: number, keepEntries: boolean): Promise<void> {
  const raw = getSqlite();
  const book = await raw.getFirstAsync<{ coverPath: string | null }>(
    'SELECT coverPath FROM books WHERE id = ?',
    [id],
  );
  const doc = await raw.getFirstAsync<{ id: number; localPath: string | null }>(
    'SELECT id,localPath FROM pdf_docs WHERE bookId = ?',
    [id],
  );
  const linked = await raw.getAllAsync<{ id: number }>('SELECT id FROM entries WHERE bookId = ?', [id]);
  const audio = keepEntries
    ? []
    : await raw.getAllAsync<{ fileName: string }>(
        `SELECT fileName FROM entry_audio WHERE entryId IN (${linked.map(() => '?').join(',') || 'NULL'})`,
        linked.map((e) => e.id),
      );
  await raw.withTransactionAsync(async () => {
    if (doc) {
      await raw.runAsync('DELETE FROM pdf_highlights WHERE pdfDocId = ?', [doc.id]);
      await raw.runAsync('DELETE FROM pdf_docs WHERE id = ?', [doc.id]);
    }
    if (keepEntries) {
      await raw.runAsync('UPDATE entries SET bookId = NULL WHERE bookId = ?', [id]);
    } else {
      for (const entry of linked) {
        await raw.runAsync('DELETE FROM review_logs WHERE entryId = ?', [entry.id]);
        await raw.runAsync('DELETE FROM review_items WHERE entryId = ?', [entry.id]);
        await raw.runAsync('UPDATE pdf_highlights SET entryId = NULL WHERE entryId = ?', [entry.id]);
        await raw.runAsync('DELETE FROM entry_tags WHERE entryId = ?', [entry.id]);
        await raw.runAsync('DELETE FROM entry_audio WHERE entryId = ?', [entry.id]);
      }
      if (linked.length) {
        await raw.runAsync(
          `DELETE FROM entries WHERE id IN (${linked.map(() => '?').join(',')})`,
          linked.map((e) => e.id),
        );
      }
    }
    await raw.runAsync('DELETE FROM sessions WHERE bookId = ?', [id]);
    await raw.runAsync('DELETE FROM summaries WHERE bookId = ?', [id]);
    await raw.runAsync('DELETE FROM books WHERE id = ?', [id]);
  });
  if (doc?.localPath) {
    await FS.deleteAsync(`${FS.documentDirectory}${doc.localPath}`, { idempotent: true });
  }
  if (book?.coverPath) {
    await FS.deleteAsync(`${FS.documentDirectory}${book.coverPath}`, { idempotent: true });
  }
  for (const row of audio) {
    await FS.deleteAsync(`${FS.documentDirectory}${row.fileName}`, { idempotent: true });
  }
}

export async function saveCover(bookId: number, sourceUri: string): Promise<string> {
  const dir = `${FS.documentDirectory}covers/`;
  await FS.makeDirectoryAsync(dir, { intermediates: true });
  const ext = sourceUri.split('.').pop()?.split('?')[0] ?? 'img';
  const name = `cover_${bookId}_${Math.random().toString(36).slice(2, 10)}.${ext}`;
  const target = `${dir}${name}`;
  await FS.copyAsync({ from: sourceUri, to: target });
  const book = await getBook(bookId);
  if (book.coverPath) await FS.deleteAsync(`${FS.documentDirectory}${book.coverPath}`, { idempotent: true });
  await getDb().update(books).set({ coverPath: `covers/${name}`, updatedAt: Date.now() }).where(eq(books.id, bookId));
  return `covers/${name}`;
}

export async function removeCover(bookId: number): Promise<void> {
  const book = await getBook(bookId);
  if (book.coverPath) {
    await FS.deleteAsync(`${FS.documentDirectory}${book.coverPath}`, { idempotent: true });
  }
  await getDb().update(books).set({ coverPath: null, updatedAt: Date.now() }).where(eq(books.id, bookId));
}

export async function createCategory(name: string): Promise<boolean> {
  const trimmed = name.trim();
  if (!trimmed) throw new Error('category-name-required');
  const norm = normalize(trimmed) ?? '';
  const existing = await getDb().select({ id: categories.id }).from(categories).where(eq(categories.nameNorm, norm)).get();
  if (existing) return false;
  await getDb().insert(categories).values({ name: trimmed, nameNorm: norm, createdAt: Date.now() });
  return true;
}

export async function deleteCategory(id: number): Promise<void> {
  await getDb().delete(categories).where(eq(categories.id, id));
}

export async function booksForCategories(): Promise<CategoryUsage[]> {
  return categoryUsage();
}

export async function allBooks(): Promise<Book[]> {
  return getDb().select().from(books);
  }
