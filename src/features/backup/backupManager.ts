// Ported from app/src/main/java/com/waraq/app/backup/BackupManager.java
import * as FS from 'expo-file-system/legacy';
import { unzip, zip } from 'react-native-zip-archive';
import { normalize } from '../../lib/arabicText';
import { dateStamp, formatIso } from '../../lib/dates';
import { getSqlite } from '../../data/db/client';
import type { Book, BookSummary, Category, EntryAudio, KnowledgeEntry, PdfDocument, PdfHighlight, ReadingSession, ReviewItem, ReviewLog, Tag } from '../../data/db/schema';

export const SCHEMA_VERSION = 3;
export const MANIFEST = 'manifest.json';
export const DATA = 'data.json';
export const COVERS_PREFIX = 'covers/';
export const PDFS_PREFIX = 'pdfs/';
export const AUDIOS_PREFIX = 'audios/';

export class BackupError extends Error {
  code: string;
  constructor(code: string) {
    super(code);
    this.code = code;
  }
}

type Json = Record<string, unknown>;

export type BackupData = {
  schema: number;
  createdAt: string;
  categories: Json[];
  books: Json[];
  sessions: Json[];
  entries: Json[];
  tags: Json[];
  entryTags: [number, number][];
  summaries: Json[];
  reviews: Json[];
  reviewLogs: Json[];
  settings: { key: string; value: string | null }[];
  pdfDocs: Json[];
  highlights: Json[];
  audios: Json[];
  covers: string[];
  pdfFiles: string[];
  audioFiles: string[];
  dir: string;
};

const n = (v: unknown, d = 0): number => (typeof v === 'number' && Number.isFinite(v) ? v : d);
const ns = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);
const s = (v: unknown, d = ''): string => (typeof v === 'string' ? v : d);
const sn = (v: unknown): string | null => (typeof v === 'string' ? v : null);
const b = (v: unknown): number => (v === true || v === 1 ? 1 : 0);
const arr = (v: unknown): Json[] => (Array.isArray(v) ? (v.filter((x) => x && typeof x === 'object') as Json[]) : []);

export async function exportBackup(includePdfFiles: boolean): Promise<{ uri: string; count: number }> {
  const raw = getSqlite();
  const work = `${FS.cacheDirectory}waraq-backup-work/`;
  const outDir = `${FS.cacheDirectory}waraq-backup-files/`;
  await FS.deleteAsync(work, { idempotent: true });
  await FS.deleteAsync(outDir, { idempotent: true });
  await FS.makeDirectoryAsync(work, { intermediates: true });
  await FS.makeDirectoryAsync(outDir, { intermediates: true });
  const categories = await raw.getAllAsync<Category>('SELECT * FROM categories ORDER BY id');
  const books = await raw.getAllAsync<Book>('SELECT * FROM books ORDER BY id');
  const sessions = await raw.getAllAsync<ReadingSession>('SELECT * FROM sessions ORDER BY id');
  const entries = await raw.getAllAsync<KnowledgeEntry>('SELECT * FROM entries ORDER BY id');
  const tags = await raw.getAllAsync<Tag>('SELECT * FROM tags ORDER BY id');
  const summaries = await raw.getAllAsync<BookSummary>('SELECT * FROM summaries ORDER BY id');
  const reviews = await raw.getAllAsync<ReviewItem>('SELECT * FROM review_items ORDER BY id');
  const reviewLogs = await raw.getAllAsync<ReviewLog>('SELECT * FROM review_logs ORDER BY id');
  const pdfDocs = await raw.getAllAsync<PdfDocument>('SELECT * FROM pdf_docs ORDER BY id');
  const highlights = await raw.getAllAsync<PdfHighlight>('SELECT * FROM pdf_highlights ORDER BY id');
  const audioRows = await raw.getAllAsync<EntryAudio>('SELECT * FROM entry_audio ORDER BY id');
  const links = await raw.getAllAsync<{ entryId: number; tagId: number }>('SELECT * FROM entry_tags ORDER BY entryId,tagId');
  const settings = await raw.getAllAsync<{ key: string; value: string | null }>('SELECT * FROM settings ORDER BY key');

  const coverDir = `${work}${COVERS_PREFIX}`;
  const pdfDir = `${work}${PDFS_PREFIX}`;
  const audioDir = `${work}${AUDIOS_PREFIX}`;
  await FS.makeDirectoryAsync(coverDir, { intermediates: true });
  await FS.makeDirectoryAsync(pdfDir, { intermediates: true });
  await FS.makeDirectoryAsync(audioDir, { intermediates: true });

  const covers: string[] = [];
  for (const book of books) {
    if (!book.coverPath) continue;
    const source = `${FS.documentDirectory}${book.coverPath}`;
    const info = await FS.getInfoAsync(source);
    if (!info.exists) continue;
    const name = book.coverPath.split('/').pop() as string;
    await FS.copyAsync({ from: source, to: `${coverDir}${name}` });
    covers.push(name);
  }

  const audios: Json[] = [];
  const audioFiles: string[] = [];
  for (const row of audioRows) {
    const name = row.fileName.split('/').pop() as string;
    const source = `${FS.documentDirectory}${row.fileName}`;
    const info = await FS.getInfoAsync(source);
    if (!info.exists || !('size' in info) || info.size === 0) continue;
    await FS.copyAsync({ from: source, to: `${audioDir}${name}` });
    audioFiles.push(name);
    audios.push({
      id: row.id,
      entryId: row.entryId,
      fileName: row.fileName,
      durationMs: row.durationMs,
      sizeBytes: 'size' in info ? info.size : row.sizeBytes,
      createdAt: row.createdAt,
    });
  }

  const pdfFiles: string[] = [];
  if (includePdfFiles) {
    const seen = new Set<string>();
    for (const doc of pdfDocs) {
      if (!doc.localPath || !doc.sha256 || seen.has(doc.sha256)) continue;
      const source = `${FS.documentDirectory}${doc.localPath}`;
      const info = await FS.getInfoAsync(source);
      if (!info.exists) continue;
      const name = `${doc.sha256.replace(/[^a-zA-Z0-9]/g, '')}.pdf`;
      await FS.copyAsync({ from: source, to: `${pdfDir}${name}` });
      pdfFiles.push(name);
      seen.add(doc.sha256);
    }
  }

  const data = {
    schema: SCHEMA_VERSION,
    createdAt: formatIso(Date.now()),
    categories: categories.map((c) => ({ id: c.id, name: c.name, createdAt: c.createdAt })),
    books: books.map((x) => ({
      id: x.id,
      title: x.title,
      author: x.author,
      description: x.description,
      coverPath: x.coverPath,
      categoryId: x.categoryId,
      status: x.status,
      rating: x.rating,
      totalPages: x.totalPages,
      currentPage: x.currentPage,
      favorite: !!x.favorite,
      createdAt: x.createdAt,
      updatedAt: x.updatedAt,
      startedAt: x.startedAt,
      finishedAt: x.finishedAt,
    })),
    sessions: sessions.map((x) => ({
      id: x.id,
      bookId: x.bookId,
      startPage: x.startPage,
      endPage: x.endPage,
      durationMinutes: x.durationMinutes,
      date: x.date,
      note: x.note,
      historical: !!x.historical,
      createdAt: x.createdAt,
    })),
    entries: entries.map((x) => ({
      id: x.id,
      type: x.type,
      title: x.title,
      quoteText: x.quoteText,
      comment: x.comment,
      bookId: x.bookId,
      page: x.page,
      date: x.date,
      favorite: !!x.favorite,
      createdAt: x.createdAt,
      updatedAt: x.updatedAt,
    })),
    tags: tags.map((x) => ({ id: x.id, name: x.name, createdAt: x.createdAt })),
    entryTags: links.map((l) => [l.entryId, l.tagId]),
    summaries: summaries.map((x) => ({
      bookId: x.bookId,
      coreIdea: x.coreIdea,
      keyIdeas: x.keyIdeas,
      learned: x.learned,
      agreeDisagree: x.agreeDisagree,
      applications: x.applications,
      questions: x.questions,
      freeText: x.freeText,
      updatedAt: x.updatedAt,
    })),
    reviews: reviews.map((x) => ({
      entryId: x.entryId,
      dueDate: x.dueDate,
      intervalIndex: x.intervalIndex,
      lastReviewedAt: x.lastReviewedAt,
      lastResult: x.lastResult,
      totalReviews: x.totalReviews,
      createdAt: x.createdAt,
    })),
    reviewLogs: reviewLogs.map((x) => ({
      entryId: x.entryId,
      reviewedAt: x.reviewedAt,
      result: x.result,
      nextDueAt: x.nextDueAt,
      intervalDays: x.intervalDays,
    })),
    settings: settings.map((x) => ({ key: x.key, value: x.value })),
    pdfDocs: pdfDocs.map((x) => ({
      id: x.id,
      bookId: x.bookId,
      displayName: x.displayName,
      sourceUri: x.sourceUri,
      pageCount: x.pageCount,
      lastPage: x.lastPage,
      lastOffset: x.lastOffset,
      sha256: x.sha256,
      sizeBytes: x.sizeBytes,
      importedAt: x.importedAt,
      fileIncluded: includePdfFiles && pdfFiles.includes(`${x.sha256.replace(/[^a-zA-Z0-9]/g, '')}.pdf`),
    })),
    highlights: highlights.map((x) => ({
      id: x.id,
      pdfDocId: x.pdfDocId,
      page: x.page,
      rects: x.rects,
      text: x.text,
      color: x.color,
      entryId: x.entryId,
      createdAt: x.createdAt,
    })),
    audios,
  };
  const manifest = {
    app: 'waraq',
    schema: SCHEMA_VERSION,
    createdAt: data.createdAt,
    books: books.length,
    sessions: sessions.length,
    entries: entries.length,
    tags: tags.length,
    reviews: reviews.length,
    covers: covers.length,
    pdfDocs: pdfDocs.length,
    highlights: highlights.length,
    audios: audios.length,
    audioFiles: audioFiles.length,
    pdfFiles: pdfFiles.length,
    pdfFilesIncluded: includePdfFiles && pdfFiles.length > 0,
  };
  await FS.writeAsStringAsync(`${work}${MANIFEST}`, JSON.stringify(manifest, null, 2));
  await FS.writeAsStringAsync(`${work}${DATA}`, JSON.stringify(data, null, 2));
  const stamp = dateStamp(Date.now());
  const target = `${outDir}waraq-backup-${stamp}.waraq`;
  await zip(work, target);
  await FS.deleteAsync(work, { idempotent: true });
  const count =
    categories.length + books.length + sessions.length + entries.length + tags.length + links.length +
    summaries.length + reviews.length + reviewLogs.length + pdfDocs.length + highlights.length;
  return { uri: target, count };
}

export async function readBackup(uri: string): Promise<BackupData> {
  const dir = `${FS.cacheDirectory}waraq-restore/`;
  await FS.deleteAsync(dir, { idempotent: true });
  await FS.makeDirectoryAsync(dir, { intermediates: true });
  try {
    await unzip(uri, dir);
  } catch {
    throw new BackupError('corrupt');
  }
  const manifestInfo = await FS.getInfoAsync(`${dir}${MANIFEST}`);
  const dataInfo = await FS.getInfoAsync(`${dir}${DATA}`);
  if (!manifestInfo.exists || !dataInfo.exists) throw new BackupError('invalid');
  let manifest: Json;
  let root: Json;
  try {
    manifest = JSON.parse(await FS.readAsStringAsync(`${dir}${MANIFEST}`)) as Json;
    root = JSON.parse(await FS.readAsStringAsync(`${dir}${DATA}`)) as Json;
  } catch {
    throw new BackupError('corrupt');
  }
  if (s(manifest.app) !== 'waraq') throw new BackupError('invalid');
  const schema = n(manifest.schema, -1);
  if (schema <= 0) throw new BackupError('invalid');
  if (schema > SCHEMA_VERSION) throw new BackupError(`newer:${schema}`);
  const categories = arr(root.categories);
  const books = arr(root.books);
  const sessions = arr(root.sessions);
  const entries = arr(root.entries);
  const tags = arr(root.tags);
  const reviews = arr(root.reviews);
  const pdfDocs = arr(root.pdfDocs);
  const highlights = arr(root.highlights);
  const audios = arr(root.audios);
  const countChecks: [string, number][] = [
    ['books', books.length],
    ['sessions', sessions.length],
    ['entries', entries.length],
    ['tags', tags.length],
    ['reviews', reviews.length],
    ['pdfDocs', pdfDocs.length],
    ['highlights', highlights.length],
    ['audios', audios.length],
  ];
  for (const [key, actual] of countChecks) {
    if (manifest[key] != null && n(manifest[key], -1) !== actual) throw new BackupError('corrupt');
  }
  const coversInfo = await FS.getInfoAsync(`${dir}${COVERS_PREFIX}`);
  const covers = coversInfo.exists ? await FS.readDirectoryAsync(`${dir}${COVERS_PREFIX}`) : [];
  const audioInfo = await FS.getInfoAsync(`${dir}${AUDIOS_PREFIX}`);
  const audioFiles = audioInfo.exists ? await FS.readDirectoryAsync(`${dir}${AUDIOS_PREFIX}`) : [];
  const pdfInfo = await FS.getInfoAsync(`${dir}${PDFS_PREFIX}`);
  const pdfFiles = pdfInfo.exists ? await FS.readDirectoryAsync(`${dir}${PDFS_PREFIX}`) : [];
  for (const audio of audios) {
    const name = s(audio.fileName).split('/').pop() as string;
    if (!audioFiles.includes(name)) throw new BackupError('audio-missing');
  }
  if (books.length === 0 && entries.length === 0 && pdfDocs.length === 0) throw new BackupError('invalid');
  return {
    schema,
    createdAt: s(manifest.createdAt),
    categories,
    books,
    sessions,
    entries,
    tags,
    entryTags: Array.isArray(root.entryTags)
      ? (root.entryTags as unknown[])
          .filter((x): x is [number, number] => Array.isArray(x) && x.length >= 2)
          .map((x) => [n(x[0]), n(x[1])])
      : [],
    summaries: arr(root.summaries),
    reviews,
    reviewLogs: arr(root.reviewLogs),
    settings: Array.isArray(root.settings)
      ? (root.settings as Json[]).map((x) => ({ key: s(x.key), value: sn(x.value) }))
      : [],
    pdfDocs,
    highlights,
    audios,
    covers,
    pdfFiles,
    audioFiles,
    dir,
  };
}

const take = (pool: Map<string, number[]>, key: string): number | null => {
  const list = pool.get(key);
  if (!list || list.length === 0) return null;
  return list.pop() as number;
};

const remember = (pool: Map<string, number[]>, key: string, id: number) => {
  const list = pool.get(key) ?? [];
  list.push(id);
  pool.set(key, list);
};

function entryKey(row: Json): string {
  return `e|${ns(row.bookId)}|${n(row.type)}|${n(row.date)}|${n(row.createdAt)}|${s(row.title)}|${s(row.quoteText)}|${s(row.comment)}`;
}

export async function applyRestore(data: BackupData, replace: boolean): Promise<{ books: number; entries: number }> {
  const raw = getSqlite();
  const result = { books: 0, entries: 0 };
  const knownEntries = new Map<string, number[]>();
  const knownSessions = new Map<string, number[]>();
  const knownLogs = new Map<string, number[]>();
  const knownHighlights = new Map<string, number[]>();
  const knownLinks = new Map<string, number[]>();
  if (!replace) {
    const existingEntries = await raw.getAllAsync<KnowledgeEntry>('SELECT * FROM entries');
    for (const row of existingEntries) remember(knownEntries, entryKey(row as unknown as Json), row.id);
    const existingSessions = await raw.getAllAsync<ReadingSession>('SELECT * FROM sessions');
    for (const row of existingSessions) {
      remember(
        knownSessions,
        `s|${row.bookId}|${row.date}|${row.startPage}|${row.endPage}|${row.durationMinutes}|${row.historical}|${row.note ?? ''}|${row.createdAt}`,
        row.id,
      );
    }
    const existingLogs = await raw.getAllAsync<ReviewLog>('SELECT * FROM review_logs');
    for (const row of existingLogs) {
      remember(knownLogs, `l|${row.entryId}|${row.reviewedAt}|${row.result}|${row.nextDueAt}|${row.intervalDays}`, row.id);
    }
    const existingHighlights = await raw.getAllAsync<PdfHighlight>('SELECT * FROM pdf_highlights');
    for (const row of existingHighlights) {
      remember(knownHighlights, `h|${row.pdfDocId}|${row.page}|${row.rects}|${row.text}|${row.color}|${row.createdAt}`, row.id);
    }
    const existingLinks = await raw.getAllAsync<{ entryId: number; tagId: number }>('SELECT * FROM entry_tags');
    for (const row of existingLinks) remember(knownLinks, `t|${row.entryId}|${row.tagId}`, 0);
  }

  const categoryMap = new Map<number, number>();
  const bookMap = new Map<number, number>();
  const tagMap = new Map<number, number>();
  const entryMap = new Map<number, number>();
  const docMap = new Map<number, number>();
  const now = Date.now();

  await raw.withTransactionAsync(async () => {
    if (replace) {
      for (const table of ['entry_audio', 'pdf_highlights', 'pdf_docs', 'review_logs', 'review_items', 'summaries', 'entry_tags', 'entries', 'sessions', 'books', 'categories', 'tags', 'settings']) {
        await raw.runAsync(`DELETE FROM ${table}`);
      }
    }
    for (const c of data.categories) {
      const name = s(c.name);
      if (!name) continue;
      const norm = normalize(name) ?? '';
      const existing = replace ? null : await raw.getFirstAsync<Category>('SELECT * FROM categories WHERE nameNorm=?', [norm]);
      const id = existing?.id ?? Number((await raw.runAsync(
        'INSERT INTO categories (id,name,nameNorm,createdAt) VALUES (?,?,?,?)',
        [replace ? n(c.id) : null, name, norm, n(c.createdAt, now)],
      )).lastInsertRowId);
      if (existing) categoryMap.set(n(c.id), existing.id);
      else categoryMap.set(n(c.id), id);
    }
    for (const row of data.books) {
      const title = s(row.title).trim();
      if (!title) throw new BackupError('corrupt');
      const titleNorm = normalize(title) ?? '';
      const author = sn(row.author);
      const authorNorm = author == null ? null : normalize(author);
      const existing = replace
        ? null
        : await raw.getFirstAsync<Book>(
            'SELECT * FROM books WHERE titleNorm=? AND COALESCE(authorNorm,\'\')=COALESCE(?,\'\')',
            [titleNorm, authorNorm],
          );
      if (existing) {
        bookMap.set(n(row.id), existing.id);
        continue;
      }
      const oldCover = sn(row.coverPath);
      let coverPath: string | null = null;
      if (oldCover) {
        const base = oldCover.split('/').pop() as string;
        if (data.covers.includes(base)) {
          const targetDir = `${FS.documentDirectory}covers/`;
          await FS.makeDirectoryAsync(targetDir, { intermediates: true });
          await FS.copyAsync({ from: `${data.dir}${COVERS_PREFIX}${base}`, to: `${targetDir}${base}` });
          coverPath = `covers/${base}`;
        }
      }
      const categoryId = row.categoryId == null ? null : categoryMap.get(n(row.categoryId)) ?? null;
      const id = Number((await raw.runAsync(
        `INSERT INTO books
         (id,title,author,description,coverPath,categoryId,status,rating,totalPages,currentPage,favorite,
          createdAt,updatedAt,startedAt,finishedAt,titleNorm,authorNorm)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [replace ? n(row.id) : null, title, author, sn(row.description), coverPath, categoryId, n(row.status), ns(row.rating), ns(row.totalPages), n(row.currentPage), b(row.favorite), n(row.createdAt, now), n(row.updatedAt, now), ns(row.startedAt), ns(row.finishedAt), titleNorm, authorNorm],
      )).lastInsertRowId);
      bookMap.set(n(row.id), id);
      result.books++;
    }
    for (const row of data.tags) {
      const name = s(row.name);
      if (!name) continue;
      const norm = normalize(name) ?? '';
      const existing = replace ? null : await raw.getFirstAsync<Tag>('SELECT * FROM tags WHERE nameNorm=?', [norm]);
      const id = existing?.id ?? Number((await raw.runAsync(
        'INSERT INTO tags (id,name,nameNorm,createdAt) VALUES (?,?,?,?)',
        [replace ? n(row.id) : null, name, norm, n(row.createdAt, now)],
      )).lastInsertRowId);
      tagMap.set(n(row.id), id);
    }
    for (const row of data.entries) {
      const bookId = row.bookId == null ? null : bookMap.get(n(row.bookId));
      if (row.bookId != null && bookId == null) throw new BackupError('orphan');
      const date = n(row.date, now);
      const createdAt = n(row.createdAt, now);
      const key = entryKey(row);
      const existing = take(knownEntries, key);
      if (existing != null) {
        entryMap.set(n(row.id), existing);
        continue;
      }
      const id = Number((await raw.runAsync(
        `INSERT INTO entries
         (id,type,title,quoteText,comment,bookId,page,date,favorite,createdAt,updatedAt,titleNorm,quoteNorm,commentNorm)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [replace ? n(row.id) : null, n(row.type), sn(row.title), sn(row.quoteText), sn(row.comment), bookId ?? null, ns(row.page), date, b(row.favorite), createdAt, n(row.updatedAt, now), normalize(sn(row.title)) ?? '', normalize(sn(row.quoteText)), normalize(sn(row.comment))],
      )).lastInsertRowId);
      entryMap.set(n(row.id), id);
      result.entries++;
    }
    for (const [oldEntry, oldTag] of data.entryTags) {
      const entryId = entryMap.get(oldEntry);
      const tagId = tagMap.get(oldTag);
      if (entryId == null || tagId == null) throw new BackupError('orphan');
      if (take(knownLinks, `t|${entryId}|${tagId}`) != null) continue;
      await raw.runAsync('INSERT OR IGNORE INTO entry_tags (entryId,tagId) VALUES (?,?)', [entryId, tagId]);
    }
    for (const row of data.sessions) {
      const bookId = bookMap.get(n(row.bookId));
      if (bookId == null) throw new BackupError('orphan');
      const key = `s|${bookId}|${n(row.date)}|${n(row.startPage)}|${n(row.endPage)}|${n(row.durationMinutes)}|${b(row.historical)}|${s(row.note)}|${n(row.createdAt)}`;
      if (take(knownSessions, key) != null) continue;
      await raw.runAsync(
        'INSERT INTO sessions (id,bookId,startPage,endPage,durationMinutes,date,note,historical,createdAt) VALUES (?,?,?,?,?,?,?,?,?)',
        [replace ? n(row.id) : null, bookId, n(row.startPage), n(row.endPage), n(row.durationMinutes), n(row.date), sn(row.note), b(row.historical), n(row.createdAt, now)],
      );
    }
    for (const row of data.summaries) {
      const bookId = bookMap.get(n(row.bookId));
      if (bookId == null) throw new BackupError('orphan');
      await raw.runAsync(
        `INSERT INTO summaries
         (bookId,coreIdea,keyIdeas,learned,agreeDisagree,applications,questions,freeText,updatedAt)
         VALUES (?,?,?,?,?,?,?,?,?)
         ON CONFLICT(bookId) DO UPDATE SET coreIdea=excluded.coreIdea,keyIdeas=excluded.keyIdeas,
         learned=excluded.learned,agreeDisagree=excluded.agreeDisagree,applications=excluded.applications,
         questions=excluded.questions,freeText=excluded.freeText,updatedAt=excluded.updatedAt`,
        [bookId, sn(row.coreIdea), sn(row.keyIdeas), sn(row.learned), sn(row.agreeDisagree), sn(row.applications), sn(row.questions), sn(row.freeText), n(row.updatedAt, now)],
      );
    }
    for (const row of data.reviews) {
      const entryId = entryMap.get(n(row.entryId));
      if (entryId == null) throw new BackupError('orphan');
      const exists = await raw.getFirstAsync<{ id: number }>('SELECT id FROM review_items WHERE entryId=?', [entryId]);
      if (exists) continue;
      await raw.runAsync(
        `INSERT INTO review_items
         (entryId,dueDate,intervalIndex,lastReviewedAt,lastResult,totalReviews,createdAt)
         VALUES (?,?,?,?,?,?,?)`,
        [entryId, n(row.dueDate), n(row.intervalIndex), ns(row.lastReviewedAt), n(row.lastResult, -1), n(row.totalReviews), n(row.createdAt, now)],
      );
    }
    for (const row of data.reviewLogs) {
      const entryId = entryMap.get(n(row.entryId));
      if (entryId == null) throw new BackupError('orphan');
      const key = `l|${entryId}|${n(row.reviewedAt)}|${n(row.result)}|${n(row.nextDueAt)}|${n(row.intervalDays)}`;
      if (take(knownLogs, key) != null) continue;
      await raw.runAsync(
        'INSERT INTO review_logs (entryId,reviewedAt,result,nextDueAt,intervalDays) VALUES (?,?,?,?,?)',
        [entryId, n(row.reviewedAt), n(row.result), n(row.nextDueAt), n(row.intervalDays)],
      );
    }
    for (const a of data.audios) {
      const entryId = entryMap.get(n(a.entryId));
      if (entryId == null) continue;
      const base = s(a.fileName).split('/').pop() as string;
      if (!data.audioFiles.includes(base)) throw new BackupError('audio-missing');
      const targetDir = `${FS.documentDirectory}audio/`;
      await FS.makeDirectoryAsync(targetDir, { intermediates: true });
      const name = `${Date.now()}-${Math.random().toString(36).slice(2)}.m4a`;
      await FS.copyAsync({ from: `${data.dir}${AUDIOS_PREFIX}${base}`, to: `${targetDir}${name}` });
      await raw.runAsync(
        'INSERT OR REPLACE INTO entry_audio (id,entryId,fileName,durationMs,sizeBytes,createdAt) VALUES (?,?,?,?,?,?)',
        [replace ? n(a.id) : null, entryId, `audio/${name}`, n(a.durationMs), n(a.sizeBytes), n(a.createdAt, now)],
      );
    }
    for (const p of data.pdfDocs) {
      const bookId = bookMap.get(n(p.bookId));
      if (bookId == null) throw new BackupError('orphan');
      const sha = s(p.sha256);
      const name = `${sha.replace(/[^a-zA-Z0-9]/g, '')}.pdf`;
      let localPath: string | null = null;
      if (data.pdfFiles.includes(name)) {
        const targetDir = `${FS.documentDirectory}pdfs/`;
        await FS.makeDirectoryAsync(targetDir, { intermediates: true });
        await FS.copyAsync({ from: `${data.dir}${PDFS_PREFIX}${name}`, to: `${targetDir}${name}` });
        localPath = `pdfs/${name}`;
      }
      const existing = await raw.getFirstAsync<PdfDocument>('SELECT * FROM pdf_docs WHERE bookId=?', [bookId]);
      if (existing) {
        docMap.set(n(p.id), existing.id);
        if (localPath) await raw.runAsync('UPDATE pdf_docs SET localPath=?, sha256=?, sizeBytes=? WHERE id=?', [localPath, sha, n(p.sizeBytes), existing.id]);
        continue;
      }
      const id = Number((await raw.runAsync(
        `INSERT INTO pdf_docs
         (id,bookId,displayName,sourceUri,localPath,pageCount,lastPage,lastOffset,sha256,sizeBytes,importedAt)
         VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
        [replace ? n(p.id) : null, bookId, s(p.displayName, 'PDF'), sn(p.sourceUri), localPath, Math.max(1, n(p.pageCount, 1)), Math.max(0, n(p.lastPage)), n(p.lastOffset), sha, n(p.sizeBytes), n(p.importedAt, now)],
      )).lastInsertRowId);
      docMap.set(n(p.id), id);
    }
    for (const h of data.highlights) {
      const docId = docMap.get(n(h.pdfDocId));
      if (docId == null) throw new BackupError('orphan');
      const key = `h|${docId}|${n(h.page)}|${s(h.rects, '[]')}|${s(h.text)}|${n(h.color)}|${n(h.createdAt)}`;
      if (take(knownHighlights, key) != null) continue;
      await raw.runAsync(
        'INSERT INTO pdf_highlights (id,pdfDocId,page,rects,text,color,entryId,createdAt) VALUES (?,?,?,?,?,?,?,?)',
        [replace ? n(h.id) : null, docId, n(h.page), s(h.rects, '[]'), s(h.text), n(h.color), h.entryId == null ? null : entryMap.get(n(h.entryId)) ?? null, n(h.createdAt, now)],
      );
    }
    for (const row of data.settings) {
      await raw.runAsync(
        'INSERT INTO settings (key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
        [row.key, row.value],
      );
    }
  });
  await FS.deleteAsync(data.dir, { idempotent: true });
  return result;
}
