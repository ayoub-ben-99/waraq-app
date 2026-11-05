# Backup Format
Contents: Container · manifest.json · data.json · Export collection · Read and validation order · Restore modes · PDF relink

Sources:

- `app/src/main/java/com/waraq/app/backup/BackupManager.java`
- `app/src/main/java/com/waraq/app/backup/BackupData.java`
- `app/src/test/java/com/waraq/app/BackupRoundTripTest.java`
- `app/src/test/java/com/waraq/app/BackupSchema3AudioTest.java`

Target: `src/features/backup/backupManager.ts`, `src/features/backup/types.ts`.

## Container

The backup is an unencrypted ZIP. Tell the user it is not encrypted before export.

| Entry | Content |
|---|---|
| `manifest.json` | App marker, schema, timestamp, counts |
| `data.json` | All table rows |
| `covers/` + stored `coverPath` | Cover bytes |
| `pdfs/<sha256>.pdf` | PDF bytes, only when included |
| `audios/<basename>` | `entry_audio` file bytes, schema 3 |

The cover path is a source quirk. `books.coverPath` already begins with `covers/`, and export writes `COVERS_PREFIX + coverPath`. A stored `covers/cover-test.png` becomes ZIP entry `covers/covers/cover-test.png`. Keep this exact layout. On read, strip the first `covers/`, so the key again matches `books.coverPath`.

Audio entry name is the basename of `entry_audio.fileName`, for example `audios/3f2a.m4a`. PDF entry name is the SHA-256 plus `.pdf`; on read the `.pdf` suffix is stripped to recover the map key.

ZIP entry order is not significant. The Java writer currently streams audio first, then manifest, data, covers, and PDFs.

## manifest.json

Export writes these keys:

| Key | Type | Value |
|---|---|---|
| `app` | string | Always `"waraq"` |
| `schema` | number | Always `3` |
| `createdAt` | string | ISO `yyyy-MM-dd'T'HH:mm:ss.SSSZ`, `Locale.US` |
| `books` | number | `books.length` |
| `sessions` | number | `sessions.length` |
| `entries` | number | `entries.length` |
| `tags` | number | `tags.length` |
| `reviews` | number | `reviewItems.length` |
| `covers` | number | Number of embedded covers |
| `pdfDocs` | number | `pdfDocs.length` |
| `highlights` | number | `highlights.length` |
| `audios` | number | Included audio rows |
| `audioFiles` | number | Audio files actually written |
| `pdfFiles` | number | PDF files actually written |
| `pdfFilesIncluded` | boolean | `includePdfFiles && pdfFiles > 0` |

Real sample from `BackupRoundTripTest.java`, schema 2:

```json
{"app":"waraq","schema":2,"createdAt":"2026-01-01","books":2,"sessions":0,"entries":0,"tags":0,"reviews":0,"covers":0,"pdfDocs":0,"highlights":0,"pdfFiles":0,"pdfFilesIncluded":false}
```

Schema 3 adds `audios` and `audioFiles`:

```json
{
  "app": "waraq",
  "schema": 3,
  "createdAt": "2026-01-01T00:00:00.000+0000",
  "books": 1,
  "sessions": 0,
  "entries": 1,
  "tags": 0,
  "reviews": 0,
  "covers": 1,
  "pdfDocs": 0,
  "highlights": 0,
  "audios": 1,
  "audioFiles": 1,
  "pdfFiles": 0,
  "pdfFilesIncluded": false
}
```

## data.json

Root fields: `schema`, `createdAt`, `categories`, `books`, `sessions`, `entries`, `tags`, `entryTags`, `summaries`, `reviews`, `reviewLogs`, `settings`, `pdfDocs`, `highlights`, `audios`.

Normalized columns are not serialized. Recompute them on restore with `normalizeArabic`; the Java parser does this.

| Array | Fields |
|---|---|
| `categories` | `id`, `name`, `createdAt` |
| `books` | `id`, `title`, `author`, `description`, `coverPath`, `categoryId`, `status`, `rating`, `totalPages`, `currentPage`, `favorite`, `createdAt`, `updatedAt`, `startedAt`, `finishedAt` |
| `sessions` | `id`, `bookId`, `startPage`, `endPage`, `durationMinutes`, `date`, `note`, `historical`, `createdAt` |
| `entries` | `id`, `type`, `title`, `quoteText`, `comment`, `bookId`, `page`, `date`, `favorite`, `createdAt`, `updatedAt` |
| `tags` | `id`, `name`, `createdAt` |
| `entryTags` | two-element arrays `[entryId, tagId]` |
| `summaries` | `bookId`, `coreIdea`, `keyIdeas`, `learned`, `agreeDisagree`, `applications`, `questions`, `freeText`, `updatedAt` |
| `reviews` | `entryId`, `dueDate`, `intervalIndex`, `lastReviewedAt`, `lastResult`, `totalReviews`, `createdAt` |
| `reviewLogs` | `entryId`, `reviewedAt`, `result`, `nextDueAt`, `intervalDays` |
| `settings` | `key`, `value` |
| `pdfDocs` | `id`, `bookId`, `displayName`, `sourceUri`, `pageCount`, `lastPage`, `lastOffset`, `sha256`, `sizeBytes`, `importedAt`, `fileIncluded` |
| `highlights` | `id`, `pdfDocId`, `page`, `rects`, `text`, `color`, `entryId`, `createdAt` |
| `audios` | `id`, `entryId`, `fileName`, `durationMs`, `sizeBytes`, `createdAt` |

`pdfDocs` intentionally omits `localPath`. `fileIncluded` is written but ignored when parsing. `summaries`, `reviews`, `reviewLogs`, `settings`, and `entryTags` have no `id` in the payload.

Parse defaults from Java:

- `entry.type` default `1`; `book.status` default `0`; `review.lastResult` default `-1`.
- `highlight.rects` default `"[]"`; `highlight.color` default `PdfRepository.COLOR_YELLOW` (`0x88FFE082`).
- `pdf.pageCount = max(1, value)`; `pdf.lastPage = max(0, value)`.
- `audio.fileName` empty is a parse error; `durationMs` and `sizeBytes` are clamped to `>= 0`.
- A book with a blank title is a parse error.

## Export collection

- Read all rows in one transaction so the archive is one consistent snapshot.
- Read cover, PDF, and audio files outside that transaction.
- Include a cover only if the file exists.
- Include an audio row only if its file exists and is non-empty; correct `sizeBytes` to the real length.
- Include PDF files only when `includePdfFiles` is true, `localPath` and `sha256` are non-empty, the file exists and is non-empty, and the SHA was not already added.
- `includePdfFiles=false` exports metadata only. `localPath` is never serialized.

## Read and validation order

1. Clear the restore temp directory.
2. Stream ZIP entries. Audio and PDF entries go to temp files. Metadata and covers go to memory.
3. Enforce caps: metadata 256 MiB, one PDF 2 GiB, total PDFs 8 GiB, total audio 4 GiB, per-audio `AudioRepository.maxFileBytes`.
4. Require both `manifest.json` and `data.json`; otherwise `backup_invalid_file`.
5. Parse the manifest. Require `app == "waraq"`, `schema > 0`, and `schema <= 3`.
6. Parse `data.json`. Override `data.createdAt` from the manifest.
7. Verify audio integrity: every `entry_audio` row has a non-empty temp file and, when `sizeBytes > 0`, the exact size.
8. For `schema >= 2`, verify manifest counts against parsed data: books, sessions, entries, tags, reviews, covers, pdfDocs, highlights, pdfFiles, and for schema 3 audios and audioFiles. Skip keys that are absent.
9. Reject archives where books, entries, and pdfDocs are all empty.
10. Do not touch the database before all checks pass.

Errors: bad ZIP or bad JSON map to `backup_corrupt`; wrong app, missing files, bad schema, or count mismatch map to `backup_invalid_file`; newer schema maps to `backup_newer_schema`; missing/corrupt audio has its own message.

## Restore modes

`replace = true`:

- Delete every row from all 13 tables inside the same transaction as the restore.
- Restore rows with their original IDs.
- After all inserts, verify counts for books, sessions, entries, audio, pdfDocs, tags, and entryTags. Any mismatch throws and rolls back everything.
- After success, delete PDF files with no referencing `pdf_docs` row.

`replace = false`:

- Never clear tables.
- Match categories by `nameNorm`, books by `titleNorm + authorNorm`, tags by `nameNorm`.
- Reuse existing IDs through maps. A missing source ID that is referenced later is an orphan error.
- Compute full-row fingerprints for entries, sessions, review logs, tag links, and highlights. `take` removes one matching ID per incoming row. This preserves legitimate duplicates while preventing the same backup from being imported twice.
- Entry fingerprint: `bookId|type|date|createdAt|titleNorm|quoteNorm|commentNorm`.
- Session fingerprint: `bookId|date|startPage|endPage|durationMinutes|historical|note|createdAt`.
- Review log fingerprint: `entryId|reviewedAt|result|nextDueAt|intervalDays`.
- Highlight fingerprint: `pdfDocId|page|rects|text|color|createdAt`.
- Tag link fingerprint: `entryId|tagId`.
- Summaries are upserted per book; `updatedAt` is set to now.
- A review item is skipped when the entry already has one.
- Settings are overwritten by key.
- Audio always gets a new random filename on restore.

Orphan policy: an entry pointing to a missing book, a session or summary pointing to a missing book, and a tag link pointing to a missing entry or tag throw `backup_verify_orphans`. Review items and logs with a missing entry are skipped. PDF docs with a missing book and highlights with a missing document are skipped. Do not broaden these rules.

## PDF relink

- Included file: adopt `pdfs/<sha>.pdf` into the app PDF directory as `pdfs/<safe-sha>.pdf`. If that target already exists and is non-empty, keep it.
- Not included: `localPath = null`; the row keeps `sha256`, `sourceUri`, page metadata, and last position.
- After restore, count documents with no file and show the relink message.
- Relink: store the picked PDF, compute SHA-256 and page count. If the SHA differs from the stored one, require explicit user confirmation. On success update `localPath`, `sha256`, `sizeBytes`; if the page count changed, clamp `lastPage` and update `pageCount`.
