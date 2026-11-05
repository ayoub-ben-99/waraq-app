// Ported from app/src/main/java/com/waraq/app/data/repo/ReviewScheduler.java
import { addDays } from './dates';

export const DEFAULT_INTERVALS = [1, 3, 7, 16, 35];

export const reviewResults = { FORGOT: 0, PARTIAL: 1, GOOD: 2 } as const;

export type Schedule = {
  intervalIndex: number;
  dueDate: number;
  intervalDays: number;
};

export function initial(intervals: number[], today: number): Schedule {
  const safe = sanitize(intervals);
  return { intervalIndex: 0, dueDate: addDays(today, safe[0]), intervalDays: safe[0] };
}

export function afterGrade(
  intervals: number[],
  currentIndex: number,
  result: number,
  today: number,
): Schedule {
  const safe = sanitize(intervals);
  let idx: number;
  if (result === reviewResults.FORGOT) idx = 0;
  else if (result === reviewResults.PARTIAL)
    idx = Math.min(Math.max(currentIndex, 0), safe.length - 1);
  else if (result === reviewResults.GOOD)
    idx = Math.min(Math.max(currentIndex, 0) + 1, safe.length - 1);
  else throw new Error('bad-result');
  const days = safe[idx];
  return { intervalIndex: idx, dueDate: addDays(today, days), intervalDays: days };
}

export function sanitize(intervals: number[] | null | undefined): number[] {
  if (!intervals || intervals.length === 0) return [...DEFAULT_INTERVALS];
  const out = intervals.filter((v) => v > 0).map((v) => Math.min(v, 365));
  return out.length ? out : [...DEFAULT_INTERVALS];
}

export function parse(text: string | null): number[] | null {
  if (text == null) return null;
  const parts = text.split(/[,،\s]+/);
  const out: number[] = [];
  for (const p of parts) {
    if (!p.trim()) continue;
    if (!/^\d+$/.test(p.trim())) return null;
    const v = Number(p);
    if (v <= 0 || v > 365) return null;
    out.push(v);
  }
  return out.length ? out : null;
}

export function join(intervals: number[]): string {
  return intervals.join(', ');
}
