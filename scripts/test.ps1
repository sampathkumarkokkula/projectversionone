<#
.SYNOPSIS
  Static analysis + unit tests with the project-local toolchain.

.PARAMETER WithOlm
  Also compiles vodozemac's Rust bindings for this PC (a few minutes the first
  time) so test/olm_crypto_test.dart can exercise the real E2E handshake.
  Without it, those tests run only if that host build already exists.

.PARAMETER WithServer
  Also validates the Supabase SQL (local PostgreSQL) and the Edge Function
  helpers (Deno), when those tools exist under .toolchain\validation.
#>
[CmdletBinding()]
param([switch] $WithOlm, [switch] $WithServer)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'env.ps1')
$repo = Split-Path -Parent $PSScriptRoot
$validation = Join-Path $repo '.toolchain\validation'
Push-Location $repo
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    dart run build_runner build
    if ($LASTEXITCODE -ne 0) { throw 'build_runner failed' }
    flutter analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reported issues' }

    $olmOut = Join-Path $validation 'vodozemac-host'
    $olmLib = Join-Path $olmOut 'release\vodozemac_bindings_dart.dll'
    if ($WithOlm -and -not (Test-Path $olmLib)) {
        $crate = Get-ChildItem (Join-Path $env:PUB_CACHE 'hosted\pub.dev') -Directory -Filter 'flutter_vodozemac-*' |
            Sort-Object Name | Select-Object -Last 1
        Push-Location (Join-Path $crate.FullName 'rust')
        try {
            cargo build --release --locked --target-dir $olmOut
            if ($LASTEXITCODE -ne 0) { throw 'host build of vodozemac failed' }
        } finally { Pop-Location }
    }
    if (Test-Path $olmLib) { $env:BVM_VODOZEMAC_LIB_DIR = Split-Path $olmLib }

    flutter test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'tests failed' }

    if ($WithServer) {
        & (Join-Path $repo 'supabase\tests\validate-local.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Supabase schema validation failed' }
        $deno = Join-Path $validation 'deno.exe'
        if (Test-Path $deno) {
            $env:DENO_DIR = Join-Path $validation 'deno-cache'
            & $deno check --no-config supabase/functions/push/index.ts supabase/functions/delete-account/index.ts
            if ($LASTEXITCODE -ne 0) { throw 'Edge Function type check failed' }
            & $deno test --no-config supabase/tests/fcm_test.ts
            if ($LASTEXITCODE -ne 0) { throw 'Edge Function tests failed' }
        }
    }
} finally {
    Pop-Location
}
