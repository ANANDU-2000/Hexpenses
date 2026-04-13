'use client';

import { apiFetch, getToken } from '@/lib/api';
import { inr } from '@/lib/format';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';

type BudgetRow = {
  id: string;
  userId: string;
  user: { id: string; name: string | null; email: string | null };
  category: { id: string; name: string };
  limit: number;
  spent: number;
  exceeded: boolean;
  percent: number;
  yearMonth: number;
};

type ListRes = { rows: BudgetRow[]; overspending: BudgetRow[] };

export default function BudgetsPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [userId, setUserId] = useState('');

  const load = useCallback(() => {
    setErr('');
    const q = userId.trim() ? `?userId=${encodeURIComponent(userId.trim())}` : '';
    apiFetch<ListRes>(`/admin/budgets${q}`, { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, [userId]);

  useEffect(() => {
    load();
  }, [load]);

  const categoryAgg = useMemo(() => {
    if (!data) return [];
    const m = new Map<string, { name: string; spent: number; limit: number }>();
    for (const r of data.rows) {
      const cur = m.get(r.category.id) ?? { name: r.category.name, spent: 0, limit: 0 };
      cur.spent += r.spent;
      cur.limit += r.limit;
      m.set(r.category.id, cur);
    }
    return [...m.values()]
      .sort((a, b) => b.spent - a.spent)
      .slice(0, 12);
  }, [data]);

  if (err) return <p className="text-red-400">{err}</p>;
  if (!data) return <p className="text-mf-muted">Loading…</p>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Budgets</h1>

      <div className="flex flex-wrap gap-2 rounded-card border border-white/10 bg-mf-card p-4">
        <input
          placeholder="Filter by user ID"
          value={userId}
          onChange={(e) => setUserId(e.target.value)}
          className="rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
        />
        <button
          type="button"
          onClick={load}
          className="rounded-xl bg-mf-lime px-4 py-2 text-sm font-semibold text-black"
        >
          Apply
        </button>
      </div>

      <div className="rounded-card border border-red-400/30 bg-mf-card p-4">
        <h2 className="text-sm font-semibold text-red-400">
          Overspending this month ({data.overspending.length})
        </h2>
        <div className="mt-3 overflow-x-auto">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="text-mf-muted">
              <tr>
                <th className="p-2 font-medium">User</th>
                <th className="p-2 font-medium">Category</th>
                <th className="p-2 font-medium">Limit</th>
                <th className="p-2 font-medium">Spent</th>
                <th className="p-2 font-medium">%</th>
              </tr>
            </thead>
            <tbody>
              {data.overspending.map((r) => (
                <tr key={r.id} className="border-t border-white/5">
                  <td className="p-2">{r.user.email ?? r.user.name ?? r.userId}</td>
                  <td className="p-2">{r.category.name}</td>
                  <td className="p-2">{inr(r.limit)}</td>
                  <td className="p-2 text-red-400">{inr(r.spent)}</td>
                  <td className="p-2">{Math.round(r.percent)}%</td>
                </tr>
              ))}
            </tbody>
          </table>
          {data.overspending.length === 0 ? (
            <p className="text-mf-muted">No overspending in current UTC month.</p>
          ) : null}
        </div>
      </div>

      <div className="rounded-card border border-white/10 bg-mf-card p-4">
        <h2 className="mb-4 text-sm font-semibold text-mf-muted">Spend by category (aggregated)</h2>
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={categoryAgg}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ffffff22" />
              <XAxis dataKey="name" stroke="#8D93A1" fontSize={10} interval={0} angle={-25} textAnchor="end" height={60} />
              <YAxis stroke="#8D93A1" fontSize={11} />
              <Tooltip
                contentStyle={{ background: '#121A2B', border: '1px solid #ffffff22' }}
                formatter={(v: number) => inr(v)}
              />
              <Bar dataKey="spent" fill="#8B9CFF" name="Spent" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="overflow-x-auto rounded-card border border-white/10 bg-mf-card">
        <table className="w-full min-w-[900px] text-left text-sm">
          <thead className="border-b border-white/10 text-mf-muted">
            <tr>
              <th className="p-3 font-medium">User</th>
              <th className="p-3 font-medium">Category</th>
              <th className="p-3 font-medium">Limit</th>
              <th className="p-3 font-medium">Spent</th>
              <th className="p-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {data.rows.map((r) => (
              <tr key={r.id} className="border-b border-white/5">
                <td className="p-3">{r.user.email ?? r.user.name ?? '—'}</td>
                <td className="p-3">{r.category.name}</td>
                <td className="p-3">{inr(r.limit)}</td>
                <td className="p-3">{inr(r.spent)}</td>
                <td className="p-3">
                  {r.exceeded ? (
                    <span className="text-red-400">Over</span>
                  ) : (
                    <span className="text-emerald-400">OK</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
