# Database Schema

Source: `app/schemas/com.waraq.app.data.WaraqDatabase/3.json` and `app/src/main/java/com/waraq/app/data/entity/`.
Target: `expo-sqlite` plus Drizzle ORM at `src/data/db/schema.ts`.

## Contents

1. Rules
2. Drizzle example
3. Tables
4. Enums

## Rules

- Use schema version 3 only. Create fresh databases at v3. Do not port the v1 to v2 to v3 migration chain.
- Keep table and column names exactly. All timestamps are epoch milliseconds as integers.
- Room booleans are integers `0` or `1`. Drizzle may use `{ mode: 'boolean' }`.
- Nullable columns stay nullable. Do not add defaults that the Java entity does not have.
- Keep all 20 indexes and every foreign key action. There are 13 tables.
- `PRAGMA foreign_keys = ON` and WAL mode must match Room defaults.
- Text search uses the stored `*Norm` columns. Recompute with `normalizeArabic` on every write, as the Java repositories do.

## Drizzle example

```ts
// src/data/db/schema.ts
import { sqliteTable, text, integer, index, uniqueIndex } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const categories = sqliteTable(
  'categories',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    name: text('name').notNull().default(''),
    nameNorm: text('nameNorm').notNull().default(''),
    createdAt: integer('createdAt').notNull().default(0),
  },
  (t) => [uniqueIndex('index_categories_nameNorm').on(t.nameNorm)],
);

export const books = sqliteTable(
  'books',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    title: text('title').notNull().default(''),
    author: text('author'),
    description: text('description'),
    coverPath: text('coverPath'),
    categoryId: integer('categoryId').references(() => categories.id, {
      onDelete: 'set null',
    }),
    status: integer('status').notNull().default(0),
    rating: integer('rating'),
    totalPages: integer('totalPages'),
    currentPage: integer('currentPage').notNull().default(0),
    favorite: integer('favorite', { mode: 'boolean' }).notNull().default(false),
    createdAt: integer('createdAt').notNull().default(0),
    updatedAt: integer('updatedAt').notNull().default(0),
    startedAt: integer('startedAt'),
    finishedAt: integer('finishedAt'),
    titleNorm: text('titleNorm').notNull().default(''),
    authorNorm: text('authorNorm'),
  },
  (t) => [
    index('index_books_categoryId').on(t.categoryId),
    index('index_books_status').on(t.status),
    index('index_books_titleNorm').on(t.titleNorm),
  ],
);
```

Follow the same style for the remaining tables.

## Tables

### categories

`id` PK autoincrement; `name` TEXT NOT NULL default `''`; `nameNorm` TEXT NOT NULL default `''`; `createdAt` INTEGER NOT NULL default 0.
Index: unique `nameNorm`.

### books

`id` PK; `title` TEXT NOT NULL default `''`; `author` TEXT; `description` TEXT; `coverPath` TEXT; `categoryId` INTEGER FK `categories.id` ON DELETE SET NULL; `status` INTEGER NOT NULL default 0; `rating` INTEGER; `totalPages` INTEGER; `currentPage` INTEGER NOT NULL default 0; `favorite` INTEGER NOT NULL default 0; `createdAt` INTEGER NOT NULL default 0; `updatedAt` INTEGER NOT NULL default 0; `startedAt` INTEGER; `finishedAt` INTEGER; `titleNorm` TEXT NOT NULL default `''`; `authorNorm` TEXT.
Indexes: `categoryId`, `status`, `titleNorm`.

### sessions

`id` PK; `bookId` INTEGER NOT NULL FK `books.id` ON DELETE CASCADE; `startPage` INTEGER NOT NULL default 0; `endPage` INTEGER NOT NULL default 0; `durationMinutes` INTEGER NOT NULL default 0; `date` INTEGER NOT NULL default 0; `note` TEXT; `historical` INTEGER NOT NULL default 0; `createdAt` INTEGER NOT NULL default 0.
Indexes: `bookId`, `date`.

### entries

`id` PK; `type` INTEGER NOT NULL default 1; `title` TEXT; `quoteText` TEXT; `comment` TEXT; `bookId` INTEGER FK `books.id` ON DELETE SET NULL; `page` INTEGER; `date` INTEGER NOT NULL default 0; `favorite` INTEGER NOT NULL default 0; `createdAt` INTEGER NOT NULL default 0; `updatedAt` INTEGER NOT NULL default 0; `titleNorm` TEXT NOT NULL default `''`; `quoteNorm` TEXT; `commentNorm` TEXT.
Indexes: `bookId`, `type`, `date`.

### tags

`id` PK; `name` TEXT NOT NULL default `''`; `nameNorm` TEXT NOT NULL default `''`; `createdAt` INTEGER NOT NULL default 0.
Index: unique `nameNorm`.

### entry_tags

`entryId` INTEGER NOT NULL FK `entries.id` ON DELETE CASCADE; `tagId` INTEGER NOT NULL FK `tags.id` ON DELETE CASCADE.
Composite primary key: `(entryId, tagId)`. Index: `tagId`.

### summaries

`id` PK; `bookId` INTEGER NOT NULL FK `books.id` ON DELETE CASCADE; `coreIdea` TEXT; `keyIdeas` TEXT; `learned` TEXT; `agreeDisagree` TEXT; `applications` TEXT; `questions` TEXT; `freeText` TEXT; `updatedAt` INTEGER NOT NULL default 0.
Index: unique `bookId`.

### review_items

`id` PK; `entryId` INTEGER NOT NULL FK `entries.id` ON DELETE CASCADE; `dueDate` INTEGER NOT NULL default 0; `intervalIndex` INTEGER NOT NULL default 0; `lastReviewedAt` INTEGER; `lastResult` INTEGER NOT NULL default -1; `totalReviews` INTEGER NOT NULL default 0; `createdAt` INTEGER NOT NULL default 0.
Indexes: unique `entryId`, `dueDate`.

### review_logs

`id` PK; `entryId` INTEGER NOT NULL FK `entries.id` ON DELETE CASCADE; `reviewedAt` INTEGER NOT NULL default 0; `result` INTEGER NOT NULL default 0; `nextDueAt` INTEGER NOT NULL default 0; `intervalDays` INTEGER NOT NULL default 0.
Indexes: `entryId`, `reviewedAt`.

### settings

`key` TEXT PRIMARY KEY; `value` TEXT. No autoincrement.

### pdf_docs

`id` PK; `bookId` INTEGER NOT NULL FK `books.id` ON DELETE CASCADE; `displayName` TEXT NOT NULL default `''`; `sourceUri` TEXT; `localPath` TEXT; `pageCount` INTEGER NOT NULL default 0; `lastPage` INTEGER NOT NULL default 0; `lastOffset` REAL NOT NULL default 0; `sha256` TEXT NOT NULL default `''`; `sizeBytes` INTEGER NOT NULL default 0; `importedAt` INTEGER NOT NULL default 0.
Index: unique `bookId`.

### pdf_highlights

`id` PK; `pdfDocId` INTEGER NOT NULL FK `pdf_docs.id` ON DELETE CASCADE; `page` INTEGER NOT NULL default 0; `rects` TEXT NOT NULL default `'[]'`; `text` TEXT NOT NULL default `''`; `color` INTEGER NOT NULL default 0; `entryId` INTEGER FK `entries.id` ON DELETE SET NULL; `createdAt` INTEGER NOT NULL default 0.
Indexes: `pdfDocId`, `entryId`.

### entry_audio

`id` PK; `entryId` INTEGER NOT NULL FK `entries.id` ON DELETE CASCADE; `fileName` TEXT NOT NULL default `''`; `durationMs` INTEGER NOT NULL default 0; `sizeBytes` INTEGER NOT NULL default 0; `createdAt` INTEGER NOT NULL default 0.
Index: unique `entryId`.

## Enums

`BookStatus`: `TO_READ = 0`, `READING = 1`, `COMPLETED = 2`, `PAUSED = 3`, `ABANDONED = 4`.

`EntryType`: `QUOTE = 0`, `BENEFIT = 1`, `SUMMARY = 2`, `QUESTION = 3`, `OPINION = 4`.

`ReviewResult`: `FORGOT = 0`, `PARTIAL = 1`, `GOOD = 2`.

Source: `app/src/main/java/com/waraq/app/data/entity/BookStatus.java`, `EntryType.java`, `ReviewResult.java`.
