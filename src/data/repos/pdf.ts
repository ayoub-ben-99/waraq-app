// Ported from app/src/main/java/com/waraq/app/data/repo/PdfRepository.java
import * as FS from 'expo-file-system/legacy';
import { normalize } from '../../lib/arabicText';
import { bookStatuses } from '../../lib/arabicText';
import { today } from '../../lib/dates';
import { getSqlite } from '../db/client';
import type { Book, PdfDocument, PdfHighlight } from '../db/schema';
import { extractCover, importPdf } from '../../features/pdf/native';

export const COLOR_YELLOW = 0x88ffe082;
export const COLOR_GREEN = 0x8834a853;
export const COLOR_BLUE = 0x8864b5f6;

export type ImportedPdf = Awaited<ReturnType<typeof importPdf>>;

export async function importPdfToBook(
  bookId: number,
  uri: string,
  author: string | null,
  replace: boolean,
): Promise<PdfDocument> {
  const imported = await importPdf(uri);
  const raw = getSqlite();
  const now = Date.now();
  let docId = 0;
  let targetBookId = bookId;
  await raw.withTransactionAsync(async () => {
    let oldPath: string | null = null;
    if (targetBookId > 0) {
      const existing = await raw.getFirstAsync<{ id: number; localPath: string | null }>(
        'SELECT id,localPath FROM pdf_docs WHERE bookId=?',
        [targetBookId],
      );
      if (existing) {
        if (!replace) throw new Error('pdf-already-linked');
        oldPath = existing.localPath;
        await raw.runAsync('DELETE FROM pdf_docs WHERE id=?', [existing.id]);
      }
      const book = await raw.getFirstAsync<Book>('SELECT * FROM books WHERE id=?', [targetBookId]);
      if (!book) throw new Error('book-missing');
      await raw.runAsync(
        'UPDATE books SET totalPages=?, status=?, updatedAt=? WHERE id=?',
        [imported.pageCount, book.status === bookStatuses.TO_READ ? bookStatuses.READING : book.status, now, targetBookId],
      );
    } else {
      const fallback = imported.displayName.replace(/\.pdf$/i, '');
      const result = await raw.runAsync(
        `INSERT INTO books
         (title,author,description,coverPath,categoryId,status,rating,totalPages,currentPage,favorite,
          createdAt,updatedAt,startedAt,finishedAt,titleNorm,authorNorm)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        [fallback, author, null, null, null, bookStatuses.READING, null, imported.pageCount, 0, 0, now, now, now, null, normalize(fallback) ?? '', author == null ? null : normalize(author)],
      );
      targetBookId = Number(result.lastInsertRowId);
    }
    const doc = await raw.runAsync(
      `INSERT INTO pdf_docs
       (bookId,displayName,sourceUri,localPath,pageCount,lastPage,lastOffset,sha256,sizeBytes,importedAt)
       VALUES (?,?,?,?,?,?,?,?,?,?)`,
      [targetBookId, imported.displayName.replace(/\.pdf$/i, ''), uri, imported.relativePath, imported.pageCount, 0, 0, imported.sha256, imported.sizeBytes, now],
    );
    docId = Number(doc.lastInsertRowId);
    if (oldPath) await FS.deleteAsync(`${FS.documentDirectory}${oldPath}`, { idempotent: true });
  });
  try {
    const cover = await extractCover(imported.absolutePath, targetBookId);
    if (cover) {
      await raw.runAsync('UPDATE books SET coverPath=?, updatedAt=? WHERE id=? AND coverPath IS NULL', [cover, Date.now(), targetBookId]);
    }
  } catch {
    // الغلاف اختياري؛ فشل استخراجه لا يبطل الاستيراد
  }
  const doc = await documentById(docId);
  if (!doc) throw new Error('pdf-insert-failed');
  return doc;
}

export async function documentById(id: number): Promise<PdfDocument | null> {
  return (await getSqlite().getFirstAsync<PdfDocument>('SELECT * FROM pdf_docs WHERE id=?', [id])) ?? null;
}

export async function documentForBook(bookId: number): Promise<PdfDocument | null> {
  return (await getSqlite().getFirstAsync<PdfDocument>('SELECT * FROM pdf_docs WHERE bookId=?', [bookId])) ?? null;
}

export async function allDocuments(): Promise<PdfDocument[]> {
  return getSqlite().getAllAsync<PdfDocument>('SELECT * FROM pdf_docs');
}

export async function savePosition(docId: number, bookId: number, page: number, offset: number): Promise<void> {
  const raw = getSqlite();
  const now = Date.now();
  await raw.withTransactionAsync(async () => {
    await raw.runAsync('UPDATE pdf_docs SET lastPage=?,lastOffset=? WHERE id=?', [page, offset, docId]);
    await raw.runAsync(
      'UPDATE books SET currentPage=MAX(currentPage,?), updatedAt=? WHERE id=?',
      [page + 1, now, bookId],
    );
  });
}

export async function highlightsFor(docId: number): Promise<PdfHighlight[]> {
  return getSqlite().getAllAsync<PdfHighlight>('SELECT * FROM pdf_highlights WHERE pdfDocId=? ORDER BY page,id', [docId]);
}

export async function addHighlight(
  doc: PdfDocument,
  page: number,
  rectsJson: string,
  text: string,
  color: number,
): Promise<PdfHighlight> {
  const raw = getSqlite();
  const result = await raw.runAsync(
    'INSERT INTO pdf_highlights (pdfDocId,page,rects,text,color,entryId,createdAt) VALUES (?,?,?,?,?,?,?)',
    [doc.id, page, rectsJson || '[]', text || '', color || COLOR_YELLOW, null, Date.now()],
  );
  return (await raw.getFirstAsync<PdfHighlight>('SELECT * FROM pdf_highlights WHERE id=?', [Number(result.lastInsertRowId)])) as PdfHighlight;
}

export async function deleteHighlight(id: number): Promise<void> {
  await getSqlite().runAsync('DELETE FROM pdf_highlights WHERE id=?', [id]);
}

export async function createEntryFromHighlight(
  highlight: PdfHighlight,
  bookId: number,
  type: number,
): Promise<number> {
  const raw = getSqlite();
  const now = Date.now();
  let entryId = 0;
  await raw.withTransactionAsync(async () => {
    const result = await raw.runAsync(
      `INSERT INTO entries
       (type,title,quoteText,comment,bookId,page,date,favorite,createdAt,updatedAt,titleNorm,quoteNorm,commentNorm)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [type >= 0 && type <= 4 ? type : 0, null, highlight.text, null, bookId > 0 ? bookId : null, highlight.page + 1, today(), 0, now, now, '', normalize(highlight.text), null],
    );
    entryId = Number(result.lastInsertRowId);
    await raw.runAsync('UPDATE pdf_highlights SET entryId=? WHERE id=?', [entryId, highlight.id]);
  });
  return entryId;
}

export async function deleteDocument(doc: PdfDocument): Promise<void> {
  await getSqlite().runAsync('DELETE FROM pdf_docs WHERE id=?', [doc.id]);
  if (doc.localPath) await FS.deleteAsync(`${FS.documentDirectory}${doc.localPath}`, { idempotent: true });
}
