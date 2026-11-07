<#
.SYNOPSIS
  Runs the BVM migration and the RLS/RPC checks on a throw-away local
  PostgreSQL (portable binaries under .toolchain\validation\pgsql).

.DESCRIPTION
  Supabase-only pieces (auth.uid(), Vault, pg_cron, the Realtime publication)
  are replaced by stubs from local_stubs.sql, and the two CREATE EXTENSION
  lines for supabase_vault / pg_cron are skipped. Everything else runs exactly
  as written. Validation only; deploy with the Supabase SQL editor or CLI.
#>
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pg = Join-Path $repo '.toolchain\validation\pgsql\bin'
if (-not (Test-Path (Join-Path $pg 'postgres.exe'))) {
    throw "Portable PostgreSQL not found in $pg (download the EDB Windows binaries zip there)."
}
$data = Join-Path $env:TEMP ('bvm-pg-' + [guid]::NewGuid().ToString('N'))
$port = 54329
$log = "$data.server.log"
$psql = Join-Path $pg 'psql.exe'
$pgctl = Join-Path $pg 'pg_ctl.exe'

function Invoke-Psql([string] $database, [string[]] $arguments) {
    $all = @('-h', 'localhost', '-p', "$port", '-U', 'postgres', '-d', $database, '-v', 'ON_ERROR_STOP=1', '-q', '-X') + $arguments
    $output = & $psql @all 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    $output | Where-Object { $_ -and $_ -notmatch '^\s*$' } | ForEach-Object { Write-Host "    $_" }
    if ($code -ne 0) { throw "psql failed ($($arguments -join ' '))" }
}

$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$failed = $null
try {
    & (Join-Path $pg 'initdb.exe') -D $data -U postgres -A trust -E UTF8 --no-locale *> $null
    if ($LASTEXITCODE -ne 0) { throw 'initdb failed' }
    # Through cmd so the background server does not inherit our output pipes.
    cmd /c "`"$pgctl`" -D `"$data`" -l `"$log`" -o `"-p $port`" -w start > nul 2>&1"
    if ($LASTEXITCODE -ne 0) { throw 'postgres did not start' }

    Write-Host '==> create database'
    Invoke-Psql 'postgres' @('-c', 'create database bvm')
    Write-Host '==> Supabase stubs'
    Invoke-Psql 'bvm' @('-f', (Join-Path $PSScriptRoot 'local_stubs.sql'))

    $migration = Get-Content -Raw (Join-Path $repo 'supabase\migrations\20261031000000_bvm_init.sql')
    $migration = $migration -replace '(?m)^create extension if not exists (supabase_vault|pg_cron)[^;]*;', '-- skipped locally: $0'
    $tmp = "$data.migration.sql"
    [System.IO.File]::WriteAllText($tmp, $migration, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host '==> migration (first run)'
    Invoke-Psql 'bvm' @('-f', $tmp)
    Write-Host '==> migration (second run, must be re-runnable)'
    Invoke-Psql 'bvm' @('-f', $tmp)
    Write-Host '==> RLS / RPC checks'
    Invoke-Psql 'bvm' @('-f', (Join-Path $PSScriptRoot 'rls_test.sql'))
} catch {
    $failed = $_.Exception.Message
} finally {
    cmd /c "`"$pgctl`" -D `"$data`" -m fast -w stop > nul 2>&1"
    $ErrorActionPreference = $previous
    Remove-Item -Recurse -Force $data, "$data.migration.sql" -ErrorAction SilentlyContinue
}
if ($failed) {
    Write-Host "FAILED: $failed" -ForegroundColor Red
    if (Test-Path $log) { Get-Content $log -Tail 20 | ForEach-Object { Write-Host "    log: $_" } }
    exit 1
}
Remove-Item -Force $log -ErrorAction SilentlyContinue
Write-Host 'Supabase schema validated.' -ForegroundColor Green
