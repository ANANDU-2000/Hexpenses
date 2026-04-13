const base = () => process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

export type ApiEnvelope<T> = { success: boolean; data: T };

function unwrap<T>(json: unknown): T {
  if (json && typeof json === 'object' && 'data' in json) {
    return (json as ApiEnvelope<T>).data;
  }
  return json as T;
}

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('mf_admin_token');
}

export function setToken(t: string | null) {
  if (typeof window === 'undefined') return;
  if (t) localStorage.setItem('mf_admin_token', t);
  else localStorage.removeItem('mf_admin_token');
}

export async function apiFetch<T>(
  path: string,
  init?: RequestInit & { token?: string | null },
): Promise<T> {
  const token = init?.token ?? getToken();
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(init?.headers || {}),
  };
  if (token) (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${base()}${path}`, { ...init, headers });
  const text = await res.text();
  let json: unknown = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    throw new Error(text || res.statusText);
  }
  if (!res.ok) {
    const msg =
      json && typeof json === 'object' && 'message' in json
        ? String((json as { message: unknown }).message)
        : text;
    throw new Error(msg || res.statusText);
  }
  return unwrap<T>(json);
}

/** Plain response (e.g. CSV) with Bearer token; triggers browser download. */
export async function downloadAuthorized(path: string, filename: string) {
  const token = getToken();
  const res = await fetch(`${base()}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(t || res.statusText);
  }
  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export async function apiLogin(email: string, password: string) {
  const json = await fetch(`${base()}/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  }).then(async (r) => {
    const t = await r.text();
    const body = t ? JSON.parse(t) : null;
    if (!r.ok) throw new Error(body?.message || r.statusText);
    return body;
  });
  const data = json?.data ?? json;
  return data as {
    accessToken: string;
    admin: { id: string; email: string; name: string; role: string };
  };
}
