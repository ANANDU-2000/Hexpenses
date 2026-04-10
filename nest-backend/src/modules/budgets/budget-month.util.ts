/** Calendar month as integer YYYYMM (e.g. 202604). */
export function toYearMonth(year: number, month1to12: number): number {
  return year * 100 + month1to12;
}

export function parseYearMonth(ym: number): { year: number; month: number } {
  return { year: Math.floor(ym / 100), month: ym % 100 };
}

export function monthRangeUtc(ym: number): { start: Date; end: Date } {
  const { year, month } = parseYearMonth(ym);
  const start = new Date(Date.UTC(year, month - 1, 1, 0, 0, 0, 0));
  const end = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0));
  return { start, end };
}

/** Accepts "2026-04" or "2026-4"; returns YYYYMM. */
export function parseMonthQuery(s: string | undefined, now = new Date()): number {
  if (!s?.trim()) {
    return toYearMonth(now.getUTCFullYear(), now.getUTCMonth() + 1);
  }
  const m = s.trim().match(/^(\d{4})-(\d{1,2})$/);
  if (!m) {
    return toYearMonth(now.getUTCFullYear(), now.getUTCMonth() + 1);
  }
  const y = Number(m[1]);
  const mo = Number(m[2]);
  if (!Number.isFinite(y) || mo < 1 || mo > 12) {
    return toYearMonth(now.getUTCFullYear(), now.getUTCMonth() + 1);
  }
  return toYearMonth(y, mo);
}

export function formatMonthLabel(ym: number): string {
  const { year, month } = parseYearMonth(ym);
  return `${year}-${String(month).padStart(2, '0')}`;
}
