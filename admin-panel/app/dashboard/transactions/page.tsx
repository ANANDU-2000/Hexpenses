'use client';

import { apiFetch, getToken } from '@/lib/api';
import { inr, isoDate } from '@/lib/format';
import { useCallback, useEffect, useState } from 'react';

type TxRow = {
  kind: 'expense' | 'income';
  id: string;
  userId: string;
  amount: number;
  date: string;
  note: string | null;
  categoryId: string | null;
  categoryName: string | null;
  user: { id: string; name: string | null; email: string | null };
};

type ListRes = { rows: TxRow[] };

export default function TransactionsPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [userId, setUserId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [edit, setEdit] = useState<TxRow | null>(null);
  const [form, setForm] = useState({
    amount: '',
    date: '',
    note: '',
    categoryId: '',
  });
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setErr('');
    const q = new URLSearchParams();
    if (userId.trim()) q.set('userId', userId.trim());
    if (from) q.set('from', new Date(from + 'T00:00:00.000Z').toISOString());
    if (to) q.set('to', new Date(to + 'T23:59:59.999Z').toISOString());
    if (categoryId.trim()) q.set('categoryId', categoryId.trim());
    q.set('take', '80');
    apiFetch<ListRes>(`/admin/transactions?${q}`, { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, [userId, from, to, categoryId]);

  useEffect(() => {
    load();
  }, [load]);

  function openEdit(row: TxRow) {
    setEdit(row);
    setForm({
      amount: String(row.amount),
      date: isoDate(row.date),
      note: row.note ?? '',
      categoryId: row.categoryId ?? '',
    });
  }

  async function saveEdit() {
    if (!edit) return;
    setBusy(true);
    try {
      const amount = parseFloat(form.amount);
      if (Number.isNaN(amount) || amount <= 0) throw new Error('Invalid amount');
      const body: Record<string, unknown> = {
        amount,
        date: new Date(form.date + 'T12:00:00.000Z').toISOString(),
        note: form.note || null,
      };
      if (edit.kind === 'expense' && form.categoryId.trim()) {
        body.categoryId = form.categoryId.trim();
      }
      const path =
        edit.kind === 'expense'
          ? `/admin/transactions/expenses/${edit.id}`
          : `/admin/transactions/incomes/${edit.id}`;
      await apiFetch(path, {
        method: 'PATCH',
        token: getToken(),
        body: JSON.stringify(body),
      });
      setEdit(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  async function del(row: TxRow) {
    if (!confirm(`Delete this ${row.kind}?`)) return;
    setBusy(true);
    try {
      const path =
        row.kind === 'expense'
          ? `/admin/transactions/expenses/${row.id}`
          : `/admin/transactions/incomes/${row.id}`;
      await apiFetch(path, { method: 'DELETE', token: getToken() });
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  if (err) return <p className="text-red-400">{err}</p>;
  if (!data) return <p className="text-mf-muted">Loading…</p>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Transactions</h1>

      <div className="flex flex-wrap gap-2 rounded-card border border-white/10 bg-mf-card p-4">
        <input
          placeholder="User ID"
          value={userId}
          onChange={(e) => setUserId(e.target.value)}
          className="rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm outline-none"
        />
        <input
          type="date"
          value={from}
          onChange={(e) => setFrom(e.target.value)}
          className="rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm outline-none"
        />
        <input
          type="date"
          value={to}
          onChange={(e) => setTo(e.target.value)}
          className="rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm outline-none"
        />
        <input
          placeholder="Category ID (expenses)"
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value)}
          className="rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm outline-none"
        />
        <button
          type="button"
          onClick={load}
          className="rounded-xl bg-mf-lime px-4 py-2 text-sm font-semibold text-black"
        >
          Apply filters
        </button>
      </div>

      <div className="overflow-x-auto rounded-card border border-white/10 bg-mf-card">
        <table className="w-full min-w-[900px] text-left text-sm">
          <thead className="border-b border-white/10 text-mf-muted">
            <tr>
              <th className="p-3 font-medium">Type</th>
              <th className="p-3 font-medium">Date</th>
              <th className="p-3 font-medium">User</th>
              <th className="p-3 font-medium">Category / source</th>
              <th className="p-3 font-medium">Amount</th>
              <th className="p-3 font-medium">Note</th>
              <th className="p-3 font-medium" />
            </tr>
          </thead>
          <tbody>
            {data.rows.map((r) => (
              <tr key={`${r.kind}-${r.id}`} className="border-b border-white/5">
                <td className="p-3">
                  <span className={r.kind === 'expense' ? 'text-red-400' : 'text-emerald-400'}>
                    {r.kind}
                  </span>
                </td>
                <td className="p-3 text-mf-muted">{isoDate(r.date)}</td>
                <td className="p-3">
                  <div className="text-white">{r.user.name ?? '—'}</div>
                  <div className="text-xs text-mf-muted">{r.user.email}</div>
                </td>
                <td className="p-3 text-mf-muted">{r.categoryName ?? '—'}</td>
                <td className="p-3 font-medium">{inr(r.amount)}</td>
                <td className="max-w-[200px] truncate p-3 text-mf-muted">{r.note ?? '—'}</td>
                <td className="space-x-2 p-3 text-right whitespace-nowrap">
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => openEdit(r)}
                    className="text-mf-lime hover:underline"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => del(r)}
                    className="text-red-400 hover:underline"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {edit ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
          <div className="w-full max-w-md rounded-card border border-white/10 bg-mf-card p-6 shadow-xl">
            <h2 className="text-lg font-bold capitalize">Edit {edit.kind}</h2>
            <div className="mt-4 space-y-3">
              <label className="block text-xs text-mf-muted">
                Amount
                <input
                  type="number"
                  step="0.01"
                  value={form.amount}
                  onChange={(e) => setForm((f) => ({ ...f, amount: e.target.value }))}
                  className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
                />
              </label>
              <label className="block text-xs text-mf-muted">
                Date
                <input
                  type="date"
                  value={form.date}
                  onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
                  className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
                />
              </label>
              <label className="block text-xs text-mf-muted">
                Note
                <input
                  value={form.note}
                  onChange={(e) => setForm((f) => ({ ...f, note: e.target.value }))}
                  className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
                />
              </label>
              {edit.kind === 'expense' ? (
                <label className="block text-xs text-mf-muted">
                  Category ID
                  <input
                    value={form.categoryId}
                    onChange={(e) => setForm((f) => ({ ...f, categoryId: e.target.value }))}
                    className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
                  />
                </label>
              ) : null}
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setEdit(null)}
                className="rounded-xl border border-white/10 px-4 py-2 text-sm"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={saveEdit}
                className="rounded-xl bg-mf-lime px-4 py-2 text-sm font-semibold text-black"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
