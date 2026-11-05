// Ported from app/src/main/java/com/waraq/app/util/Validation.java
import { isBlank } from './arabicText';

export function titleError(title: string): string | null {
  return isBlank(title) ? 'عنوان الكتاب مطلوب' : null;
}

export function pagesError(total: number | null, current: number): string | null {
  if (total != null) {
    if (total <= 0) return 'إجمالي الصفحات يجب أن يكون أكبر من صفر';
    if (current < 0 || current > total) return 'الصفحة الحالية يجب ألا تتجاوز الإجمالي';
  } else if (current < 0) {
    return 'رقم الصفحة يجب أن يكون صفرًا أو أكثر';
  }
  return null;
}

export function ratingError(rating: number | null): string | null {
  if (rating == null) return null;
  return rating < 0 || rating > 5 ? 'التقييم من 0 إلى 5' : null;
}

export function sessionError(
  start: number | null,
  end: number | null,
  duration: number | null,
  total: number | null,
): string | null {
  if (start == null || start < 0) return 'رقم الصفحة يجب أن يكون صفرًا أو أكثر';
  if (end == null || end < start) return 'صفحة النهاية يجب ألا تقل عن صفحة البداية';
  if (duration == null || duration <= 0) return 'أدخل مدة أكبر من صفر';
  if (total != null && total > 0 && end > total) return 'صفحة النهاية تتجاوز إجمالي صفحات الكتاب';
  return null;
}

export function parseIntOrNull(s: string | null): number | null {
  if (s == null) return null;
  const t = s.trim();
  if (!t || !/^\d+$/.test(t)) return null;
  return Number(t);
}
