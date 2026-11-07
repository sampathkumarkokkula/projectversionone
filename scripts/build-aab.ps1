<#
.SYNOPSIS
  Builds the Google Play bundle (milestone M2): dist\bvm-<version>-release.aab
#>
[CmdletBinding()]
param([switch] $SkipTests)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'env.ps1')
$repo = Split-Path -Parent $PSScriptRoot
Push-Location $repo
try {
    if (-not (Test-Path 'android\key.properties')) {
        & (Join-Path $PSScriptRoot 'create-keystore.ps1')
    }
    $envFile = Join-Path $repo '.env'
    if (-not (Test-Path $envFile)) { throw '.env is required for a Play build (see .env.example).' }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    dart run build_runner build
    if ($LASTEXITCODE -ne 0) { throw 'build_runner failed' }
    if (-not $SkipTests) {
        flutter test --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'tests failed' }
    }

    flutter build appbundle --release --no-pub --obfuscate --split-debug-info=build\symbols "--dart-define-from-file=$envFile"
    if ($LASTEXITCODE -ne 0) { throw 'flutter build appbundle failed' }

    $version = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value.Replace('+', '-')
    New-Item -ItemType Directory -Force -Path 'dist' | Out-Null
    $target = Join-Path 'dist' "bvm-$version-release.aab"
    Copy-Item 'build\app\outputs\bundle\release\app-release.aab' $target -Force
    Write-Host "Bundle: $target"
    Write-Host 'Upload it in Play Console > Testing > Closed testing. Keep build\symbols for crash de-obfuscation.'
} finally {
    Pop-Location
}
