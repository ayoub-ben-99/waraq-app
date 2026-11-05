// Ported from app/src/main/java/com/waraq/app/data/entity
import { index, integer, primaryKey, real, sqliteTable, text, uniqueIndex } from 'drizzle-orm/sqlite-core';

export const books = sqliteTable(
  'books',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    title: text('title').notNull(),
    author: text('author'),
    description: text('description'),
    coverPath: text('coverPath'),
    categoryId: integer('categoryId'),
    status: integer('status').notNull(),
    rating: integer('rating'),
    totalPages: integer('totalPages'),
    currentPage: integer('currentPage').notNull(),
    favorite: integer('favorite').notNull(),
    createdAt: integer('createdAt').notNull(),
    updatedAt: integer('updatedAt').notNull(),
    startedAt: integer('startedAt'),
    finishedAt: integer('finishedAt'),
    titleNorm: text('titleNorm').notNull(),
    authorNorm: text('authorNorm'),
  },
  (table) => [
    index('index_books_categoryId').on(table.categoryId),
    index('index_books_status').on(table.status),
    index('index_books_titleNorm').on(table.titleNorm),
  ],
);

export const categories = sqliteTable(
  'categories',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    name: text('name').notNull(),
    nameNorm: text('nameNorm').notNull(),
    createdAt: integer('createdAt').notNull(),
  },
  (table) => [uniqueIndex('index_categories_nameNorm').on(table.nameNorm)],
);

export const sessions = sqliteTable(
  'sessions',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    bookId: integer('bookId').notNull(),
    startPage: integer('startPage').notNull(),
    endPage: integer('endPage').notNull(),
    durationMinutes: integer('durationMinutes').notNull(),
    date: integer('date').notNull(),
    note: text('note'),
    historical: integer('historical').notNull(),
    createdAt: integer('createdAt').notNull(),
  },
  (table) => [
    index('index_sessions_bookId').on(table.bookId),
    index('index_sessions_date').on(table.date),
  ],
);

export const entries = sqliteTable(
  'entries',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    type: integer('type').notNull(),
    title: text('title'),
    quoteText: text('quoteText'),
    comment: text('comment'),
    bookId: integer('bookId'),
    page: integer('page'),
    date: integer('date').notNull(),
    favorite: integer('favorite').notNull(),
    createdAt: integer('createdAt').notNull(),
    updatedAt: integer('updatedAt').notNull(),
    titleNorm: text('titleNorm').notNull(),
    quoteNorm: text('quoteNorm'),
    commentNorm: text('commentNorm'),
  },
  (table) => [
    index('index_entries_bookId').on(table.bookId),
    index('index_entries_type').on(table.type),
    index('index_entries_date').on(table.date),
  ],
);

export const entryAudio = sqliteTable(
  'entry_audio',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    entryId: integer('entryId').notNull(),
    fileName: text('fileName').notNull(),
    durationMs: integer('durationMs').notNull(),
    sizeBytes: integer('sizeBytes').notNull(),
    createdAt: integer('createdAt').notNull(),
  },
  (table) => [uniqueIndex('index_entry_audio_entryId').on(table.entryId)],
);

export const tags = sqliteTable(
  'tags',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    name: text('name').notNull(),
    nameNorm: text('nameNorm').notNull(),
    createdAt: integer('createdAt').notNull(),
  },
  (table) => [uniqueIndex('index_tags_nameNorm').on(table.nameNorm)],
);

export const entryTags = sqliteTable(
  'entry_tags',
  {
    entryId: integer('entryId').notNull(),
    tagId: integer('tagId').notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.entryId, table.tagId] }),
    index('index_entry_tags_tagId').on(table.tagId),
  ],
);

export const summaries = sqliteTable(
  'summaries',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    bookId: integer('bookId').notNull(),
    coreIdea: text('coreIdea'),
    keyIdeas: text('keyIdeas'),
    learned: text('learned'),
    agreeDisagree: text('agreeDisagree'),
    applications: text('applications'),
    questions: text('questions'),
    freeText: text('freeText'),
    updatedAt: integer('updatedAt').notNull(),
  },
  (table) => [uniqueIndex('index_summaries_bookId').on(table.bookId)],
);

export const reviewItems = sqliteTable(
  'review_items',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    entryId: integer('entryId').notNull(),
    dueDate: integer('dueDate').notNull(),
    intervalIndex: integer('intervalIndex').notNull(),
    lastReviewedAt: integer('lastReviewedAt'),
    lastResult: integer('lastResult').notNull(),
    totalReviews: integer('totalReviews').notNull(),
    createdAt: integer('createdAt').notNull(),
  },
  (table) => [
    uniqueIndex('index_review_items_entryId').on(table.entryId),
    index('index_review_items_dueDate').on(table.dueDate),
  ],
);

export const reviewLogs = sqliteTable(
  'review_logs',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    entryId: integer('entryId').notNull(),
    reviewedAt: integer('reviewedAt').notNull(),
    result: integer('result').notNull(),
    nextDueAt: integer('nextDueAt').notNull(),
    intervalDays: integer('intervalDays').notNull(),
  },
  (table) => [
    index('index_review_logs_entryId').on(table.entryId),
    index('index_review_logs_reviewedAt').on(table.reviewedAt),
  ],
);

export const settings = sqliteTable('settings', {
  key: text('key').primaryKey(),
  value: text('value'),
});

export const pdfDocs = sqliteTable(
  'pdf_docs',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    bookId: integer('bookId').notNull(),
    displayName: text('displayName').notNull(),
    sourceUri: text('sourceUri'),
    localPath: text('localPath'),
    pageCount: integer('pageCount').notNull(),
    lastPage: integer('lastPage').notNull(),
    lastOffset: real('lastOffset').notNull(),
    sha256: text('sha256').notNull(),
    sizeBytes: integer('sizeBytes').notNull(),
    importedAt: integer('importedAt').notNull(),
  },
  (table) => [uniqueIndex('index_pdf_docs_bookId').on(table.bookId)],
);

export const pdfHighlights = sqliteTable(
  'pdf_highlights',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    pdfDocId: integer('pdfDocId').notNull(),
    page: integer('page').notNull(),
    rects: text('rects').notNull(),
    text: text('text').notNull(),
    color: integer('color').notNull(),
    entryId: integer('entryId'),
    createdAt: integer('createdAt').notNull(),
  },
  (table) => [
    index('index_pdf_highlights_pdfDocId').on(table.pdfDocId),
    index('index_pdf_highlights_entryId').on(table.entryId),
  ],
);

export type Book = typeof books.$inferSelect;
export type Category = typeof categories.$inferSelect;
export type ReadingSession = typeof sessions.$inferSelect;
export type KnowledgeEntry = typeof entries.$inferSelect;
export type EntryAudio = typeof entryAudio.$inferSelect;
export type Tag = typeof tags.$inferSelect;
export type EntryTag = typeof entryTags.$inferSelect;
export type BookSummary = typeof summaries.$inferSelect;
export type ReviewItem = typeof reviewItems.$inferSelect;
export type ReviewLog = typeof reviewLogs.$inferSelect;
export type SettingRow = typeof settings.$inferSelect;
export type PdfDocument = typeof pdfDocs.$inferSelect;
export type PdfHighlight = typeof pdfHighlights.$inferSelect;
