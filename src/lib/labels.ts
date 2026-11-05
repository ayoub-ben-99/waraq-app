// Ported from app/src/main/java/com/waraq/app/ui/Ui.java
import { bookStatuses, entryTypes } from './arabicText';
import { t } from './strings';

export const bookStatusList = [
  bookStatuses.TO_READ,
  bookStatuses.READING,
  bookStatuses.COMPLETED,
  bookStatuses.PAUSED,
  bookStatuses.ABANDONED,
] as const;

export const entryTypeList = [
  entryTypes.QUOTE,
  entryTypes.BENEFIT,
  entryTypes.SUMMARY,
  entryTypes.QUESTION,
  entryTypes.OPINION,
] as const;

export function bookStatusLabel(status: number): string {
  switch (status) {
    case bookStatuses.READING:
      return t.bookStatusReading;
    case bookStatuses.COMPLETED:
      return t.bookStatusCompleted;
    case bookStatuses.PAUSED:
      return t.bookStatusPaused;
    case bookStatuses.ABANDONED:
      return t.bookStatusAbandoned;
    default:
      return t.bookStatusToRead;
  }
}

export function entryTypeLabel(type: number): string {
  switch (type) {
    case entryTypes.QUOTE:
      return t.entryQuote;
    case entryTypes.SUMMARY:
      return t.entrySummary;
    case entryTypes.QUESTION:
      return t.entryQuestion;
    case entryTypes.OPINION:
      return t.entryOpinion;
    default:
      return t.entryBenefit;
  }
}

export function entryDisplayText(entry: {
  title?: string | null;
  quoteText?: string | null;
  comment?: string | null;
}): string {
  return entry.quoteText?.trim() || entry.comment?.trim() || entry.title?.trim() || '';
}

export function formatArabicCount(n: number, one: string, two: string, few: string, many: string): string {
  const mod = n % 100;
  if (n === 1) return one;
  if (n === 2) return two;
  if (mod >= 3 && mod <= 10) return few.replace('{n}', String(n));
  return many.replace('{n}', String(n));
}
