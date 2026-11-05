// Ported from app/src/main/java/com/waraq/app/data/DraftStore.java
import { getDraft, removeDraft, setDraft } from '../lib/prefs';

export type Draft = {
  entryId: number;
  type: number;
  title: string;
  quote: string;
  comment: string;
  tags: string;
  page: number | null;
  bookId: number;
  date: number;
  savedAt: number;
};

export function saveDraft(draft: Draft): void {
  setDraft(`draft:${draft.entryId}`, JSON.stringify(draft));
}

export function loadDraft(entryId: number): Draft | null {
  const raw = getDraft(`draft:${entryId}`);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Draft;
  } catch {
    clearDraft(entryId);
    return null;
  }
}

export function clearDraft(entryId: number): void {
  removeDraft(`draft:${entryId}`);
}

export function hasDraftContent(draft: Draft): boolean {
  return [draft.title, draft.quote, draft.comment, draft.tags].some((s) => s.trim().length > 0);
}
