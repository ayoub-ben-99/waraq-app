// Ported from app/src/main/java/com/waraq/app/util/Dates.java
const months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

export function startOfDay(millis: number): number {
  const d = new Date(millis);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

export function endOfDay(millis: number): number {
  return startOfDay(addDays(startOfDay(millis), 1)) - 1;
}

export function today(): number {
  return startOfDay(Date.now());
}

export function addDays(dayStart: number, days: number): number {
  const d = new Date(dayStart);
  d.setDate(d.getDate() + days);
  return startOfDay(d.getTime());
}

export function daysBetween(fromDayStart: number, toDayStart: number): number {
  const diff = startOfDay(toDayStart) - startOfDay(fromDayStart);
  return Math.round(diff / 86400000);
}

export function format(millis: number): string {
  const d = new Date(millis);
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
}

export function formatShort(millis: number): string {
  const d = new Date(millis);
  return `${d.getDate()} ${months[d.getMonth()].slice(0, 3)} ${d.getFullYear()}`;
}

export function formatDateTime(millis: number): string {
  const d = new Date(millis);
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}، ${hh}:${mm}`;
}

export function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes} د`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (m === 0) return `${h} س`;
  return `${h} س ${m} د`;
}

export function formatIso(millis: number): string {
  const d = new Date(millis);
  const pad = (n: number, l = 2) => String(Math.abs(n)).padStart(l, '0');
  const offset = -d.getTimezoneOffset();
  const sign = offset >= 0 ? '+' : '-';
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(
    d.getHours(),
  )}:${pad(d.getMinutes())}:${pad(d.getSeconds())}.${pad(d.getMilliseconds(), 3)}${sign}${pad(
    Math.floor(Math.abs(offset) / 60),
  )}${pad(Math.abs(offset) % 60)}`;
}

export function dateStamp(millis: number): string {
  const d = new Date(millis);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export function dayStartLabel(millis: number): string {
  return new Intl.DateTimeFormat('ar-u-nu-latn', { weekday: 'short' }).format(new Date(millis));
}
