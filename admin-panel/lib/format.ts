export function inr(n: number) {
  return `\u20B9${n.toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
}

export function isoDate(d: string | Date) {
  const x = typeof d === 'string' ? new Date(d) : d;
  return x.toISOString().slice(0, 10);
}
