// Ported from app/src/main/java/com/waraq/app/util/Prefs.java
import { createMMKV } from 'react-native-mmkv';

export type ThemeMode = 'system' | 'light' | 'dark';
export type LibraryView = 'grid' | 'list';

const storage = createMMKV({ id: 'waraq-prefs' });

export function getThemeMode(): ThemeMode {
  const value = storage.getString('theme_mode');
  return value === 'light' || value === 'dark' ? value : 'system';
}

export function setThemeMode(mode: ThemeMode): void {
  storage.set('theme_mode', mode);
}

export function getLibraryView(): LibraryView {
  return storage.getString('library_view') === 'list' ? 'list' : 'grid';
}

export function setLibraryView(view: LibraryView): void {
  storage.set('library_view', view);
}

export function getDraft(key: string): string | null {
  return storage.getString(key) ?? null;
}

export function setDraft(key: string, value: string): void {
  storage.set(key, value);
}

export function removeDraft(key: string): void {
  storage.remove(key);
}
