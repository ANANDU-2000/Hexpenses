# MoneyFlow Cutover and Decommission Runbook

## Canary Steps
1. Start `docker-compose.yml` with `postgres`, `redis`, and `nest-api`.
2. Point client traffic (or reverse proxy) to `nest-backend` for these endpoint groups in order:
   - auth/users
   - expenses/categories/ledger
   - recurring/notifications
   - insurance/vehicles
   - reports/ai/whatsapp
3. Validate parity using:
   - `npm run build`
   - `npm run prisma:generate`
   - `npm run verify:migration`

## Rollback Trigger
- Any authentication failure rate above threshold.
- Recurring queue backlog above SLA.
- Report total mismatches beyond allowed tolerance.

## Decommission Action
- Django API returns HTTP 410 at `/api/` from `backend/core/urls.py`.
- React frontend is replaced by Flutter client (`flutter-app/`).
