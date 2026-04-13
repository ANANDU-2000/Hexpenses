'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const items = [
  { href: '/dashboard', label: 'Dashboard' },
  { href: '/dashboard/users', label: 'Users' },
  { href: '/dashboard/transactions', label: 'Transactions' },
  { href: '/dashboard/analytics', label: 'Analytics' },
  { href: '/dashboard/notifications', label: 'Notifications' },
  { href: '/dashboard/documents', label: 'Documents' },
  { href: '/dashboard/budgets', label: 'Budgets' },
  { href: '/dashboard/settings', label: 'Settings' },
];

export function Sidebar({ onLogout }: { onLogout: () => void }) {
  const path = usePathname();
  return (
    <aside className="flex w-56 flex-col border-r border-white/10 bg-mf-card/80">
      <div className="border-b border-white/10 p-4">
        <div className="text-lg font-bold text-mf-lime">MoneyFlow AI</div>
        <div className="text-xs text-mf-muted">Admin</div>
      </div>
      <nav className="flex flex-1 flex-col gap-1 p-3">
        {items.map((it) => {
          const active =
            it.href === '/dashboard'
              ? path === '/dashboard'
              : path === it.href || path.startsWith(it.href + '/');
          return (
            <Link
              key={it.href}
              href={it.href}
              className={`rounded-xl px-3 py-2 text-sm font-medium transition ${
                active
                  ? 'bg-mf-lime/15 text-mf-lime'
                  : 'text-mf-muted hover:bg-white/5 hover:text-white'
              }`}
            >
              {it.label}
            </Link>
          );
        })}
      </nav>
      <div className="border-t border-white/10 p-3">
        <button
          type="button"
          onClick={onLogout}
          className="w-full rounded-xl border border-white/10 px-3 py-2 text-sm text-mf-muted hover:bg-white/5"
        >
          Logout
        </button>
      </div>
    </aside>
  );
}
