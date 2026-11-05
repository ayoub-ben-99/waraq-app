// Ported from app/src/main/java/com/waraq/app/data/repo/KnowledgeRepository.java
import { eq } from 'drizzle-orm';
import * as FS from 'expo-file-system/legacy';
import { getDb, getSqlite } from '../db/client';
import { entries, entryAudio, tags, type EntryAudio, type KnowledgeEntry, type Tag } from '../db/schema';
import { isBlank, likePattern, normalize } from '../../lib/arabicText';
import { today } from '../../lib/dates';

export const SORT_NEWEST = 0;
export const SORT_OLDEST = 1;
export const SORT_TITLE = 2;

export type EntryTagRow = { entryId: number; tagId: number; name: string; nameNorm: string };

export function displayText(entry: KnowledgeEntry): string {
  if (entry.quoteText && entry.quoteText.trim()) return entry.quoteText.trim();
  return entry.comment?.trim() ?? '';
}

export async function listEntries(
  type: number,
  favoriteOnly: boolean,
  query: string,
  tagId: number | null,
  sort: number,
): Promise<KnowledgeEntry[]> {
  const where: string[] = [];
  const params: (string | number)[] = [];
  if (type >= 0) {
    where.push('e.type = ?');
    params.push(type);
  }
  if (favoriteOnly) where.push('e.favorite = 1');
  if (!isBlank(query)) {
    const like = likePattern(query);
    where.push('(e.titleNorm LIKE ? OR e.quoteNorm LIKE ? OR e.commentNorm LIKE ?)');
    params.push(like, like, like);
  }
  if (tagId != null) {
    where.push('EXISTS (SELECT 1 FROM entry_tags et WHERE et.entryId = e.id AND et.tagId = ?)');
    params.push(tagId);
  }
  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const order =
    sort === SORT_OLDEST
      ? 'ORDER BY e.date ASC, e.id ASC'
      : sort === SORT_TITLE
        ? 'ORDER BY CASE WHEN e.title IS NULL OR TRIM(e.title) = \'\' THEN 1 ELSE 0 END, e.title COLLATE NOCASE ASC, e.date DESC, e.id DESC'
        : 'ORDER BY e.date DESC, e.id DESC';
  return getSqlite().getAllAsync<KnowledgeEntry>(`SELECT e.* FROM entries e ${clause} ${order}`, params);
}

export async function recentEntries(limit: number): Promise<KnowledgeEntry[]> {
  return getSqlite().getAllAsync<KnowledgeEntry>(
    'SELECT * FROM entries ORDER BY createdAt DESC LIMIT ?',
    [Math.max(1, limit)],
  );
}

export async function entriesForBook(bookId: number): Promise<KnowledgeEntry[]> {
  return getSqlite().getAllAsync<KnowledgeEntry>(
    'SELECT * FROM entries WHERE bookId = ? ORDER BY date DESC, id DESC',
    [bookId],
  );
}

export async function getEntry(id: number): Promise<KnowledgeEntry | null> {
  const row = await getDb().select().from(entries).where(eq(entries.id, id)).get();
  return row ?? null;
}

export async function tagsOf(entryId: number): Promise<EntryTagRow[]> {
  return getSqlite().getAllAsync<EntryTagRow>(
    `SELECT et.entryId, et.tagId, t.name, t.nameNorm
     FROM entry_tags et JOIN tags t ON t.id = et.tagId
     WHERE et.entryId = ? ORDER BY t.name`,
    [entryId],
  );
}

export async function allEntryTags(): Promise<EntryTagRow[]> {
  return getSqlite().getAllAsync<EntryTagRow>(
    'SELECT et.entryId, et.tagId, t.name, t.nameNorm FROM entry_tags et JOIN tags t ON t.id = et.tagId',
  );
}

export async function allTags(): Promise<Tag[]> {
  return getDb().select().from(tags).orderBy(tags.name);
}

export async function usedTags(): Promise<Tag[]> {
  return getSqlite().getAllAsync<Tag>(
    'SELECT DISTINCT t.* FROM tags t JOIN entry_tags et ON et.tagId = t.id ORDER BY t.name',
  );
}

export async function tagUsage(): Promise<(Tag & { count: number })[]> {
  return getSqlite().getAllAsync<Tag & { count: number }>(
    `SELECT t.*, COUNT(et.entryId) AS count FROM tags t
     LEFT JOIN entry_tags et ON et.tagId = t.id GROUP BY t.id ORDER BY t.name`,
  );
}

export type EntryInput = {
  id?: number;
  type: number;
  title: string | null;
  quoteText: string | null;
  comment: string | null;
  bookId: number | null;
  page: number | null;
  date: number;
  favorite: boolean;
  createdAt?: number;
};

export async function saveEntry(input: EntryInput, tagNames: string[]): Promise<number> {
  const titled = input.title != null && input.title.trim().length > 0;
  const hasText = !isBlank(input.quoteText) || !isBlank(input.comment);
  if (!hasText && !titled) throw new Error('text-required');
  const raw = getSqlite();
  const now = Date.now();
  let id = input.id ?? 0;
  await raw.withTransactionAsync(async () => {
    const values = [
      input.type,
      input.title?.trim() || null,
      input.quoteText?.trim() || null,
      input.comment?.trim() || null,
      input.bookId,
      input.page,
      input.date || today(),
      input.favorite ? 1 : 0,
      now,
      normalize(input.title) ?? '',
      input.quoteText == null ? null : normalize(input.quoteText),
      input.comment == null ? null : normalize(input.comment),
    ];
    if (!id) {
      const result = await raw.runAsync(
        `INSERT INTO entries
         (type,title,quoteText,comment,bookId,page,date,favorite,createdAt,updatedAt,titleNorm,quoteNorm,commentNorm)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7], input.createdAt || now, now, values[9], values[10], values[11]],
      );
      id = Number(result.lastInsertRowId);
    } else {
      await raw.runAsync(
        `UPDATE entries SET type=?,title=?,quoteText=?,comment=?,bookId=?,page=?,date=?,favorite=?,
         updatedAt=?,titleNorm=?,quoteNorm=?,commentNorm=? WHERE id=?`,
        [values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7], now, values[9], values[10], values[11], id],
      );
    }
    await raw.runAsync('DELETE FROM entry_tags WHERE entryId = ?', [id]);
    const unique = new Map<string, string>();
    for (const rawName of tagNames) {
      const name = rawName.trim();
      if (!name) continue;
      const norm = normalize(name) ?? '';
      if (!unique.has(norm)) unique.set(norm, name);
    }
    for (const [norm, name] of unique) {
      const existing = await raw.getFirstAsync<{ id: number }>('SELECT id FROM tags WHERE nameNorm = ?', [norm]);
      let tagId = existing?.id;
      if (!tagId) {
        const inserted = await raw.runAsync('INSERT INTO tags (name,nameNorm,createdAt) VALUES (?,?,?)', [name, norm, now]);
        tagId = Number(inserted.lastInsertRowId);
      }
      await raw.runAsync('INSERT OR IGNORE INTO entry_tags (entryId,tagId) VALUES (?,?)', [id, tagId]);
    }
  });
  return id;
}

export async function deleteEntry(id: number): Promise<void> {
  const raw = getSqlite();
  const audio = await raw.getFirstAsync<EntryAudio>('SELECT * FROM entry_audio WHERE entryId = ?', [id]);
  await raw.withTransactionAsync(async () => {
    await raw.runAsync('DELETE FROM review_items WHERE entryId = ?', [id]);
    await raw.runAsync('UPDATE pdf_highlights SET entryId = NULL WHERE entryId = ?', [id]);
    await raw.runAsync('DELETE FROM entries WHERE id = ?', [id]);
  });
  if (audio?.fileName) {
    await FS.deleteAsync(`${FS.documentDirectory}${audio.fileName}`, { idempotent: true });
  }
}

export async function toggleEntryFavorite(id: number): Promise<boolean> {
  const entry = await getEntry(id);
  if (!entry) throw new Error('entry-not-found');
  const favorite = entry.favorite ? 0 : 1;
  await getDb().update(entries).set({ favorite, updatedAt: Date.now() }).where(eq(entries.id, id));
  return favorite === 1;
}

export async function linkEntryBook(entryId: number, bookId: number | null): Promise<void> {
  await getDb().update(entries).set({ bookId, updatedAt: Date.now() }).where(eq(entries.id, entryId));
}

export async function entryCounts(): Promise<[number, number, number, number, number, number]> {
  const row = await getSqlite().getFirstAsync<{
    total: number;
    quote: number;
    benefit: number;
    summary: number;
    question: number;
    opinion: number;
  }>(
    `SELECT COUNT(*) AS total,
      SUM(CASE WHEN type=0 THEN 1 ELSE 0 END) AS quote,
      SUM(CASE WHEN type=1 THEN 1 ELSE 0 END) AS benefit,
      SUM(CASE WHEN type=2 THEN 1 ELSE 0 END) AS summary,
      SUM(CASE WHEN type=3 THEN 1 ELSE 0 END) AS question,
      SUM(CASE WHEN type=4 THEN 1 ELSE 0 END) AS opinion FROM entries`,
  );
  return [row?.total ?? 0, row?.quote ?? 0, row?.benefit ?? 0, row?.summary ?? 0, row?.question ?? 0, row?.opinion ?? 0];
}

export function parseTags(raw: string): string[] {
  return raw
    .split(/[,،]/)
    .map((s) => s.trim())
    .filter(Boolean);
}

export function joinTags(rows: EntryTagRow[]): string {
  return rows.map((r) => r.name).join('، ');
}
