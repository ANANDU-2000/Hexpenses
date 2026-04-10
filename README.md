# The Ledger — Enhanced Personal Expense Tracker

Production-oriented full-stack finance tracker: **React (Vite) + Tailwind CSS** frontend, **Django REST Framework + JWT** backend, **SQLite** for local development and **PostgreSQL** for production. UI follows the design system in `DESIGN.md` and the reference layout in `code.html` / `screen.png`.

## Features

- **Authentication**: Registration, login, JWT access/refresh, secure password hashing.
- **Expenses & income**: CRUD for expenses (including bill image upload), create/list income; unified ledger feed with search, filters, and pagination.
- **Categories**: Per-user categories with optional **monthly budgets**; category icons for the ledger.
- **Dashboard**: Balance, totals, monthly category bar chart, recent transactions.
- **Insights**: Pie chart, trend line, income vs expenses bar chart, rule-based “smart insights” (month-over-month category comparisons).
- **Reports**: `GET /api/reports?start=&end=` aggregations; **CSV** and **PDF** export.
- **Notifications**: Budget warnings and monthly spend summary via `GET /api/notifications`.
- **Recurring**: Flag transactions as weekly/monthly; run `python manage.py apply_recurring` (or schedule it) to materialize next occurrences.
- **Frontend**: Sidebar (desktop) + bottom navigation (mobile), dark/light mode, lazy-loaded pages, centralized API error handling with token refresh.

**Not included (portfolio extensions):** Rasa chatbot, Google OAuth — see “Extensions” below.

## Repository layout

```
expense-finance-tracker/
├── backend/                 # Django project
│   ├── core/                # settings, root urls
│   ├── apps/
│   │   ├── users/           # register, login, profile
│   │   ├── expenses/        # models, transactions API, categories
│   │   └── reports/         # reports, export, insight helpers
│   ├── manage.py
│   └── requirements.txt
├── frontend/                # Vite + React
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/api.js
│   │   ├── hooks/
│   │   ├── context/
│   │   └── utils/
│   └── vite.config.js       # dev proxy to Django
├── DESIGN.md
├── code.html
└── README.md
```

## API overview

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/register/` | Create user |
| POST | `/api/login/` | JWT pair |
| POST | `/api/token/refresh/` | Refresh access token |
| GET | `/api/me/` | Current user |
| GET/POST | `/api/expenses/` | List/create expenses |
| GET/PUT/PATCH/DELETE | `/api/expenses/:id/` | Expense detail |
| GET/POST | `/api/income/` | List/create income |
| GET/PUT/PATCH/DELETE | `/api/income/:id/` | Income detail |
| GET | `/api/ledger/` | Combined feed (`type`, `search`, `page`, `start`, `end`) |
| GET | `/api/ledger/summary/` | Totals and balance |
| GET/POST/PUT/PATCH/DELETE | `/api/categories/` | Categories + budgets |
| GET | `/api/reports/` | Aggregates + trend series |
| GET | `/api/reports/export/?format=csv|pdf` | Export |
| GET | `/api/insights/` | Smart insights |
| GET | `/api/notifications/` | Alerts |

## Local setup

### 1. Backend

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env   # or cp on Unix; edit values
python manage.py migrate
python manage.py createsuperuser   # optional
python manage.py runserver
```

API runs at `http://127.0.0.1:8000`. Media uploads are served under `/media/` when `DEBUG=True`.

### 2. Frontend

```bash
cd frontend
npm install
copy .env.example .env.local   # optional; defaults use Vite proxy
npm run dev
```

App runs at `http://127.0.0.1:5173`. The Vite dev server **proxies** `/api` and `/media` to port 8000 (see `frontend/vite.config.js`).

### 3. PostgreSQL (production-style)

Set in `backend/.env`:

- `USE_POSTGRES=true`
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`

Then run `migrate` again.

## Environment variables

**Backend** (`backend/.env.example`):

- `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`
- `CORS_ALLOWED_ORIGINS` (comma-separated; include your Vite/Vercel origin)
- `JWT_ACCESS_MINUTES`, `JWT_REFRESH_DAYS`
- Optional PostgreSQL variables above

**Frontend** (`frontend/.env.example`):

- `VITE_API_URL` — production base URL of the API (e.g. `https://your-api.onrender.com`). Leave empty in development to use the Vite proxy.

## Deployment

### Frontend (Vercel)

1. Connect the repo; set **Root Directory** to `frontend`.
2. Build command: `npm run build`, output: `dist`.
3. Set `VITE_API_URL` to your deployed API origin.
4. Add `vercel.json` (included) so client-side routes resolve for React Router.

### Backend (Render / Railway)

1. Root directory: `backend`.
2. Build: `pip install -r requirements.txt && python manage.py migrate && python manage.py collectstatic --noinput` (if you serve static via Whitenoise later).
3. Start: `gunicorn core.wsgi:application` (add `gunicorn` to requirements for production).
4. Set `DJANGO_DEBUG=false`, a strong `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS`, and PostgreSQL env vars.
5. Configure persistent **media** storage (S3 or similar) for bill uploads; the default file storage is local disk.

## Extensions (bonus ideas)

- **Rasa**: Run a separate Rasa server and call it from a thin Django endpoint or directly from the React app for conversational tips.
- **Google OAuth**: Add `django-allauth` or `social-auth-app-django` and a small React flow for token exchange / session bridging.

## License

See [`LICENSE`](LICENSE) in this repository (upstream default: BSL-1.0). For learning and portfolio use, comply with that license or replace it with your preferred terms.
