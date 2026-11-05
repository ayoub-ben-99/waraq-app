// Ported from app/src/main/java/com/waraq/app/util/ArabicText.java
export function normalize(input: string | null | undefined): string | null {
  if (input == null) return null;
  let out = '';
  for (const c of input) {
    const code = c.codePointAt(0) ?? 0;
    if (code >= 0x064b && code <= 0x065f) continue;
    if (code === 0x0670 || code === 0x0640) continue;
    if (c === 'أ' || c === 'إ' || c === 'آ' || c === 'ٱ') out += 'ا';
    else if (c === 'ى' || c === 'ئ' || c === 'ي') out += 'ي';
    else if (c === 'ة') out += 'ه';
    else if (c === 'ؤ') out += 'و';
    else out += c.toLowerCase();
  }
  return out.replace(/\s+/g, ' ').trim();
}

export function likePattern(query: string): string {
  const n = normalize(query);
  if (n == null) return '%';
  return `%${n.replace(/%/g, '').replace(/_/g, '')}%`;
}

export function isBlank(s: string | null | undefined): boolean {
  return s == null || s.trim().length === 0;
}

export function wordCount(s: string | null | undefined): number {
  if (isBlank(s)) return 0;
  return (s as string).trim().split(/\s+/).length;
}

export const entryTypes = {
  QUOTE: 0,
  BENEFIT: 1,
  SUMMARY: 2,
  QUESTION: 3,
  OPINION: 4,
} as const;

export type EntryType = (typeof entryTypes)[keyof typeof entryTypes];

export const bookStatuses = {
  TO_READ: 0,
  READING: 1,
  COMPLETED: 2,
  PAUSED: 3,
  ABANDONED: 4,
} as const;

export type BookStatus = (typeof bookStatuses)[keyof typeof bookStatuses];

export function isValidBookStatus(s: number): boolean {
  return s >= 0 && s <= 4;
}

export function isValidEntryType(t: number): boolean {
  return t >= 0 && t <= 4;
}
