// Ported from app/src/main/java/com/waraq/app/pdf/PdfImporter.java
import { requireOptionalNativeModule, type EventSubscription } from 'expo-modules-core';

export type ImportedPdfResult = {
  absolutePath: string;
  relativePath: string;
  displayName: string;
  sha256: string;
  pageCount: number;
  sizeBytes: number;
};

export type ReaderProgress = { bookId: number; page: number; offset: number; pageCount: number };
export type ReaderHighlight = {
  bookId: number;
  page: number;
  rects: string;
  text: string;
  color: number;
};
export type ReaderEntry = { bookId: number; page: number; type: number };

type WaraqNativeModule = {
  importPdf(uri: string): Promise<ImportedPdfResult>;
  extractCover(path: string, bookId: number): Promise<string | null>;
  openReader(bookId: number, path: string, lastPage: number, highlightsJson: string): Promise<void>;
  clearOcrCache(): Promise<number>;
  addListener(eventName: string, listener: (payload: unknown) => void): EventSubscription;
};

const fallbackNative: WaraqNativeModule = {
  importPdf: async () => {
    throw new Error('PDF import is not supported in the web build.');
  },
  extractCover: async () => null,
  openReader: async () => {
    throw new Error('PDF reader is not available in the web build.');
  },
  clearOcrCache: async () => 0,
  addListener: () => ({ remove: () => undefined }) as EventSubscription,
};

const Native = requireOptionalNativeModule<WaraqNativeModule>('WaraqNative') ?? fallbackNative;

export function importPdf(uri: string): Promise<ImportedPdfResult> {
  return Native.importPdf(uri);
}

export function extractCover(path: string, bookId: number): Promise<string | null> {
  return Native.extractCover(path, bookId);
}

export function openReader(
  bookId: number,
  path: string,
  lastPage: number,
  highlightsJson: string,
): Promise<void> {
  return Native.openReader(bookId, path, lastPage, highlightsJson);
}

export function clearOcrCache(): Promise<number> {
  return Native.clearOcrCache();
}

export function onReaderProgress(listener: (payload: ReaderProgress) => void): EventSubscription {
  return Native.addListener('onProgress', listener as (payload: unknown) => void);
}

export function onReaderHighlight(listener: (payload: ReaderHighlight) => void): EventSubscription {
  return Native.addListener('onHighlightAdded', listener as (payload: unknown) => void);
}

export function onReaderEntry(listener: (payload: ReaderEntry) => void): EventSubscription {
  return Native.addListener('onEntryRequested', listener as (payload: unknown) => void);
}

export function onReaderClosed(listener: () => void): EventSubscription {
  return Native.addListener('onReaderClosed', listener as (payload: unknown) => void);
}
