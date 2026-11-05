# Spaced Repetition
Contents: Constants · Day rules · Scheduler · Add, grade, postpone · Lists and counts · Vectors

Sources:

- `app/src/main/java/com/waraq/app/data/repo/ReviewScheduler.java`
- `app/src/main/java/com/waraq/app/data/repo/ReviewRepository.java`
- `app/src/main/java/com/waraq/app/data/repo/SettingsRepository.java`
- `app/src/main/java/com/waraq/app/util/Dates.java`
- `app/src/test/java/com/waraq/app/ReviewTest.java`

Targets:

- `src/lib/srs/scheduler.ts`
- `src/data/repos/reviewRepository.ts`
- `src/data/repos/settingsRepository.ts`
- `src/lib/dates.ts`

## Constants

```ts
export const DEFAULT_INTERVALS = [1, 3, 7, 16, 35] as const;

export const ReviewResult = {
  FORGOT: 0,
  PARTIAL: 1,
  GOOD: 2,
} as const;
```

Settings keys:

- `review_intervals`, stored as `"1, 3, 7, 16, 35"` by `join`.
- `last_backup_at`.

When `review_intervals` is missing or parses as invalid, use `DEFAULT_INTERVALS`.

## Day rules

- `today()` is local start of day, epoch milliseconds.
- `endOfToday(now)` is `startOfDay(addDays(startOfDay(now), 1)) - 1`. Do not compute it as `start + 24h`; Morocco changes clocks twice a year.
- `addDays(dayStart, n)` adds local calendar days, then returns start of that day.
- `daysBetween(from, to)` is `Math.round((to - from) / 86_400_000)` after both are day starts. This is an elapsed-hours approximation, not a calendar-day count. Preserve it if a screen uses it.
- `dueDate` is always a day start.

## Scheduler

```ts
export type Schedule = {
  intervalIndex: number;
  dueDate: number;
  intervalDays: number;
};

export function sanitize(intervals: number[] | null): number[];
export function parseIntervals(text: string | null): number[] | null;
export function joinIntervals(intervals: number[]): string;
export function initial(intervals: number[] | null, today: number): Schedule;
export function afterGrade(
  intervals: number[] | null,
  currentIndex: number,
  result: number,
  today: number,
): Schedule;
```

`sanitize`:

1. If `null`, empty, or no value greater than 0, return a copy of `DEFAULT_INTERVALS`.
2. Keep only values greater than 0.
3. Cap each kept value at 365.
4. Preserve order.

`parseIntervals`:

1. Return `null` for `null`.
2. Split on `[,،\s]+`, allowing Arabic comma and any whitespace.
3. Skip empty parts.
4. Parse each part as a base-10 integer.
5. Return `null` if any part is not an integer, is `<= 0`, or is `> 365`.
6. Return `null` if no parts remain.

`joinIntervals`: join with `", "`.

`initial`: `intervalIndex = 0`, `intervalDays = safe[0]`, `dueDate = addDays(today, safe[0])`.

`afterGrade`:

- Reject any result outside 0, 1, 2 with `bad-result`.
- `FORGOT` sets index 0.
- `PARTIAL` keeps `clamp(currentIndex, 0, safe.length - 1)`.
- `GOOD` sets `clamp(currentIndex + 1, 0, safe.length - 1)`.
- `intervalDays = safe[index]`, `dueDate = addDays(today, intervalDays)`.

## Add, grade, postpone

`add(entryId)`:

- Fail with `entry-not-found` if the entry does not exist.
- Return the existing review item without changes if one exists.
- Otherwise use `initial(settings.intervalsBlocking(), today)`.
- Store `lastResult = -1`, `totalReviews = 0`, `createdAt = Date.now()`.
- First review is due after the first interval, not today.

`grade(entryId, result)`:

- Reject invalid result with `bad-result`.
- Fail with `not-in-review` when no item exists.
- Apply `afterGrade` with the item's current index.
- Update `intervalIndex`, `dueDate`, `lastReviewedAt = Date.now()`, `lastResult`, and increment `totalReviews`.
- Insert one `review_logs` row with `entryId`, `reviewedAt = Date.now()`, `result`, `nextDueAt = dueDate`, `intervalDays`.
- Wrap the item update and log insert in one transaction.

`postpone(entryId, days)`:

- Reject `days <= 0` with `bad-days`.
- Fail with `not-in-review` when no item exists.
- Base is `max(item.dueDate, today)`.
- New due date is `addDays(base, days)`.

`remove(entryId)`: delete the review item by entry. Cascades delete logs only if the entry is deleted; removing from review leaves logs.

## Lists and counts

`dueList`:

- Query items with `dueDate <= endOfToday`.
- Skip items whose entry is missing.
- `overdue = item.dueDate < today`.
- Keep DAO order.

`upcoming(limit)`:

- Query all items.
- Skip `dueDate <= endOfToday`.
- Skip items whose entry is missing.
- Return at most `limit`.

`counts` returns exactly:

```ts
[dueCount, upcomingCount, itemCount, logCount]
```

where due is `dueDate <= endOfToday`, upcoming is `dueDate > endOfToday`, items is all review items, and logs is all review logs.

## Vectors from `ReviewTest.java`

Defaults `[1, 3, 7, 16, 35]`:

| Call | Result |
|---|---|
| `initial(defaults, today)` | index 0, days 1, due `today + 1` |
| `afterGrade(defaults, 0, GOOD, today)` | index 1, days 3, due `today + 3` |
| `afterGrade(defaults, 2, PARTIAL, today)` | index 2, days 7 |
| `afterGrade(defaults, 3, FORGOT, today)` | index 0, days 1 |

Other assertions:

- `afterGrade([1, 3], 1, GOOD, today)` stays at index 1 and days 3.
- `parseIntervals("1, 4, 9 , 21")` returns `[1, 4, 9, 21]`.
- `parseIntervals("1, صفر, 3")` returns `null`.
- `parseIntervals("0, 3")` returns `null`.
- `parseIntervals(" ")` returns `null`.
- `sanitize(null)` has the default length, 5.
- Adding an entry schedules tomorrow, and due count today remains 0.
- Adding the same entry twice keeps one review item.
- Grading `GOOD` records one log, sets `lastResult = GOOD`, `totalReviews = 1`, and due `today + 3`.
- A due date of `today - 2` is overdue.
- Postponing 3 days from an overdue item sets due `today + 3`.
- Upcoming excludes due-today items and marks `overdue = false`.
- Removing an item makes item count 0.
- Grading a missing item fails.
