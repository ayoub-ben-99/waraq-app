// Ported from app/src/main/java/com/waraq/app/data/repo/SettingsRepository.java
import { eq } from 'drizzle-orm';
import { getDb, getSqlite } from '../db/client';
import { settings } from '../db/schema';
import { DEFAULT_INTERVALS, join, parse } from '../../lib/reviewScheduler';

export const KEY_INTERVALS = 'review_intervals';
export const KEY_LAST_BACKUP = 'last_backup_at';

export async function getSetting(key: string): Promise<string | null> {
  const row = await getDb().select().from(settings).where(eq(settings.key, key)).get();
  return row?.value ?? null;
}

export async function putSetting(key: string, value: string | null): Promise<void> {
  await getSqlite().runAsync(
    'INSERT INTO settings (key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
    [key, value],
  );
}

export async function intervals(): Promise<number[]> {
  const raw = await getSetting(KEY_INTERVALS);
  if (raw == null) return [...DEFAULT_INTERVALS];
  return parse(raw) ?? [...DEFAULT_INTERVALS];
}

export async function saveIntervals(values: number[]): Promise<void> {
  await putSetting(KEY_INTERVALS, join(values));
}

export async function allSettings(): Promise<{ key: string; value: string | null }[]> {
  return getDb().select().from(settings);
}
