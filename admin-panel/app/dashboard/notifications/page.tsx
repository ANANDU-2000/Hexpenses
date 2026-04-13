'use client';

import { apiFetch, getToken } from '@/lib/api';
import { isoDate } from '@/lib/format';
import { useCallback, useEffect, useState } from 'react';

type Row = {
  id: string;
  title: string;
  body: string | null;
  category: string;
  date: string;
  user: { id: string; name: string | null; email: string | null };
};

type ListRes = { rows: Row[]; total: number };

export default function NotificationsPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [type, setType] = useState<'info' | 'alert' | 'reminder'>('info');
  const [targetUserIds, setTargetUserIds] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setErr('');
    apiFetch<ListRes>('/admin/notifications?take=40', { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function send() {
    setBusy(true);
    try {
      const userIds = targetUserIds
        .split(/[\s,]+/)
        .map((s) => s.trim())
        .filter(Boolean);
      const body: Record<string, unknown> = { title: title.trim(), message: message.trim(), type };
      if (userIds.length) body.userIds = userIds;
      await apiFetch('/admin/notifications/send', {
        method: 'POST',
        token: getToken(),
        body: JSON.stringify(body),
      });
      setTitle('');
      setMessage('');
      setTargetUserIds('');
      load();
      alert('Sent');
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  if (err) return <p className="text-red-400">{err}</p>;
  if (!data) return <p className="text-mf-muted">Loading…</p>;

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold">Notifications</h1>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-card border border-white/10 bg-mf-card p-6">
          <h2 className="text-sm font-semibold text-mf-muted">Send notification</h2>
          <p className="mt-1 text-xs text-mf-muted">
            Leave target users empty to broadcast to all active users.
          </p>
          <div className="mt-4 space-y-3">
            <input
              placeholder="Title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
            />
            <textarea
              placeholder="Message"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={4}
              className="w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
            />
            <select
              value={type}
              onChange={(e) => setType(e.target.value as typeof type)}
              className="w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
            >
              <option value="info">Info</option>
              <option value="alert">Alert</option>
              <option value="reminder">Reminder</option>
            </select>
            <input
              placeholder="Target user IDs (comma or space separated)"
              value={targetUserIds}
              onChange={(e) => setTargetUserIds(e.target.value)}
              className="w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
            />
            <button
              type="button"
              disabled={busy || !title.trim() || !message.trim()}
              onClick={send}
              className="w-full rounded-xl bg-mf-lime py-2.5 text-sm font-semibold text-black disabled:opacity-50"
            >
              Send
            </button>
          </div>
        </div>

        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <h2 className="mb-4 text-sm font-semibold text-mf-muted">Recent</h2>
          <div className="max-h-[480px] space-y-3 overflow-y-auto pr-1">
            {data.rows.map((n) => (
              <div
                key={n.id}
                className="rounded-xl border border-white/5 bg-mf-bg/50 p-3 text-sm"
              >
                <div className="flex justify-between gap-2">
                  <span className="font-medium text-white">{n.title}</span>
                  <span className="text-xs text-mf-muted">{isoDate(n.date)}</span>
                </div>
                <div className="mt-1 text-xs text-mf-purple">{n.category}</div>
                {n.body ? <p className="mt-2 text-mf-muted">{n.body}</p> : null}
                <div className="mt-2 text-xs text-mf-muted">
                  To: {n.user.name ?? n.user.email ?? n.user.id}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
