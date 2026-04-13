'use client';

import { Sidebar } from '@/components/Sidebar';
import { getToken, setToken } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ok, setOk] = useState(false);

  useEffect(() => {
    if (!getToken()) router.replace('/login');
    else setOk(true);
  }, [router]);

  function logout() {
    setToken(null);
    router.replace('/login');
  }

  if (!ok) {
    return (
      <div className="flex min-h-screen items-center justify-center text-mf-muted">
        Loading…
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar onLogout={logout} />
      <main className="flex-1 overflow-auto p-6">{children}</main>
    </div>
  );
}
