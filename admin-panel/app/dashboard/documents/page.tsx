'use client';

import { apiFetch, getToken } from '@/lib/api';
import { isoDate } from '@/lib/format';
import { useCallback, useEffect, useState } from 'react';

type Row = {
  id: string;
  fileUrl: string;
  type: string;
  originalName: string | null;
  mimeType: string | null;
  uploadedAt: string;
  user: { id: string; name: string | null; email: string | null };
};

type ListRes = { rows: Row[]; total: number };

export default function DocumentsPage() {
  const [data, setData] = useState<ListRes | null>(null);
  const [err, setErr] = useState('');
  const [userId, setUserId] = useState('');
  const [type, setType] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setErr('');
    const q = new URLSearchParams();
    if (userId.trim()) q.set('userId', userId.trim());
    if (type.trim()) q.set('type', type.trim());
    q.set('take', '60');
    apiFetch<ListRes>(`/admin/documents?${q}`, { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, [userId, type]);

  useEffect(() => {
    load();
  }, [load]);

  async function remove(id: string) {
    if (!confirm('Delete this document?')) return;
    setBusy(true);
    try {
      await apiFetch(`/admin/documents/${id}`, { method: 'DELETE', token: getToken() });
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
      <h1 className="text-2xl font-bold">Documents</h1>

      <div className="flex flex-wrap gap-2 rounded-card border border-white/10 bg-mf-card p-4">
        <input
          placeholder="User ID"
          value={userId}
          onChange={(e) => setUserId(e.target.value)}
          className="rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
        />
        <input
          placeholder="Type filter"
          value={type}
          onChange={(e) => setType(e.target.value)}
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

      <div className="overflow-x-auto rounded-card border border-white/10 bg-mf-card">
        <table className="w-full min-w-[800px] text-left text-sm">
          <thead className="border-b border-white/10 text-mf-muted">
            <tr>
              <th className="p-3 font-medium">File</th>
              <th className="p-3 font-medium">Type</th>
              <th className="p-3 font-medium">User</th>
              <th className="p-3 font-medium">Uploaded</th>
              <th className="p-3 font-medium" />
            </tr>
          </thead>
          <tbody>
            {data.rows.map((d) => (
              <tr key={d.id} className="border-b border-white/5">
                <td className="p-3">
                  <div className="font-medium">{d.originalName ?? d.fileUrl}</div>
                  <div className="text-xs text-mf-muted">{d.mimeType ?? '—'}</div>
                </td>
                <td className="p-3 text-mf-muted">{d.type}</td>
                <td className="p-3">
                  <div>{d.user.name ?? '—'}</div>
                  <div className="text-xs text-mf-muted">{d.user.email}</div>
                </td>
                <td className="p-3 text-mf-muted">{isoDate(d.uploadedAt)}</td>
                <td className="p-3 text-right">
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => remove(d.id)}
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

      <p className="text-sm text-mf-muted">Total: {data.total}</p>
    </div>
  );
}
