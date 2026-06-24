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
$ProjectRef = "ebccdpydoptajlkmqefx"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$FunctionsDir = Join-Path $ProjectRoot "supabase\functions"
Set-Location $ProjectRoot

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

# Functions to deploy
$Functions = @("alert-aggregator", "crisis-pins")

foreach ($fn in $Functions) {
    $fnDir = Join-Path $FunctionsDir $fn
    if (-not (Test-Path $fnDir)) {
        Write-Host "SKIP: $fn (no folder)" -ForegroundColor Yellow
        continue
    }
    Write-Host "Deploying $fn ..." -ForegroundColor Cyan
    & pwsh -Command "$cliCmd functions deploy $fn --project-ref $ProjectRef --no-verify-jwt"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAILED: $fn" -ForegroundColor Red
    } else {
        Write-Host "  OK: $fn" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Done. Test with:" -ForegroundColor Cyan
Write-Host "  Invoke-RestMethod -Method POST -Uri 'https://ebccdpydoptajlkmqefx.supabase.co/functions/v1/alert-aggregator' -Headers @{'Authorization'='Bearer <SERVICE_ROLE_KEY>'}"
