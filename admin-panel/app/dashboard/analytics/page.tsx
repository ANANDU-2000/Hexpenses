'use client';

import { apiFetch, getToken } from '@/lib/api';
import { useEffect, useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

type Analytics = {
  dailyActiveUsers: { day: string; users: number }[];
  screenUsage: { screen: string; events: number; durationMs: unknown }[];
  loginFrequencyTop: { userId: string; sessions: number }[];
};

export default function AnalyticsPage() {
  const [data, setData] = useState<Analytics | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    apiFetch<Analytics>('/admin/dashboard/analytics', { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, []);

  if (err) return <p className="text-red-400">{err}</p>;
  if (!data) return <p className="text-mf-muted">Loading analytics…</p>;

  const screenData = data.screenUsage.map((s) => ({
    screen: s.screen || '(unknown)',
    events: s.events,
    minutes: Math.round(Number(s.durationMs) / 60000),
  }));

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">App usage</h1>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <div className="text-xs font-medium uppercase text-mf-muted">DAU series</div>
          <div className="mt-2 text-2xl font-bold">{data.dailyActiveUsers.length}</div>
          <div className="text-xs text-mf-muted">Days in window (30d)</div>
        </div>
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <div className="text-xs font-medium uppercase text-mf-muted">Tracked screens</div>
          <div className="mt-2 text-2xl font-bold">{data.screenUsage.length}</div>
          <div className="text-xs text-mf-muted">Top routes by events</div>
        </div>
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <div className="text-xs font-medium uppercase text-mf-muted">Login tokens (top)</div>
          <div className="mt-2 text-2xl font-bold">{data.loginFrequencyTop.length}</div>
          <div className="text-xs text-mf-muted">Users with most refresh tokens</div>
        </div>
      </div>

      <div className="rounded-card border border-white/10 bg-mf-card p-4">
        <h2 className="mb-4 text-sm font-semibold text-mf-muted">Daily active users</h2>
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data.dailyActiveUsers}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ffffff22" />
              <XAxis dataKey="day" stroke="#8D93A1" fontSize={10} interval={6} />
              <YAxis stroke="#8D93A1" fontSize={11} />
              <Tooltip
                contentStyle={{ background: '#121A2B', border: '1px solid #ffffff22' }}
              />
              <Line type="monotone" dataKey="users" stroke="#8B9CFF" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="rounded-card border border-white/10 bg-mf-card p-4">
        <h2 className="mb-4 text-sm font-semibold text-mf-muted">Screen usage (events)</h2>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={screenData} layout="vertical" margin={{ left: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#ffffff22" />
              <XAxis type="number" stroke="#8D93A1" fontSize={11} />
              <YAxis
                type="category"
                dataKey="screen"
                stroke="#8D93A1"
                fontSize={10}
                width={120}
              />
              <Tooltip
                contentStyle={{ background: '#121A2B', border: '1px solid #ffffff22' }}
                formatter={(v: number, name: string) =>
                  name === 'minutes' ? [`${v} min`, 'Session time'] : [v, 'Events']
                }
              />
              <Bar dataKey="events" fill="#E6FF4D" name="events" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="rounded-card border border-white/10 bg-mf-card p-4">
        <h2 className="mb-4 text-sm font-semibold text-mf-muted">Login frequency (top users)</h2>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="text-mf-muted">
              <tr>
                <th className="p-2 font-medium">User ID</th>
                <th className="p-2 font-medium">Refresh tokens</th>
              </tr>
            </thead>
            <tbody>
              {data.loginFrequencyTop.map((r) => (
                <tr key={r.userId} className="border-t border-white/5">
                  <td className="p-2 font-mono text-xs">{r.userId}</td>
                  <td className="p-2">{r.sessions}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
