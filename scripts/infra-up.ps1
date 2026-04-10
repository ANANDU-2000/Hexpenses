# Start Postgres + Redis via Docker, then apply Prisma migrations (MoneyFlow AI).
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Host "Docker not found. Install Docker Desktop for Windows, then run this script again." -ForegroundColor Yellow
  exit 1
}

docker compose up -d postgres redis
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Waiting for Postgres health..." -ForegroundColor Cyan
$deadline = (Get-Date).AddSeconds(60)
do {
  Start-Sleep -Seconds 2
  try {
    docker compose exec -T postgres pg_isready -U postgres -d moneyflow 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
  } catch { }
} while ((Get-Date) -lt $deadline)

$env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/moneyflow"
Set-Location (Join-Path $root "nest-backend")
npx prisma migrate deploy
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Infra is up. DATABASE_URL for local Docker Postgres: postgresql://postgres:postgres@localhost:5432/moneyflow" -ForegroundColor Green
Write-Host "Next: cd nest-backend; npm run start:dev" -ForegroundColor Green
