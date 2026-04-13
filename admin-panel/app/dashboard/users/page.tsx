'use client';

import { apiFetch, getToken } from '@/lib/api';
import { isoDate } from '@/lib/format';
import Link from 'next/link';
import { useCallback, useEffect, useState } from 'react';

type Row = {
  id: string;
  name: string | null;
  email: string | null;
  phone: string | null;
  appUserStatus: string;
  currency: string | null;
  createdAt: string;
};

type ListRes = { rows: Row[]; total: number };

export default function UsersPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<'all' | 'active' | 'banned'>('all');
  const [skip, setSkip] = useState(0);
  const [refreshKey, setRefreshKey] = useState(0);
  const take = 30;

  const load = useCallback(() => {
    setErr('');
    const q = new URLSearchParams();
    if (search.trim()) q.set('search', search.trim());
    if (status !== 'all') q.set('status', status);
    q.set('skip', String(skip));
    q.set('take', String(take));
    apiFetch<ListRes>(`/admin/users?${q}`, { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, [search, status, skip, refreshKey]);

  useEffect(() => {
    load();
  }, [load]);

  if (err) return <p className="text-red-400">{err}</p>;
  if (!data) return <p className="text-mf-muted">Loading users…</p>;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <h1 className="text-2xl font-bold">Users</h1>
        <div className="flex flex-wrap gap-2">
          <input
            placeholder="Search name or email"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="rounded-xl border border-white/10 bg-mf-card px-3 py-2 text-sm outline-none focus:border-mf-lime/40"
          />
          <select
            value={status}
            onChange={(e) => {
              setSkip(0);
              setStatus(e.target.value as typeof status);
            }}
            className="rounded-xl border border-white/10 bg-mf-card px-3 py-2 text-sm outline-none"
          >
            <option value="all">All statuses</option>
            <option value="active">Active</option>
            <option value="banned">Banned</option>
          </select>
          <button
            type="button"
            onClick={() => {
              setSkip(0);
              setRefreshKey((k) => k + 1);
            }}
            className="rounded-xl bg-mf-lime px-4 py-2 text-sm font-semibold text-black"
          >
            Apply
          </button>
        </div>
      </div>

      <div className="overflow-x-auto rounded-card border border-white/10 bg-mf-card">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead className="border-b border-white/10 text-mf-muted">
            <tr>
              <th className="p-3 font-medium">User</th>
              <th className="p-3 font-medium">Email</th>
              <th className="p-3 font-medium">Status</th>
              <th className="p-3 font-medium">Joined</th>
              <th className="p-3 font-medium" />
            </tr>
          </thead>
          <tbody>
            {data.rows.map((u) => (
              <tr key={u.id} className="border-b border-white/5 hover:bg-white/[0.03]">
                <td className="p-3 font-medium text-white">{u.name ?? '—'}</td>
                <td className="p-3 text-mf-muted">{u.email ?? '—'}</td>
                <td className="p-3">
                  <span
                    className={
                      u.appUserStatus === 'banned'
                        ? 'text-red-400'
                        : 'text-emerald-400'
                    }
                  >
                    {u.appUserStatus}
                  </span>
                </td>
                <td className="p-3 text-mf-muted">{isoDate(u.createdAt)}</td>
                <td className="p-3 text-right">
                  <Link
                    href={`/dashboard/users/${u.id}`}
                    className="text-mf-lime hover:underline"
                  >
                    View
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between text-sm text-mf-muted">
        <span>
          Showing {data.rows.length} of {data.total}
        </span>
        <div className="flex gap-2">
          <button
            type="button"
            disabled={skip === 0}
            onClick={() => setSkip((s) => Math.max(0, s - take))}
            className="rounded-lg border border-white/10 px-3 py-1 disabled:opacity-40"
          >
            Previous
          </button>
          <button
            type="button"
            disabled={skip + take >= data.total}
            onClick={() => setSkip((s) => s + take)}
            className="rounded-lg border border-white/10 px-3 py-1 disabled:opacity-40"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  );
}
