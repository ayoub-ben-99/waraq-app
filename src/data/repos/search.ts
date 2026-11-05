// Ported from app/src/main/java/com/waraq/app/data/repo/SearchRepository.java
import { normalize } from '../../lib/arabicText';
import { getSqlite } from '../db/client';
import type { Book, KnowledgeEntry, Tag } from '../db/schema';

export type SearchResult = {
  books: Book[];
  quotes: KnowledgeEntry[];
  benefits: KnowledgeEntry[];
  summaries: KnowledgeEntry[];
  notes: KnowledgeEntry[];
  tags: Tag[];
  total: number;
};

export async function searchAll(query: string): Promise<SearchResult> {
  const result: SearchResult = { books: [], quotes: [], benefits: [], summaries: [], notes: [], tags: [], total: 0 };
  const norm = normalize(query);
  if (norm == null || norm.length < 2) return result;
  const pattern = `%${norm.replace(/%/g, '').replace(/_/g, '')}%`;
  const raw = getSqlite();
  result.books = await raw.getAllAsync<Book>(
    'SELECT * FROM books WHERE titleNorm LIKE ? OR authorNorm LIKE ? OR description LIKE ?',
    [pattern, pattern, pattern],
  );
  const entries = await raw.getAllAsync<KnowledgeEntry>(
    'SELECT * FROM entries WHERE titleNorm LIKE ? OR quoteNorm LIKE ? OR commentNorm LIKE ?',
    [pattern, pattern, pattern],
  );
  for (const entry of entries) {
    if (entry.type === 0) result.quotes.push(entry);
    else if (entry.type === 1) result.benefits.push(entry);
    else if (entry.type === 2) result.summaries.push(entry);
    else result.notes.push(entry);
  }
  result.tags = (await raw.getAllAsync<Tag>('SELECT * FROM tags')).filter((tag) => tag.nameNorm.includes(norm));
  result.total =
    result.books.length +
    result.quotes.length +
    result.benefits.length +
    result.summaries.length +
    result.notes.length +
    result.tags.length;
  return result;
}
