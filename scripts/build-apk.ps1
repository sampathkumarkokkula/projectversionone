<#
.SYNOPSIS
  Builds the signed release APK: dist\bvm-<version>-release.apk

.DESCRIPTION
  1. Uses the project-local toolchain (scripts\env.ps1).
  2. Creates the upload keystore on first use (scripts\create-keystore.ps1).
  3. Regenerates Drift code, runs the unit tests (skip with -SkipTests).
  4. flutter build apk --release with obfuscation, passing .env through
     --dart-define-from-file (Supabase URL/key, optional Firebase ids).
  5. Copies the APK and its SHA-256 checksum to dist\.

  Without a .env file the APK still builds, but starts in "not configured"
  mode (it cannot reach a server).
#>
[CmdletBinding()]
param(
    [switch] $SkipTests,
    [switch] $SplitPerAbi
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'env.ps1')
$repo = Split-Path -Parent $PSScriptRoot
Push-Location $repo
try {
    if (-not (Test-Path 'android\key.properties')) {
        & (Join-Path $PSScriptRoot 'create-keystore.ps1')
    }

    $envFile = Join-Path $repo '.env'
    if (-not (Test-Path $envFile)) {
        Write-Warning '.env not found: the APK will start in "not configured" mode. Copy .env.example to .env and fill it in.'
    }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
    dart run build_runner build
    if ($LASTEXITCODE -ne 0) { throw 'build_runner failed' }

    if (-not $SkipTests) {
        flutter test --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'tests failed' }
    }

    $buildArgs = @('build', 'apk', '--release', '--no-pub', '--obfuscate', '--split-debug-info=build\symbols')
    if ($SplitPerAbi) { $buildArgs += '--split-per-abi' }
    if (Test-Path $envFile) { $buildArgs += "--dart-define-from-file=$envFile" }
    flutter @buildArgs
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk failed' }

    $version = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value.Replace('+', '-')
    New-Item -ItemType Directory -Force -Path 'dist' | Out-Null
    Get-ChildItem 'build\app\outputs\flutter-apk' -Filter '*-release.apk' | ForEach-Object {
        $name = $_.Name.Replace('app-', "bvm-$version-")
        $target = Join-Path 'dist' $name
        Copy-Item $_.FullName $target -Force
        $hash = (Get-FileHash -Algorithm SHA256 $target).Hash.ToLowerInvariant()
        "$hash  $name" | Set-Content -Path "$target.sha256" -Encoding ascii
        Write-Host ("{0}  ({1:N1} MB)  sha256 {2}" -f $target, ($_.Length / 1MB), $hash)
    }
} finally {
    Pop-Location
}
