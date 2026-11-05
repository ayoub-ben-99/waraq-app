// Ported from app/schemas/com.waraq.app.data.WaraqDatabase/3.json
export const LATEST_SCHEMA = 3;

export const createSchemaSql = `
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT NOT NULL,
  nameNorm TEXT NOT NULL,
  createdAt INTEGER NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS index_categories_nameNorm ON categories (nameNorm);
CREATE TABLE IF NOT EXISTS books (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  title TEXT NOT NULL,
  author TEXT,
  description TEXT,
  coverPath TEXT,
  categoryId INTEGER,
  status INTEGER NOT NULL,
  rating INTEGER,
  totalPages INTEGER,
  currentPage INTEGER NOT NULL,
  favorite INTEGER NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  startedAt INTEGER,
  finishedAt INTEGER,
  titleNorm TEXT NOT NULL,
  authorNorm TEXT,
  FOREIGN KEY(categoryId) REFERENCES categories(id) ON UPDATE NO ACTION ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS index_books_categoryId ON books (categoryId);
CREATE INDEX IF NOT EXISTS index_books_status ON books (status);
CREATE INDEX IF NOT EXISTS index_books_titleNorm ON books (titleNorm);
CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  bookId INTEGER NOT NULL,
  startPage INTEGER NOT NULL,
  endPage INTEGER NOT NULL,
  durationMinutes INTEGER NOT NULL,
  date INTEGER NOT NULL,
  note TEXT,
  historical INTEGER NOT NULL,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY(bookId) REFERENCES books(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS index_sessions_bookId ON sessions (bookId);
CREATE INDEX IF NOT EXISTS index_sessions_date ON sessions (date);
CREATE TABLE IF NOT EXISTS entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  type INTEGER NOT NULL,
  title TEXT,
  quoteText TEXT,
  comment TEXT,
  bookId INTEGER,
  page INTEGER,
  date INTEGER NOT NULL,
  favorite INTEGER NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  titleNorm TEXT NOT NULL,
  quoteNorm TEXT,
  commentNorm TEXT,
  FOREIGN KEY(bookId) REFERENCES books(id) ON UPDATE NO ACTION ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS index_entries_bookId ON entries (bookId);
CREATE INDEX IF NOT EXISTS index_entries_type ON entries (type);
CREATE INDEX IF NOT EXISTS index_entries_date ON entries (date);
CREATE TABLE IF NOT EXISTS entry_audio (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  entryId INTEGER NOT NULL,
  fileName TEXT NOT NULL,
  durationMs INTEGER NOT NULL,
  sizeBytes INTEGER NOT NULL,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY(entryId) REFERENCES entries(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS index_entry_audio_entryId ON entry_audio (entryId);
CREATE TABLE IF NOT EXISTS tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  name TEXT NOT NULL,
  nameNorm TEXT NOT NULL,
  createdAt INTEGER NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS index_tags_nameNorm ON tags (nameNorm);
CREATE TABLE IF NOT EXISTS entry_tags (
  entryId INTEGER NOT NULL,
  tagId INTEGER NOT NULL,
  PRIMARY KEY(entryId, tagId),
  FOREIGN KEY(entryId) REFERENCES entries(id) ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY(tagId) REFERENCES tags(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS index_entry_tags_tagId ON entry_tags (tagId);
CREATE TABLE IF NOT EXISTS summaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  bookId INTEGER NOT NULL,
  coreIdea TEXT,
  keyIdeas TEXT,
  learned TEXT,
  agreeDisagree TEXT,
  applications TEXT,
  questions TEXT,
  freeText TEXT,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY(bookId) REFERENCES books(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS index_summaries_bookId ON summaries (bookId);
CREATE TABLE IF NOT EXISTS review_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  entryId INTEGER NOT NULL,
  dueDate INTEGER NOT NULL,
  intervalIndex INTEGER NOT NULL,
  lastReviewedAt INTEGER,
  lastResult INTEGER NOT NULL,
  totalReviews INTEGER NOT NULL,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY(entryId) REFERENCES entries(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS index_review_items_entryId ON review_items (entryId);
CREATE INDEX IF NOT EXISTS index_review_items_dueDate ON review_items (dueDate);
CREATE TABLE IF NOT EXISTS review_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  entryId INTEGER NOT NULL,
  reviewedAt INTEGER NOT NULL,
  result INTEGER NOT NULL,
  nextDueAt INTEGER NOT NULL,
  intervalDays INTEGER NOT NULL,
  FOREIGN KEY(entryId) REFERENCES entries(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS index_review_logs_entryId ON review_logs (entryId);
CREATE INDEX IF NOT EXISTS index_review_logs_reviewedAt ON review_logs (reviewedAt);
CREATE TABLE IF NOT EXISTS settings (
  key TEXT NOT NULL,
  value TEXT,
  PRIMARY KEY(key)
);
CREATE TABLE IF NOT EXISTS pdf_docs (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  bookId INTEGER NOT NULL,
  displayName TEXT NOT NULL,
  sourceUri TEXT,
  localPath TEXT,
  pageCount INTEGER NOT NULL,
  lastPage INTEGER NOT NULL,
  lastOffset REAL NOT NULL,
  sha256 TEXT NOT NULL,
  sizeBytes INTEGER NOT NULL,
  importedAt INTEGER NOT NULL,
  FOREIGN KEY(bookId) REFERENCES books(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS index_pdf_docs_bookId ON pdf_docs (bookId);
CREATE TABLE IF NOT EXISTS pdf_highlights (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  pdfDocId INTEGER NOT NULL,
  page INTEGER NOT NULL,
  rects TEXT NOT NULL,
  text TEXT NOT NULL,
  color INTEGER NOT NULL,
  entryId INTEGER,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY(pdfDocId) REFERENCES pdf_docs(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS index_pdf_highlights_pdfDocId ON pdf_highlights (pdfDocId);
CREATE INDEX IF NOT EXISTS index_pdf_highlights_entryId ON pdf_highlights (entryId);
`;
