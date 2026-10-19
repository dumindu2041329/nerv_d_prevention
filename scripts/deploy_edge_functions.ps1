#!/usr/bin/env pwsh
# ═══════════════════════════════════════════════════════════════════
# Deploy all NERV edge functions to Supabase
# ═══════════════════════════════════════════════════════════════════
# Prerequisites:
#   1. Generate a Supabase access token at
#      https://supabase.com/dashboard/account/tokens
#   2. Set it in your environment before running this script:
#         $env:SUPABASE_ACCESS_TOKEN = "sbp_..."
#   3. (Optional) `npx supabase login` instead of setting the env var.
#
# Usage:
#   pwsh scripts/deploy_edge_functions.ps1
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$FunctionsDir = Join-Path $ProjectRoot "supabase\functions"
Set-Location $ProjectRoot

# Project ref comes from SUPABASE_URL in .env so this script never drifts
# from the project the app actually talks to.
$EnvFile = Join-Path $ProjectRoot ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host ".env not found at $EnvFile" -ForegroundColor Red
    exit 1
}
$SupabaseUrl = (Get-Content $EnvFile | Select-String -Pattern '^\s*SUPABASE_URL\s*=\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$ProjectRef = [regex]::Match($SupabaseUrl, 'https://([A-Za-z0-9\-]+)\.supabase\.co').Groups[1].Value
if (-not $ProjectRef) {
    Write-Host "Could not parse a project ref from SUPABASE_URL=$SupabaseUrl" -ForegroundColor Red
    exit 1
}
Write-Host "Target project: $ProjectRef" -ForegroundColor Green

function Ensure-Tool {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host "  → $Name not found, using npx..." -ForegroundColor Yellow
        return $null
    }
    return $cmd.Source
}

$cli = Ensure-Tool "supabase"
$cliCmd = if ($cli) { "supabase" } else { "npx -y supabase" }

# Verify token
if (-not $env:SUPABASE_ACCESS_TOKEN) {
    Write-Host "No SUPABASE_ACCESS_TOKEN in environment." -ForegroundColor Red
    Write-Host "Either run 'npx supabase login' or set the env var." -ForegroundColor Red
    Write-Host "Get a token at: https://supabase.com/dashboard/account/tokens" -ForegroundColor Red
    exit 1
}

# Functions to deploy. Per-function verify_jwt settings are read from
# supabase/config.toml — do not pass --no-verify-jwt here or every function
# would be deployed unauthenticated.
$Functions = @(
    "weather",
    "geocode",
    "tiles",
    "contact",
    "crisis-pins",
    "alert-aggregator"
)

foreach ($fn in $Functions) {
    $fnDir = Join-Path $FunctionsDir $fn
    if (-not (Test-Path $fnDir)) {
        Write-Host "SKIP: $fn (no folder)" -ForegroundColor Yellow
        continue
    }
    Write-Host "Deploying $fn ..." -ForegroundColor Cyan
    & pwsh -Command "$cliCmd functions deploy $fn --project-ref $ProjectRef"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAILED: $fn" -ForegroundColor Red
    } else {
        Write-Host "  OK: $fn" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Secrets (required once):" -ForegroundColor Cyan
Write-Host "  $cliCmd secrets set WEATHERAPI_KEY=... MAPTILER_API_KEY=... OWM_API_KEY=... AGGREGATOR_CRON_SECRET=... --project-ref $ProjectRef"
Write-Host "  (AGGREGATOR_CRON_SECRET must ALSO exist as a Vault secret named the same -"
Write-Host "   the 20261020_alert_aggregator_cron_auth.sql migration wires pg_cron to send it"
Write-Host "   as the Bearer token. Generate one with:"
Write-Host "   node -e \"console.log(crypto.randomUUID().replace(/-/g,''))\")"

# Smoke test: invoke the aggregator with the cron secret and assert 2xx.
# A bare unauthenticated GET would now (correctly) return 403 — the same
# 403 that silently killed the alert feed before the auth contract fix.
if ($env:AGGREGATOR_CRON_SECRET) {
    Write-Host "Smoke-testing alert-aggregator ..." -ForegroundColor Cyan
    try {
        $r = Invoke-RestMethod -Method Post `
            -Uri "https://$ProjectRef.supabase.co/functions/v1/alert-aggregator" `
            -Headers @{ Authorization = "Bearer $env:AGGREGATOR_CRON_SECRET" }
        Write-Host "  OK: derived=$($r.derived) alerts=$($r.alerts)" -ForegroundColor Green
    } catch {
        Write-Host "  FAILED: alert-aggregator returned $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        Write-Host "  Check AGGREGATOR_CRON_SECRET matches between Vault, function secrets and the cron job." -ForegroundColor Yellow
    }

    # Verify the scheduled job itself succeeds (catches header drift):
    #   select status, return_code, message, start_time
    #   from cron.job_run_details order by start_time desc limit 5;
    Write-Host "After ~10 min, verify cron runs: select status, return_code from cron.job_run_details order by start_time desc limit 5;" -ForegroundColor Cyan
} else {
    Write-Host "Set `$env:AGGREGATOR_CRON_SECRET before running this script to enable the smoke test." -ForegroundColor Yellow
}
