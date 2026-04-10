/** YYYY-MM-DD in the given IANA time zone. */
export function calendarDayInTimeZone(timeZone: string, d = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: timeZone || 'UTC',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(d);
}

/** Store expense date at UTC noon for the calendar day to avoid boundary shifts. */
export function parseYmdToUtcNoon(ymd: string): Date {
  const [y, m, d] = ymd.split('-').map((x) => parseInt(x, 10));
  if (!y || !m || !d) return new Date();
  return new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
}
