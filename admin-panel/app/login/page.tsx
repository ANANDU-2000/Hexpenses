'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { apiLogin, setToken } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@Money.com');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    setLoading(true);
    try {
      const { accessToken } = await apiLogin(email.trim(), password);
      setToken(accessToken);
      router.push('/dashboard');
    } catch (ex) {
      setErr(ex instanceof Error ? ex.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-mf-bg px-4">
      <div className="w-full max-w-md rounded-card border border-white/10 bg-mf-card p-8 shadow-xl">
        <h1 className="text-2xl font-bold text-mf-lime">Admin sign in</h1>
        <p className="mt-1 text-sm text-mf-muted">MoneyFlow AI control panel</p>
        <form onSubmit={onSubmit} className="mt-8 space-y-4">
          <div>
            <label className="block text-xs font-medium text-mf-muted">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm outline-none focus:border-mf-lime/50"
              autoComplete="username"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-mf-muted">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full rounded-xl border border-white/10 bg-mf-bg px-3 py-2 text-sm outline-none focus:border-mf-lime/50"
              autoComplete="current-password"
            />
          </div>
          {err ? <p className="text-sm text-red-400">{err}</p> : null}
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-mf-lime py-2.5 text-sm font-semibold text-black hover:opacity-90 disabled:opacity-50"
          >
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
