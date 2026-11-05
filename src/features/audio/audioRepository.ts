// Ported from app/src/main/java/com/waraq/app/data/repo/AudioRepository.java
import * as FS from 'expo-file-system/legacy';
import { getSqlite } from '../../data/db/client';
import type { EntryAudio } from '../../data/db/schema';
import { normalize } from '../../lib/arabicText';

export const AUDIO_DIR = 'audio';
export const AUDIO_EXT = '.m4a';

export async function ensureAudioDir(): Promise<string> {
  const dir = `${FS.documentDirectory}${AUDIO_DIR}/`;
  await FS.makeDirectoryAsync(dir, { intermediates: true });
  return dir;
}

export function audioUri(relative: string | null | undefined): string | null {
  if (!relative) return null;
  const name = relative.startsWith(`${AUDIO_DIR}/`) ? relative.slice(AUDIO_DIR.length + 1) : relative;
  if (name.includes('/') || name.includes('\\') || name.includes('..')) return null;
  return `${FS.documentDirectory}${AUDIO_DIR}/${name}`;
}

export async function getEntryAudio(entryId: number): Promise<EntryAudio | null> {
  return (
    (await getSqlite().getFirstAsync<EntryAudio>('SELECT * FROM entry_audio WHERE entryId=?', [entryId])) ??
    null
  );
}

export async function allAudio(): Promise<EntryAudio[]> {
  return getSqlite().getAllAsync<EntryAudio>('SELECT * FROM entry_audio');
}

export async function attachAudio(
  entryId: number,
  sourceUri: string,
  durationMs: number,
): Promise<EntryAudio> {
  await ensureAudioDir();
  const name = `${Date.now()}-${Math.random().toString(36).slice(2)}${AUDIO_EXT}`;
  const relative = `${AUDIO_DIR}/${name}`;
  const target = `${FS.documentDirectory}${relative}`;
  await FS.copyAsync({ from: sourceUri, to: target });
  const info = await FS.getInfoAsync(target);
  const sizeBytes = info.exists && 'size' in info ? info.size : 0;
  const raw = getSqlite();
  const existing = await getEntryAudio(entryId);
  const now = Date.now();
  let row: EntryAudio;
  if (existing) {
    await raw.runAsync(
      'UPDATE entry_audio SET fileName=?,durationMs=?,sizeBytes=?,createdAt=? WHERE entryId=?',
      [relative, Math.max(0, durationMs), sizeBytes, now, entryId],
    );
    row = { ...existing, fileName: relative, durationMs: Math.max(0, durationMs), sizeBytes, createdAt: now };
    if (existing.fileName && existing.fileName !== relative) {
      const old = audioUri(existing.fileName);
      if (old) await FS.deleteAsync(old, { idempotent: true });
    }
  } else {
    const result = await raw.runAsync(
      'INSERT INTO entry_audio (entryId,fileName,durationMs,sizeBytes,createdAt) VALUES (?,?,?,?,?)',
      [entryId, relative, Math.max(0, durationMs), sizeBytes, now],
    );
    row = {
      id: Number(result.lastInsertRowId),
      entryId,
      fileName: relative,
      durationMs: Math.max(0, durationMs),
      sizeBytes,
      createdAt: now,
    };
  }
  await FS.deleteAsync(sourceUri, { idempotent: true });
  return row;
}

export async function deleteRecording(entryId: number): Promise<void> {
  const row = await getEntryAudio(entryId);
  if (!row) return;
  await getSqlite().runAsync('DELETE FROM entry_audio WHERE entryId=?', [entryId]);
  const uri = audioUri(row.fileName);
  if (uri) await FS.deleteAsync(uri, { idempotent: true });
}

export async function renameAudioEntry(entryId: number, title: string): Promise<void> {
  const name = title.trim();
  await getSqlite().runAsync(
    'UPDATE entries SET title=?, titleNorm=?, updatedAt=? WHERE id=?',
    [name || null, normalize(name) ?? '', Date.now(), entryId],
  );
}

export async function cleanupOrphanAudio(): Promise<number> {
  const dir = await ensureAudioDir();
  const rows = await allAudio();
  const referenced = new Set(rows.map((r) => r.fileName.split('/').pop()));
  const files = await FS.readDirectoryAsync(dir);
  let removed = 0;
  for (const file of files) {
    if (referenced.has(file)) continue;
    await FS.deleteAsync(`${dir}${file}`, { idempotent: true });
    removed++;
  }
  return removed;
}

export function formatAudioDuration(ms: number): string {
  const total = Math.max(0, ms) / 1000;
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = Math.floor(total % 60);
  if (h > 0) return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  return `${m}:${String(s).padStart(2, '0')}`;
}
