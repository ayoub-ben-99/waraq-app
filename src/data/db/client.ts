import { Platform } from 'react-native';
import { drizzle, type ExpoSQLiteDatabase } from 'drizzle-orm/expo-sqlite';
import { openDatabaseSync, type SQLiteDatabase } from 'expo-sqlite';
import { createSchemaSql, LATEST_SCHEMA } from './migrations';
import * as schema from './schema';

let sqlite: SQLiteDatabase | null = null;
let database: ExpoSQLiteDatabase<typeof schema> | null = null;

export function getSqlite(): SQLiteDatabase {
  if (Platform.OS === 'web') {
    throw new Error('SQLite is not supported on web platform');
  }
  if (!sqlite) sqlite = openDatabaseSync('waraq.db');
  return sqlite;
}

export function getDb(): ExpoSQLiteDatabase<typeof schema> {
  if (Platform.OS === 'web') {
    throw new Error('SQLite is not supported on web platform');
  }
  if (!database) database = drizzle(getSqlite(), { schema });
  return database;
}

export function initializeDatabase(): void {
  if (Platform.OS === 'web') {
    // No‑op for web; SQLite is unavailable.
    return;
  }
  const raw = getSqlite();
  raw.execSync('PRAGMA foreign_keys = ON;');
  raw.execSync('PRAGMA journal_mode = WAL;');
  raw.execSync('PRAGMA busy_timeout = 5000;');
  const row = raw.getFirstSync<{ user_version: number }>('PRAGMA user_version');
  const version = row?.user_version ?? 0;
  if (version > LATEST_SCHEMA) {
    throw new Error(`waraq-db-newer:${version}`);
  }
  if (version < LATEST_SCHEMA) {
    raw.withTransactionSync(() => {
      raw.execSync(createSchemaSql);
      raw.execSync(`PRAGMA user_version = ${LATEST_SCHEMA};`);
    });
  }
  database = drizzle(raw, { schema });
}

export function resetDatabaseForTests(): void {
  sqlite = null;
  database = null;
}
