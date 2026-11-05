// Ported from app/src/main/java/com/waraq/app/data/repo/SummaryRepository.java
import { eq } from 'drizzle-orm';
import { getDb, getSqlite } from '../db/client';
import { summaries, type BookSummary } from '../db/schema';

export type SummaryInput = {
  bookId: number;
  coreIdea: string | null;
  keyIdeas: string | null;
  learned: string | null;
  agreeDisagree: string | null;
  applications: string | null;
  questions: string | null;
  freeText: string | null;
};

export function summaryIsEmpty(s: SummaryInput): boolean {
  return [s.coreIdea, s.keyIdeas, s.learned, s.agreeDisagree, s.applications, s.questions, s.freeText].every(
    (v) => v == null || v.trim().length === 0,
  );
}

export async function loadSummary(bookId: number): Promise<BookSummary | null> {
  return (await getDb().select().from(summaries).where(eq(summaries.bookId, bookId)).get()) ?? null;
}

export async function saveSummary(input: SummaryInput): Promise<void> {
  const raw = getSqlite();
  const existing = await loadSummary(input.bookId);
  if (summaryIsEmpty(input)) {
    if (existing) await raw.runAsync('DELETE FROM summaries WHERE bookId=?', [input.bookId]);
    return;
  }
  const now = Date.now();
  const clean = (v: string | null) => (v == null || !v.trim() ? null : v.trim());
  if (!existing) {
    await raw.runAsync(
      `INSERT INTO summaries
       (bookId,coreIdea,keyIdeas,learned,agreeDisagree,applications,questions,freeText,updatedAt)
       VALUES (?,?,?,?,?,?,?,?,?)`,
      [input.bookId, clean(input.coreIdea), clean(input.keyIdeas), clean(input.learned), clean(input.agreeDisagree), clean(input.applications), clean(input.questions), clean(input.freeText), now],
    );
  } else {
    await raw.runAsync(
      `UPDATE summaries SET coreIdea=?,keyIdeas=?,learned=?,agreeDisagree=?,applications=?,
       questions=?,freeText=?,updatedAt=? WHERE bookId=?`,
      [clean(input.coreIdea), clean(input.keyIdeas), clean(input.learned), clean(input.agreeDisagree), clean(input.applications), clean(input.questions), clean(input.freeText), now, input.bookId],
    );
  }
}

export async function allSummaries(): Promise<BookSummary[]> {
  return getDb().select().from(summaries);
}

export async function summaryCount(): Promise<number> {
  const row = await getSqlite().getFirstAsync<{ n: number }>(
    `SELECT COUNT(*) AS n FROM summaries WHERE
      TRIM(COALESCE(coreIdea,'')) <> '' OR TRIM(COALESCE(keyIdeas,'')) <> '' OR
      TRIM(COALESCE(learned,'')) <> '' OR TRIM(COALESCE(agreeDisagree,'')) <> '' OR
      TRIM(COALESCE(applications,'')) <> '' OR TRIM(COALESCE(questions,'')) <> '' OR
      TRIM(COALESCE(freeText,'')) <> ''`,
  );
  return row?.n ?? 0;
}
