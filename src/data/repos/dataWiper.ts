// Ported from app/src/main/java/com/waraq/app/data/repo/DataWiper.java
import { getSqlite } from '../db/client';
import { clearOcrCache } from '../../features/pdf/native';

export const WIPE_PROGRESS = 1;
export const WIPE_HIGHLIGHTS = 2;
export const WIPE_OCR = 4;

export type WipeResult = {
  booksReset: number;
  documentsReset: number;
  highlightsDeleted: number;
  ocrFilesDeleted: number;
};

export async function wipeData(flags: number): Promise<WipeResult> {
  const raw = getSqlite();
  const result: WipeResult = { booksReset: 0, documentsReset: 0, highlightsDeleted: 0, ocrFilesDeleted: 0 };
  if (flags & WIPE_PROGRESS) {
    const now = Date.now();
    const books = await raw.runAsync('UPDATE books SET currentPage=0, updatedAt=?', [now]);
    const docs = await raw.runAsync('UPDATE pdf_docs SET lastPage=0, lastOffset=0');
    result.booksReset = books.changes;
    result.documentsReset = docs.changes;
  }
  if (flags & WIPE_HIGHLIGHTS) {
    const marks = await raw.runAsync('DELETE FROM pdf_highlights');
    result.highlightsDeleted = marks.changes;
  }
  if (flags & WIPE_OCR) {
    result.ocrFilesDeleted = await clearOcrCache();
  }
  return result;
}
