# Finance tracker — MoneyFlow AI

Full-stack personal finance tracker: **Flutter** client (`flutter-app/`), **NestJS** API with **Prisma** (`nest-backend/`), **Next.js admin dashboard** (`admin-panel/`), and **Docker Compose** for local infrastructure.

**Development:** HEXASTACK SOLUTION \| Surag

## Repository layout

| Path | Description |
|------|-------------|
| `flutter-app/` | Cross-platform app (mobile, desktop, web); Drift offline cache, Riverpod |
| `nest-backend/` | REST API (`/api`), JWT auth, workspaces, expenses, budgets, admin routes, AI insights, WhatsApp hooks |
| `admin-panel/` | Next.js 14 admin UI (dashboard, users, transactions, analytics, etc.) — port **3001** in dev |
| `docker-compose.yml` | Postgres and supporting services for local dev |
| `DESIGN.md` | UI / product design notes (Flutter) |
| `HOW_TO_RUN.md` / [`how-to-run.md`](how-to-run.md) | **Full setup:** install requirements, PostgreSQL, backend, Flutter, admin, troubleshooting |
| `APP_FEATURES.md` | Product / platform feature overview (marketing & handoff) |
| `USER_GUIDE.md` | **End-user help:** how to use the app (tabs, Home, transactions, budgets, sync) |

## Quick start

> For **detailed steps** (Postgres URLs, migrations, seeds, Flutter defines, admin `.env.local`), see **[HOW_TO_RUN.md](HOW_TO_RUN.md)**.

## Stack installation (all components)

Install these first:

- **Node.js**: 18.x or 20.x LTS
- **npm**: comes with Node.js
- **Flutter SDK**: stable channel (`flutter doctor` must pass)
- **PostgreSQL**: 14+ (16 recommended)
- **Optional Redis**: for queue-backed notifications/jobs
- **Optional Docker Desktop**: easiest local infra

Verify:

```bash
node -v
npm -v
flutter doctor
psql --version
```

## Database connectivity (PostgreSQL)

Set `DATABASE_URL` in `nest-backend/.env`:

- **Local Postgres (5432)**  
  `DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/moneyflow"`

- **Docker Compose Postgres (host 5433)**  
  `DATABASE_URL="postgresql://postgres:postgres@localhost:5433/moneyflow"`

Create DB if needed:

```sql
CREATE DATABASE moneyflow;
```

Connectivity checklist:

1. Postgres service is running.
2. Username/password in `DATABASE_URL` are correct.
3. Port matches your running Postgres (`5432` local, `5433` compose default).
4. DB `moneyflow` exists.
5. Then run:

```bash
cd nest-backend
npx prisma generate
npx prisma migrate deploy
npx prisma db seed
```

If Prisma shows `P1000 Authentication failed`, your DB credentials/port in `DATABASE_URL` are wrong.

**Backend**

```bash
cd nest-backend
cp .env.example .env   # set DATABASE_URL, JWT_SECRET; optional REDIS_DISABLED=true
npm install
npx prisma migrate deploy
npx prisma db seed
npm run start:dev
```

API listens on **http://localhost:4000** with prefix **/api**.

**Flutter**

```bash
cd flutter-app
flutter pub get
flutter run
```

Override API: `flutter run --dart-define=API_BASE=http://127.0.0.1:4000/api`. Offline demo: `--dart-define=NO_API=true`.

**Admin panel (Next.js)**

```bash
cd admin-panel
cp .env.local.example .env.local   # NEXT_PUBLIC_API_URL=http://localhost:4000/api
npm install
npm run dev
```

Open **http://localhost:3001**. Seed admin login (after `npx prisma db seed`): **admin@money.com** / **Money@hexastack26** — change in production; details in [HOW_TO_RUN.md](HOW_TO_RUN.md).

## Admin credentials (seed)

After running `npx prisma db seed` in `nest-backend`, the admin account is:

| Field | Value |
|------|-------|
| Email | `admin@money.com` |
| Password | `Money@hexastack26` |

Use these only for local development/demo. Rotate credentials in staging/production.

## Docker

```bash
docker compose up -d postgres
```

Use host port **5433** and `DATABASE_URL` as described in `HOW_TO_RUN.md` and `nest-backend/.env.example`.

## Security

Do not commit real `.env` or `.env.local` files. The root `.gitignore` excludes `.env` and common secrets. Rotate JWT secrets and admin credentials for any public deployment.

## License

See [`LICENSE`](LICENSE).
