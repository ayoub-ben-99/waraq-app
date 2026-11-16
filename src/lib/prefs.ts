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

/* تفضيلات القارئ — محفوظة في MMKV لا في قاعدة البيانات، كما في التطبيق الأصلي. */

export const READER_TEXT_SIZE_MIN = 14;
export const READER_TEXT_SIZE_MAX = 32;
export const READER_TEXT_SIZE_DEFAULT = 18;
export const READER_TEXT_SPACING_MIN = 10;
export const READER_TEXT_SPACING_MAX = 22;
export const READER_TEXT_SPACING_DEFAULT = 16;

export type ReaderTextFont = 'system' | 'amiri' | 'plex';

export function getReaderDark(): boolean {
  return storage.getBoolean('reader_dark') ?? false;
}

export function setReaderDark(value: boolean): void {
  storage.set('reader_dark', value);
}

/** وضع القراءة النصي لكل مستند، كما كان في التطبيق الأصلي. */
export function getReaderTextMode(docId: number): boolean {
  return storage.getBoolean(`reader_text:${docId}`) ?? false;
}

export function setReaderTextMode(docId: number, value: boolean): void {
  storage.set(`reader_text:${docId}`, value);
}

export function getReaderTextSize(): number {
  const value = storage.getNumber('reader_text_size');
  if (value == null) return READER_TEXT_SIZE_DEFAULT;
  return Math.min(READER_TEXT_SIZE_MAX, Math.max(READER_TEXT_SIZE_MIN, value));
}

export function setReaderTextSize(value: number): void {
  storage.set('reader_text_size', value);
}

/** التباعد مضروبًا في 10 كي يُخزَّن عددًا صحيحًا (10 = 1.0). */
export function getReaderTextSpacing(): number {
  const value = storage.getNumber('reader_text_spacing');
  if (value == null) return READER_TEXT_SPACING_DEFAULT;
  return Math.min(READER_TEXT_SPACING_MAX, Math.max(READER_TEXT_SPACING_MIN, Math.round(value)));
}

export function setReaderTextSpacing(value: number): void {
  storage.set('reader_text_spacing', Math.round(value));
}

export function getReaderTextFont(): ReaderTextFont {
  const value = storage.getString('reader_text_font');
  return value === 'amiri' || value === 'plex' ? value : 'system';
}

export function setReaderTextFont(value: ReaderTextFont): void {
  storage.set('reader_text_font', value);
}
