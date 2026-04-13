'use client';

import { apiFetch, getToken } from '@/lib/api';
import { inr, isoDate } from '@/lib/format';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';

type Detail = {
  id: string;
  name: string | null;
  email: string | null;
  phone: string | null;
  appUserStatus: string;
  joinedAt: string;
  currency: string | null;
  totalBalance: number;
  accounts: { id: string; balance: unknown; type: string }[];
  stats: {
    expenseCount: number;
    incomeCount: number;
    notificationCount: number;
    lastExpenseAt: string | null;
    lastIncomeAt: string | null;
  };
};

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [u, setU] = useState<Detail | null>(null);
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    if (!id) return;
    setErr('');
    apiFetch<Detail>(`/admin/users/${id}`, { token: getToken() })
      .then(setU)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  async function setStatus(next: 'active' | 'banned') {
    if (!id || !u) return;
    if (!confirm(`Set user status to ${next}?`)) return;
    setBusy(true);
    try {
      await apiFetch(`/admin/users/${id}/status`, {
        method: 'PATCH',
        token: getToken(),
        body: JSON.stringify({ status: next }),
      });
      await load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  async function removeUser() {
    if (!id) return;
    if (!confirm('Soft-delete this user? They will be marked deleted in the database.')) return;
    setBusy(true);
    try {
      await apiFetch(`/admin/users/${id}`, { method: 'DELETE', token: getToken() });
      router.push('/dashboard/users');
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  if (err) return <p className="text-red-400">{err}</p>;
  if (!u) return <p className="text-mf-muted">Loading…</p>;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center gap-4">
        <Link href="/dashboard/users" className="text-sm text-mf-muted hover:text-mf-lime">
          ← Users
        </Link>
        <h1 className="text-2xl font-bold">{u.name ?? 'User'}</h1>
        <span
          className={
            u.appUserStatus === 'banned' ? 'text-red-400' : 'text-emerald-400'
          }
        >
          {u.appUserStatus}
        </span>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-mf-muted">
            Profile
          </h2>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Email</dt>
              <dd>{u.email ?? '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Phone</dt>
              <dd>{u.phone ?? '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Joined</dt>
              <dd>{isoDate(u.joinedAt)}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Currency</dt>
              <dd>{u.currency ?? '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Total balance</dt>
              <dd className="font-semibold text-mf-lime">{inr(u.totalBalance)}</dd>
            </div>
          </dl>
        </div>

        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-mf-muted">
            Activity
          </h2>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Expenses</dt>
              <dd>{u.stats.expenseCount}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Incomes</dt>
              <dd>{u.stats.incomeCount}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Notifications</dt>
              <dd>{u.stats.notificationCount}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Last expense</dt>
              <dd>{u.stats.lastExpenseAt ? isoDate(u.stats.lastExpenseAt) : '—'}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-mf-muted">Last income</dt>
              <dd>{u.stats.lastIncomeAt ? isoDate(u.stats.lastIncomeAt) : '—'}</dd>
            </div>
          </dl>
        </div>
      </div>

      {u.accounts.length > 0 ? (
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <h2 className="mb-3 text-xs font-semibold uppercase tracking-wide text-mf-muted">
            Accounts
          </h2>
          <ul className="space-y-2 text-sm">
            {u.accounts.map((a) => (
              <li key={a.id} className="flex justify-between border-b border-white/5 py-2">
                <span className="text-mf-muted">{a.type}</span>
                <span>{inr(Number(a.balance))}</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      <div className="flex flex-wrap gap-3">
        {u.appUserStatus !== 'banned' ? (
          <button
            type="button"
            disabled={busy}
            onClick={() => setStatus('banned')}
            className="rounded-xl border border-red-400/50 px-4 py-2 text-sm text-red-400 hover:bg-red-400/10"
          >
            Ban user
          </button>
        ) : (
          <button
            type="button"
            disabled={busy}
            onClick={() => setStatus('active')}
            className="rounded-xl border border-emerald-400/50 px-4 py-2 text-sm text-emerald-400 hover:bg-emerald-400/10"
          >
            Activate user
          </button>
        )}
        <button
          type="button"
          disabled={busy}
          onClick={removeUser}
          className="rounded-xl border border-white/20 px-4 py-2 text-sm text-mf-muted hover:bg-white/5"
        >
          Delete user
        </button>
      </div>
    </div>
  );
}
