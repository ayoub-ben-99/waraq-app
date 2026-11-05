# Arabic Text Normalization
Contents: Behavior · Reference implementation · Vectors exercised by Java tests · Additional rule vectors · Write rules

Source: `app/src/main/java/com/waraq/app/util/ArabicText.java`.
Target: `src/lib/arabicText.ts`.

## Behavior

`normalize(input: string | null): string | null` walks UTF-16 code units in order.

1. Skip `U+064B..U+065F` (Arabic diacritics).
2. Skip `U+0670` (superscript alef) and `U+0640` (tatweel).
3. Map `أ`, `إ`, `آ`, `ٱ` to `ا`.
4. Map `ى`, `ئ`, `ي` to `ي`.
5. Map `ة` to `ه`.
6. Map `ؤ` to `و`.
7. Keep `ء` unchanged.
8. Lowercase every other character with the Java `Character.toLowerCase` equivalent.
9. Replace every run of whitespace with one space, then trim.
10. Return `null` only when the input is `null`.

`likePattern(query)`:

- Normalize the query.
- Return `"%"` when normalization returns `null`.
- Remove `%` and `_` from the normalized text.
- Return `"%" + text + "%"`.

`isBlank(s)`: true for `null`, empty, or whitespace-only.

`wordCount(s)`: 0 when blank, otherwise the count of `trim().split("\\s+")` parts.

## Reference implementation

```ts
export function normalize(input: string | null): string | null {
  if (input === null) return null;
  let out = '';
  for (let i = 0; i < input.length; i++) {
    const c = input.charCodeAt(i);
    if (c >= 0x064b && c <= 0x065f) continue;
    if (c === 0x0670 || c === 0x0640) continue;
    const ch = input.charAt(i);
    switch (ch) {
      case 'أ': case 'إ': case 'آ': case 'ٱ': out += 'ا'; break;
      case 'ى': case 'ئ': case 'ي': out += 'ي'; break;
      case 'ة': out += 'ه'; break;
      case 'ؤ': out += 'و'; break;
      case 'ء': out += 'ء'; break;
      default: out += ch.toLowerCase();
    }
  }
  return out.replace(/\s+/g, ' ').trim();
}

export function likePattern(query: string | null): string {
  const n = normalize(query);
  if (n === null) return '%';
  return '%' + n.replace(/%/g, '').replace(/_/g, '') + '%';
}

export function isBlank(s: string | null): boolean {
  return s === null || s.trim().length === 0;
}

export function wordCount(s: string | null): number {
  if (isBlank(s)) return 0;
  return s!.trim().split(/\s+/).length;
}
```

Do not use `Intl`, `normalize('NFKC')`, or a Unicode library. The Java code is a custom character map.

## Vectors exercised by Java tests

Source: `app/src/test/java/com/waraq/app/SearchTest.java`.

| Input | Normalized result |
|---|---|
| `الأمانة في العمل` | `الامانه في العمل` |
| `الامانة` | `الامانه` |
| `الامانه` | `الامانه` |
| `الصدق ينجي صاحبه في المواقف الصعبة` | `الصدق ينجي صاحبه في المواقف الصعبه` |
| `أخلاق` | `اخلاق` |
| `خلاصة الفصول الأخيرة عن المسؤولية` | `خلاصه الفصول الاخيره عن المسووليه` |
| `المسؤولية` | `المسووليه` |

Source: `app/src/test/java/com/waraq/app/BooksTest.java`.

| Input | Normalized result |
|---|---|
| `الإتقان في العمل` | `الاتقان في العمل` |
| `التربية بالقدوة` | `التربيه بالقدوه` |
| `الأمانة` | `الامانه` |

Search behavior from `app/src/test/java/com/waraq/app/SearchTest.java`:

- `search("الامانة")` finds the book titled `الأمانة في العمل`.
- `search("الامانه")` finds the same book.
- `search("المواقف")` finds a benefit whose comment contains `المواقف`.
- `search("أخلاق")` finds the tag `أخلاق`.
- `search("المسؤولية")` finds the summary.
- `search("ا")` returns nothing. Queries shorter than 2 normalized characters return nothing.
- `search("")` returns nothing.
- `search("الفلسفة")` returns nothing when absent.

Search rule from `app/src/main/java/com/waraq/app/data/repo/SearchRepository.java`:

- Normalize first. Return empty when `null` or length `< 2`.
- Search books by title, author, and description through `books.search(like)`.
- Search entries by title, quote, and comment through `entries.search(like)`.
- Group entries as `quotes`, `benefits`, `summaries`, and `notes`; everything that is not quote, benefit, or summary is a note.
- Search tags with `nameNorm.includes(norm)`, not SQL LIKE.

## Additional rule vectors

Derived directly from the Java loop, for unit tests.

| Input | Normalized result |
|---|---|
| `مُحَمَّد` | `محمد` |
| `ـ` | `` |
| `ىئي` | `ييي` |
| `ؤ` | `و` |
| `ء` | `ء` |
| `  أ  إ   آ  ` | `ا ا ا` |
| `ABC` | `abc` |

## Write rules

Every repository write that affects a searchable column must store the normalized value:

- `categories.nameNorm`
- `books.titleNorm`, `books.authorNorm`
- `entries.titleNorm`, `entries.quoteNorm`, `entries.commentNorm`
- `tags.nameNorm`

Recompute on update. Never trust a restored backup's `*Norm` values; the backup parser recomputes them.
