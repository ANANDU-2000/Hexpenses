'use client';

import { apiFetch, getToken } from '@/lib/api';
import { useEffect, useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

type Overview = {
  cards: {
    totalUsers: number;
    activeUsersLast7Days: number;
    bannedUsers: number;
    totalTransactions: number;
    totalExpense: number;
    totalIncome: number;
    appUsageSessionCount7d: number;
  };
  charts: {
    userGrowth: { month: string; count: number }[];
    dailyTransactions: { day: string; expenses: number; incomes: number }[];
    incomeVsExpense: { name: string; value: number }[];
  };
};

const PIE_COLORS = ['#22C697', '#F07070'];

export default function DashboardPage() {
  const [data, setData] = useState<Overview | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    apiFetch<Overview>('/admin/dashboard/overview', { token: getToken() })
      .then(setData)
      .catch((e) => setErr(e instanceof Error ? e.message : 'Failed'));
  }, []);

  if (err) return <p className="text-red-400">{err}</p>;
  if (!data) return <p className="text-mf-muted">Loading overview…</p>;

  const { cards, charts } = data;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Total users" value={cards.totalUsers} />
        <StatCard label="Active (7d)" value={cards.activeUsersLast7Days} />
        <StatCard label="Transactions" value={cards.totalTransactions} />
        <StatCard label="Sessions (7d)" value={cards.appUsageSessionCount7d} />
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <StatCard
          label="Total income"
          value={`\u20B9${cards.totalIncome.toLocaleString('en-IN')}`}
        />
        <StatCard
          label="Total expense"
          value={`\u20B9${cards.totalExpense.toLocaleString('en-IN')}`}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <h2 className="mb-4 text-sm font-semibold text-mf-muted">User growth</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={charts.userGrowth}>
                <CartesianGrid strokeDasharray="3 3" stroke="#ffffff22" />
                <XAxis dataKey="month" stroke="#8D93A1" fontSize={11} />
                <YAxis stroke="#8D93A1" fontSize={11} />
                <Tooltip
                  contentStyle={{ background: '#121A2B', border: '1px solid #ffffff22' }}
                />
                <Line type="monotone" dataKey="count" stroke="#E6FF4D" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
        <div className="rounded-card border border-white/10 bg-mf-card p-4">
          <h2 className="mb-4 text-sm font-semibold text-mf-muted">Daily transactions (30d)</h2>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={charts.dailyTransactions}>
                <CartesianGrid strokeDasharray="3 3" stroke="#ffffff22" />
                <XAxis dataKey="day" stroke="#8D93A1" fontSize={9} interval={4} />
                <YAxis stroke="#8D93A1" fontSize={11} />
                <Tooltip
                  contentStyle={{ background: '#121A2B', border: '1px solid #ffffff22' }}
                />
                <Legend />
                <Bar dataKey="expenses" fill="#F07070" name="Expenses" stackId="a" />
                <Bar dataKey="incomes" fill="#22C697" name="Incomes" stackId="a" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div className="rounded-card border border-white/10 bg-mf-card p-4">
        <h2 className="mb-4 text-sm font-semibold text-mf-muted">Income vs expense</h2>
        <div className="mx-auto h-72 w-full max-w-md">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={charts.incomeVsExpense}
                dataKey="value"
                nameKey="name"
                cx="50%"
                cy="50%"
                outerRadius={100}
                label
              >
                {charts.incomeVsExpense.map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{ background: '#121A2B', border: '1px solid #ffffff22' }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-card border border-white/10 bg-mf-card p-4">
      <div className="text-xs font-medium uppercase tracking-wide text-mf-muted">{label}</div>
      <div className="mt-2 text-2xl font-bold text-white">{value}</div>
    </div>
  );
}
