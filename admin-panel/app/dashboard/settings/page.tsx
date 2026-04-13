'use client';

import { apiFetch, downloadAuthorized, getToken } from '@/lib/api';
import { useCallback, useEffect, useState } from 'react';

type SettingRow = { id: string; key: string; value: string; updatedAt: string };

export default function SettingsPage() {
  const [rows, setRows] = useState<SettingRow[] | null>(null);
  const [err, setErr] = useState('');
  const [key, setKey] = useState('default_currency');
  const [value, setValue] = useState('INR');
  const [rules, setRules] = useState('budget_alert_threshold=0.9');
  const [busy, setBusy] = useState(false);
  const [exportBusy, setExportBusy] = useState(false);

  const load = useCallback(() => {
    setErr('');
    apiFetch<SettingRow[]>('/admin/settings', { token: getToken() })
      .then(setRows)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function savePair(k: string, v: string) {
    setBusy(true);
    try {
      await apiFetch('/admin/settings', {
        method: 'POST',
        token: getToken(),
        body: JSON.stringify({ key: k, value: v }),
      });
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setBusy(false);
    }
  }

  async function saveCurrency() {
    await savePair(key.trim() || 'default_currency', value.trim());
  }

  async function saveRules() {
    await savePair('notification_rules', rules.trim());
  }

  async function exportUsers() {
    setExportBusy(true);
    try {
      await downloadAuthorized('/admin/export/users.csv', 'moneyflow-users.csv');
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Export failed');
    } finally {
      setExportBusy(false);
    }
  }

  async function exportTx() {
    setExportBusy(true);
    try {
      await downloadAuthorized('/admin/export/transactions.csv', 'moneyflow-transactions.csv');
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Export failed');
    } finally {
      setExportBusy(false);
    }
  }

  if (err) return <p className="text-red-400">{err}</p>;
  if (!rows) return <p className="text-mf-muted">Loading…</p>;

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold">Settings</h1>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-card border border-white/10 bg-mf-card p-6">
          <h2 className="text-sm font-semibold text-mf-muted">App configuration</h2>
          <p className="mt-1 text-xs text-mf-muted">
            Key/value store in PostgreSQL (<code className="text-mf-lime">AppSetting</code>).
          </p>
          <div className="mt-4 space-y-3">
            <label className="block text-xs text-mf-muted">
              Setting key
              <input
                value={key}
                onChange={(e) => setKey(e.target.value)}
                className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
              />
            </label>
            <label className="block text-xs text-mf-muted">
              Value (e.g. INR, USD)
              <input
                value={value}
                onChange={(e) => setValue(e.target.value)}
                className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
              />
            </label>
            <button
              type="button"
              disabled={busy}
              onClick={saveCurrency}
              className="rounded-xl bg-mf-lime px-4 py-2 text-sm font-semibold text-black"
            >
              Save setting
            </button>
          </div>

          <div className="mt-8 border-t border-white/10 pt-6">
            <h3 className="text-xs font-semibold uppercase text-mf-muted">Notification rules</h3>
            <p className="mt-1 text-xs text-mf-muted">
              Stored as a single string; adjust format to match your mobile app parser.
            </p>
            <textarea
              value={rules}
              onChange={(e) => setRules(e.target.value)}
              rows={3}
              className="mt-3 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm"
            />
            <button
              type="button"
              disabled={busy}
              onClick={saveRules}
              className="mt-2 rounded-xl border border-white/10 px-4 py-2 text-sm hover:bg-white/5"
            >
              Save rules
            </button>
          </div>
        </div>

        <div className="space-y-6">
          <div className="rounded-card border border-white/10 bg-mf-card p-6">
            <h2 className="text-sm font-semibold text-mf-muted">Admin profile</h2>
            <p className="mt-2 text-sm text-mf-muted">
              JWT is stored in this browser. To change admin credentials, update the seed or database
              directly.
            </p>
          </div>

          <div className="rounded-card border border-white/10 bg-mf-card p-6">
            <h2 className="text-sm font-semibold text-mf-muted">Export data</h2>
            <div className="mt-4 flex flex-wrap gap-2">
              <button
                type="button"
                disabled={exportBusy}
                onClick={exportUsers}
                className="rounded-xl bg-mf-lime px-4 py-2 text-sm font-semibold text-black disabled:opacity-50"
              >
                Users CSV
              </button>
              <button
                type="button"
                disabled={exportBusy}
                onClick={exportTx}
                className="rounded-xl border border-white/10 px-4 py-2 text-sm disabled:opacity-50"
              >
                Transactions CSV
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="rounded-card border border-white/10 bg-mf-card p-4">
        <h2 className="text-sm font-semibold text-mf-muted">All settings</h2>
        <div className="mt-3 overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-mf-muted">
              <tr>
                <th className="p-2 font-medium">Key</th>
                <th className="p-2 font-medium">Value</th>
                <th className="p-2 font-medium">Updated</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id} className="border-t border-white/5">
                  <td className="p-2 font-mono text-xs">{r.key}</td>
                  <td className="p-2">{r.value}</td>
                  <td className="p-2 text-mf-muted">{new Date(r.updatedAt).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {rows.length === 0 ? (
            <p className="text-mf-muted">No rows yet — save a setting above.</p>
          ) : null}
        </div>
      </div>
    </div>
  );
}
