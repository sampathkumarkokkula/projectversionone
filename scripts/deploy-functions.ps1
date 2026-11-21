<#
.SYNOPSIS
  Deploys the Edge Functions `push` and `delete-account` to your Supabase
  project, and optionally stores the Firebase service-account key that `push`
  needs for instant notifications.

.DESCRIPTION
  * Downloads the Supabase CLI (Windows build) into .toolchain\supabase-cli on
    first use. No Docker and no Node.js are needed (--use-api bundling).
  * Reads the project ref from SUPABASE_URL in .env.
  * Needs a Supabase personal access token (supabase.com > Account >
    Access Tokens). Pass it in $env:SUPABASE_ACCESS_TOKEN or type it when
    asked; it is never written to disk.
  * With -ServiceAccount, uploads the Firebase service-account JSON as the
    function secret FCM_SERVICE_ACCOUNT (the JSON file stays where it is;
    keep it out of git and delete it afterwards if you like).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\deploy-functions.ps1 -ServiceAccount C:\Users\me\Downloads\bvm-firebase-adminsdk.json
#>
[CmdletBinding()]
param(
    [string] $ServiceAccount,
    [string] $CliVersion = '3.1.0'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repo = Split-Path -Parent $PSScriptRoot
$cliDir = Join-Path $repo ".toolchain\supabase-cli\$CliVersion"
$cli = Join-Path $cliDir 'supabase.exe'

# ---- Supabase CLI -------------------------------------------------------------
if (-not (Test-Path $cli)) {
    Write-Host "==> Downloading Supabase CLI $CliVersion"
    New-Item -ItemType Directory -Force -Path $cliDir | Out-Null
    $zip = Join-Path $cliDir 'supabase.zip'
    $url = "https://github.com/supabase/cli/releases/download/v$CliVersion/supabase_${CliVersion}_windows_amd64.zip"
    & curl.exe --fail --location --silent --show-error --retry 5 --retry-delay 5 --retry-all-errors -o $zip $url
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $url" }
    & tar.exe -xf $zip -C $cliDir
    Remove-Item -Force $zip
    if (-not (Test-Path $cli)) { throw "supabase.exe not found after extracting $url" }
}

# ---- Project ref from .env ------------------------------------------------------
$envFile = Join-Path $repo '.env'
if (-not (Test-Path $envFile)) { throw '.env not found. Copy .env.example to .env and set SUPABASE_URL first.' }
$urlLine = Get-Content $envFile | Where-Object { $_ -match '^\s*SUPABASE_URL\s*=' } | Select-Object -First 1
if ($urlLine -notmatch 'https://([a-z0-9]+)\.supabase\.co') { throw 'SUPABASE_URL in .env must look like https://<project-ref>.supabase.co' }
$ref = $Matches[1]

# ---- Access token (process environment only) -------------------------------------
if (-not $env:SUPABASE_ACCESS_TOKEN) {
    $secure = Read-Host 'Supabase access token (supabase.com > Account > Access Tokens)' -AsSecureString
    $env:SUPABASE_ACCESS_TOKEN = [System.Net.NetworkCredential]::new('', $secure).Password
}
if (-not $env:SUPABASE_ACCESS_TOKEN.StartsWith('sbp_')) { Write-Warning 'Access tokens normally start with sbp_.' }

Push-Location $repo
try {
    foreach ($fn in 'push', 'delete-account') {
        Write-Host "==> Deploying function $fn to project $ref"
        & $cli functions deploy $fn --project-ref $ref --no-verify-jwt --use-api
        if ($LASTEXITCODE -ne 0) { throw "Deploying $fn failed" }
    }

    if ($ServiceAccount) {
        if (-not (Test-Path $ServiceAccount)) { throw "File not found: $ServiceAccount" }
        $sa = Get-Content -Raw $ServiceAccount | ConvertFrom-Json
        if (-not $sa.project_id -or -not $sa.client_email -or -not $sa.private_key) {
            throw 'This is not a Firebase service-account key (expected project_id, client_email, private_key).'
        }
        Write-Host "==> Setting secret FCM_SERVICE_ACCOUNT (service account $($sa.client_email))"
        # One line, single-quoted so the env-file parser keeps it literally.
        $compact = $sa | ConvertTo-Json -Compress -Depth 5
        $tmp = Join-Path $env:TEMP ('bvm-secret-' + [guid]::NewGuid().ToString('N') + '.env')
        try {
            [System.IO.File]::WriteAllText($tmp, "FCM_SERVICE_ACCOUNT='$compact'`n", (New-Object System.Text.UTF8Encoding($false)))
            & $cli secrets set --env-file $tmp --project-ref $ref
            if ($LASTEXITCODE -ne 0) { throw 'Setting the secret failed' }
        } finally {
            Remove-Item -Force $tmp -ErrorAction SilentlyContinue
        }
    }
} finally {
    Pop-Location
}

Write-Host 'Done. Functions: push, delete-account.'
if (-not $ServiceAccount) {
    Write-Host 'No -ServiceAccount given: push answers "push-not-configured" until FCM_SERVICE_ACCOUNT is set.'
}
