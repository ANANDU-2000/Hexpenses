# How to run — MoneyFlow AI

Step-by-step setup for the **NestJS API**, **PostgreSQL**, **Flutter app**, and **Next.js admin panel**.  
Developed by **HEXASTACK SOLUTION** (Surag).

---

## 1. Installation requirements

### All platforms

| Tool | Version / notes |
|------|------------------|
| **Node.js** | 18.x or 20.x LTS (for `nest-backend` and `admin-panel`) |
| **npm** | Bundled with Node |
| **PostgreSQL** | 14+ recommended; repo tested with **16** (Docker or local) |
| **Flutter** | Stable channel, **Dart SDK** compatible with `flutter-app/pubspec.yaml` (`>=3.2.0 <4.0.0`) |
| **Git** | For cloning the repository |

### Optional

| Tool | When |
|------|------|
| **Redis** | Notifications / BullMQ queues. Set `REDIS_DISABLED=true` in `nest-backend/.env` if you skip Redis. |
| **Docker Desktop** | Easiest Postgres + Redis via `docker compose`. |
| **Android Studio / Xcode** | Mobile emulators and device builds. |
| **Chrome** | `flutter run -d chrome` for web. |

### Verify installs

```bash
node -v
npm -v
psql --version
flutter doctor
```

---

## 2. PostgreSQL configuration

### Option A — Docker (recommended if you already use Docker)

From the **repository root**:

```bash
docker compose up -d postgres
```

- **Host port:** `5433` (avoids conflict with a local Postgres on `5432`).
- **Database:** `moneyflow`
- **User / password:** `postgres` / `postgres`

**`DATABASE_URL` for Nest on the host machine:**

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5433/moneyflow"
```

### Option B — Local PostgreSQL

1. Install PostgreSQL and start the service.
2. Create the database (psql, pgAdmin, or CLI):

   ```sql
   CREATE DATABASE moneyflow;
   ```

3. Set `DATABASE_URL` in `nest-backend/.env`, for example:

   ```env
   DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/moneyflow"
   ```

4. If the password contains special characters (e.g. `@`), **URL-encode** them in the connection string.

### Prisma commands (always from `nest-backend/`)

```bash
cd nest-backend
npx prisma generate
npx prisma migrate deploy
npx prisma db seed
```

- **`migrate deploy`**: applies pending migrations (use in dev/CI; safe for existing DBs).
- **`migrate dev`**: creates a new migration during schema changes (developer workflow).
- **`db seed`**: demo app user + **admin panel user** (see [Admin panel credentials](#5-admin-panel-nextjs)).

If you see **“table Admin does not exist”**, migrations were not applied — run `npx prisma migrate deploy`.

---

## 3. Backend (NestJS)

```bash
cd nest-backend
cp .env.example .env
```

Edit **`.env`**: set `DATABASE_URL`, `JWT_SECRET`, and optionally `REDIS_DISABLED=true` if Redis is not running.

```bash
npm install
npx prisma generate
npx prisma migrate deploy
npx prisma db seed
npm run start:dev
```

- **API base:** `http://localhost:4000`
- **Global prefix:** `/api` (e.g. health and routes under `http://localhost:4000/api/...`).

### Run API without Postgres (smoke test only)

In `.env`:

```env
DATABASE_DISABLED=true
REDIS_DISABLED=true
```

Auth and real data routes need a real database.

---

## 4. Flutter app

```bash
cd flutter-app
flutter pub get
flutter run
```

Pick a device when prompted (Android emulator, iOS simulator, Chrome, Windows, etc.).

### API URL

Default compile-time base is in `lib/core/api_config.dart` (`http://127.0.0.1:4000/api`). Override when needed:

```bash
flutter run --dart-define=API_BASE=http://YOUR_HOST:4000/api
```

### Offline / no-backend mode

Uses local **Drift** + demo data (no Nest):

```bash
flutter run --dart-define=NO_API=true
```

The first time you open the app in this mode, a **Get started** onboarding explains the demo. Reopen it anytime from **Profile → Demo → Get started**. To see the flow again from scratch, clear app storage / reinstall (the completion flag is `mf_demo_get_started_completed` in `SharedPreferences`).

### Web note

On web, Drift may log that it uses **IndexedDB** fallback when `SharedArrayBuffer` is not available — this is normal in development unless you serve with COOP/COEP headers.

### App behavior (working end-to-end)

1. Start **Postgres**, run **migrations + seed**, start **Nest** (`npm run start:dev`).
2. Start **Flutter**; ensure `API_BASE` points at your machine’s API.
3. Sign in with the **demo user** created by seed (see seed output in terminal after `npx prisma db seed`), or register a new user if your API allows it.
4. Data syncs over REST; with `NO_API=true`, only local demo data is used.

**Helping new users:** share **[USER_GUIDE.md](USER_GUIDE.md)** for a plain-language tour of tabs, Home, transactions, budgets, and sync.

---

## 5. Admin panel (Next.js)

The admin UI lives in **`admin-panel/`** (React / Next.js 14, Tailwind, Recharts). It talks to the same Nest API under `/api/admin/...`.

### Setup

```bash
cd admin-panel
cp .env.local.example .env.local
```

Edit **`.env.local`**:

```env
NEXT_PUBLIC_API_URL=http://localhost:4000/api
```

If the API runs on another host/port, change this URL accordingly (must include the `/api` prefix).

```bash
npm install
npm run dev
```

- **Dev server:** [http://localhost:3001](http://localhost:3001) (see `package.json` script `next dev -p 3001`).

### Production build

```bash
npm run build
npm run start
```

Serve behind HTTPS in production; point `NEXT_PUBLIC_API_URL` at your public API.

### Admin panel credentials (seed)

These are created/updated by **`npx prisma db seed`** in `nest-backend`:

| Field | Value |
|-------|--------|
| **Email** | `admin@money.com` |
| **Password** | `Money@hexastack26` |

Login is case-insensitive for email on the API. **Change these in production** (update the `Admin` row and hashing policy as appropriate).

---

## 6. Quick command summary

| Goal | Command |
|------|---------|
| Postgres (Docker) | `docker compose up -d postgres` |
| API + DB migrate + seed | `cd nest-backend && npm install && npx prisma migrate deploy && npx prisma db seed && npm run start:dev` |
| Flutter | `cd flutter-app && flutter pub get && flutter run` |
| Admin UI | `cd admin-panel && npm install && npm run dev` |

---

## 7. Troubleshooting

| Issue | What to try |
|-------|-------------|
| Prisma P1000 / auth failed | Check `DATABASE_URL`, Postgres running, DB exists, password encoding. |
| `Admin` table missing | `cd nest-backend && npx prisma migrate deploy` |
| Flutter cannot reach API | Same machine: use `127.0.0.1` or `10.0.2.2` (Android emulator); set `API_BASE`. |
| Redis connection errors | Set `REDIS_DISABLED=true` in `nest-backend/.env` for local dev. |
| Admin login fails | Run seed; verify email/password above; API must be on URL matching `.env.local`. |

---

## 8. Security

- Do **not** commit real `.env` or `.env.local` files.
- Rotate **JWT_SECRET**, **admin password**, and **demo user** credentials for any public deployment.
- See root **`README.md`** for repository layout and high-level overview.

---

*HEXASTACK SOLUTION — Surag*
