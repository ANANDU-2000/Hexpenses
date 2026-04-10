# Fixes Prisma P1000 when Postgres rejects user "postgres" / password "postgres".
# Run from repo root in PowerShell. You need the CURRENT Windows Postgres superuser password once.
#
# Usage:
#   .\scripts\fix-p1000-postgres.ps1
#   $env:PGPASSWORD = 'your_current_postgres_password'; .\scripts\fix-p1000-postgres.ps1
#
# Optional: point to psql if not on PATH:
#   $env:PSQL = 'C:\Program Files\PostgreSQL\16\bin\psql.exe'; $env:PGPASSWORD='...'; .\scripts\fix-p1000-postgres.ps1

$ErrorActionPreference = "Stop"
$TargetPassword = "postgres"
$DbName = "moneyflow"

function Find-Psql {
    if ($env:PSQL -and (Test-Path $env:PSQL)) { return $env:PSQL }
    $candidates = @(
        (Get-Command psql -ErrorAction SilentlyContinue).Source
        "C:\Program Files\PostgreSQL\17\bin\psql.exe"
        "C:\Program Files\PostgreSQL\16\bin\psql.exe"
        "C:\Program Files\PostgreSQL\15\bin\psql.exe"
        "C:\Program Files\PostgreSQL\14\bin\psql.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }
    return $candidates | Select-Object -First 1
}

$psql = Find-Psql
if (-not $psql) {
    Write-Host @"

Could not find psql.exe.

Do one of the following:
  1) Add PostgreSQL "bin" folder to your PATH, or set env PSQL to full path to psql.exe
  2) Install Docker Desktop, then from repo root run:
       docker compose up -d postgres
     (uses postgres/postgres — matches nest-backend\.env.example)
  3) Edit nest-backend\.env and set DATABASE_URL to your real user/password:
       DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/moneyflow"
     Create DB in pgAdmin: CREATE DATABASE moneyflow;

"@
    exit 1
}

Write-Host "Using: $psql"
if (-not $env:PGPASSWORD) {
    Write-Host "Set your CURRENT postgres user password for this session, then re-run:"
    Write-Host '  $env:PGPASSWORD = "the_password_you_chose_at_Postgres_install"'
    Write-Host "  .\scripts\fix-p1000-postgres.ps1"
    exit 1
}

Write-Host "Setting user postgres password to '$TargetPassword' and ensuring database '$DbName' exists..."
& $psql -U postgres -h localhost -d postgres -v ON_ERROR_STOP=1 -c "ALTER USER postgres PASSWORD '$TargetPassword';"
$exists = & $psql -U postgres -h localhost -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DbName';"
if ($exists -ne "1") {
    & $psql -U postgres -h localhost -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $DbName;"
}
Write-Host "Done. Test with:"
Write-Host "  cd nest-backend"
Write-Host "  npx prisma migrate deploy"
