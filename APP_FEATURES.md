# MoneyFlow AI — Product & platform features

**A modern personal finance experience for Indian users and global patterns — mobile-first, API-driven, with an operator-grade admin surface.**

**Development:** HEXASTACK SOLUTION \| Surag

---

## Why MoneyFlow AI

- **Single ledger** for day-to-day money: income, expenses, budgets, and insights in one coherent flow.
- **Offline-aware client**: fast local cache (Drift) with optional sync to a **NestJS + PostgreSQL** backend.
- **Fintech-grade UI**: dark-first layouts, clear rupee formatting, and patterns inspired by leading expense and banking apps.
- **Extensible server**: JWT auth, workspaces, documents, investments, insurance, vehicles, recurring rules, WhatsApp hooks, and AI insight hooks — ready to grow with your roadmap.

---

## Mobile & desktop (Flutter)

| Area | Highlights |
|------|------------|
| **Dashboard** | Balances, cashflow snapshots, quick actions, recent activity. |
| **Expenses & income** | Categorized transactions, lists, add/edit flows, Indian locale-friendly amounts (INR / ₹ formatting). |
| **Budgets** | Monthly caps and visibility into spend vs limit. |
| **Accounts** | Multi-account picture for net worth and transfers. |
| **Investments & wealth** | Portfolio-oriented data model (where enabled). |
| **Insurance & vehicles** | Structured coverage and asset records. |
| **Documents** | Attach and organize scans and PDFs. |
| **Recurring** | Templates for repeating income and expenses. |
| **Insights** | AI / rule-driven insight cards on the home experience. |
| **Notifications** | In-app notification center aligned with the API. |
| **Profile & settings** | Theme, preferences, and session-aware profile. |
| **WhatsApp** | Integration surface for link status and messaging workflows (backend-supported). |
| **Offline mode** | Run with demo data without a server (`NO_API`) for demos and UI work. |

**Tech:** Flutter, Riverpod, Dio, Drift, Material 3, custom design tokens.

---

## Backend (NestJS)

| Capability | Description |
|------------|-------------|
| **REST API** | Versioned JSON API under `/api`, consistent envelopes and validation. |
| **Auth** | JWT access/refresh, secure password handling, session-friendly refresh tokens. |
| **PostgreSQL + Prisma** | Typed schema, migrations, and seed data for local QA. |
| **Workspaces** | Multi-user organization of accounts and data. |
| **Core domains** | Users, expenses, incomes, categories, budgets, accounts, documents, notifications, recurring, AI insights, WhatsApp webhooks, and more. |
| **Redis / queues** | Optional BullMQ for async jobs (can be disabled for simple local dev). |
| **Encryption hooks** | Field-level encryption options for sensitive columns (when configured). |

---

## Admin panel (Next.js)

Built for **operators and product owners** who need visibility without opening the mobile app.

| Module | Capabilities |
|--------|----------------|
| **Dashboard** | User counts, activity, transaction totals, income vs expense, charts (growth, daily volume, mix). |
| **Users** | Search, filter, detail view, ban/activate, soft-delete. |
| **Transactions** | Unified expense/income list, filters, admin edit/delete. |
| **Analytics** | Daily active users, screen usage, login frequency signals. |
| **Notifications** | Broadcast or targeted in-app notifications. |
| **Documents** | List, filter, delete uploaded files. |
| **Budgets** | Overspend monitoring and category-level views. |
| **Settings** | App-level key/value config; CSV export for users and transactions. |

**Tech:** Next.js 14, React, Tailwind CSS, Recharts, JWT to the same API as the mobile app.

---

## DevOps & quality

- **Docker Compose** for Postgres (and optional Redis / API) in one command.
- **Prisma migrations** for repeatable database evolution.
- **Seed data** for demo login and admin access in non-production environments.

---

## Engagement & licensing

MoneyFlow AI is engineered as a **scalable product foundation**: ship a polished consumer app, keep data in **your** PostgreSQL instance, and extend the Nest modules as your feature set grows.

For **custom development, white-label delivery, or enterprise deployment**, contact **HEXASTACK SOLUTION**.

**Using the app:** see **[USER_GUIDE.md](USER_GUIDE.md)** for new-user help (tabs, Home, transactions, budgets).

---

*HEXASTACK SOLUTION \| Surag — Finance, built clear.*
