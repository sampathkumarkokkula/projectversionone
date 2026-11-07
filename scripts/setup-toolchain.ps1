<#
.SYNOPSIS
  Installs a project-local build toolchain for BVM under <repo>\.toolchain.

.DESCRIPTION
  Downloads and installs, without admin rights and without touching the system
  PATH:
    - Eclipse Temurin JDK 17
    - Flutter SDK (pinned stable version, SHA-256 verified)
    - Android SDK command-line tools, platform-tools, platform, build-tools, NDK
    - Rust (rustup, GNU host toolchain + Android targets), needed to compile the
      vodozemac (Olm/Double Ratchet) native library for Android.

  The script is idempotent: components that are already present are skipped.
  Re-run it with -Force to reinstall a component.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\setup-toolchain.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\setup-toolchain.ps1 -Only flutter,android
#>
[CmdletBinding()]
param(
    [ValidateSet('jdk', 'flutter', 'android', 'rust')]
    [string[]] $Only = @('jdk', 'flutter', 'android', 'rust'),
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ---- Pinned versions ---------------------------------------------------------
$FlutterVersion = '3.47.9'
$FlutterSha256  = 'd8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e'
$JdkFeature     = 17
$RustTargets    = @('aarch64-linux-android', 'armv7-linux-androideabi', 'x86_64-linux-android', 'i686-linux-android')
$CmdlineToolsVersion = '19.0'
$CmdlineToolsZip     = 'commandlinetools-win-13114758_latest.zip'
$CmdlineToolsSha1    = '54a582f3bf73e04253602f2d1c80bd5868aac115'
# -------------------------------------------------------------------------------

. (Join-Path $PSScriptRoot 'env.ps1')
$tc = $env:BVM_TOOLCHAIN
$downloads = Join-Path $tc 'downloads'
New-Item -ItemType Directory -Force -Path $tc, $downloads | Out-Null

function Write-Step([string] $msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

function Get-File([string] $url, [string] $dest) {
    if ((Test-Path $dest) -and -not $Force) { return }
    Write-Host "    downloading $url"
    $tmp = "$dest.part"
    & curl.exe --fail --location --silent --show-error --retry 5 --retry-delay 5 -C - -o $tmp $url
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $url" }
    Move-Item -Force $tmp $dest
}

function Assert-Sha256([string] $file, [string] $expected) {
    $actual = (Get-FileHash -Algorithm SHA256 $file).Hash.ToLowerInvariant()
    if ($actual -ne $expected.ToLowerInvariant()) {
        Remove-Item -Force $file
        throw "SHA-256 mismatch for $file (expected $expected, got $actual)"
    }
}

function Assert-Sha1([string] $file, [string] $expected) {
    $actual = (Get-FileHash -Algorithm SHA1 $file).Hash.ToLowerInvariant()
    if ($actual -ne $expected.ToLowerInvariant()) {
        Remove-Item -Force $file
        throw "SHA-1 mismatch for $file (expected $expected, got $actual)"
    }
}

function Expand-Zip([string] $zip, [string] $destDir) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    & tar.exe -xf $zip -C $destDir
    if ($LASTEXITCODE -ne 0) { throw "Extraction failed: $zip" }
}

# ---- JDK -------------------------------------------------------------------------
function Install-Jdk {
    $jdkDir = $env:JAVA_HOME
    if ((Test-Path (Join-Path $jdkDir 'bin\java.exe')) -and -not $Force) {
        Write-Step "JDK already installed at $jdkDir"; return
    }
    Write-Step "Installing Temurin JDK $JdkFeature"
    $api = "https://api.adoptium.net/v3/assets/latest/$JdkFeature/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse"
    $asset = (Invoke-RestMethod -Uri $api -UseBasicParsing) | Where-Object { $_.binary.package.name -like '*.zip' } | Select-Object -First 1
    if (-not $asset) { throw 'Could not resolve a Temurin JDK zip from the Adoptium API.' }
    $zip = Join-Path $downloads $asset.binary.package.name
    Get-File $asset.binary.package.link $zip
    Assert-Sha256 $zip $asset.binary.package.checksum
    $staging = Join-Path $tc 'jdk-staging'
    if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
    Expand-Zip $zip $staging
    $inner = Get-ChildItem $staging -Directory | Select-Object -First 1
    if (Test-Path $jdkDir) { Remove-Item -Recurse -Force $jdkDir }
    Move-Item $inner.FullName $jdkDir
    Remove-Item -Recurse -Force $staging
    & (Join-Path $jdkDir 'bin\java.exe') -version
}

# ---- Flutter -----------------------------------------------------------------------
function Install-Flutter {
    $flutterDir = Join-Path $tc 'flutter'
    if ((Test-Path (Join-Path $flutterDir 'bin\flutter.bat')) -and -not $Force) {
        Write-Step "Flutter already installed at $flutterDir"
    } else {
        Write-Step "Installing Flutter $FlutterVersion"
        $zip = Join-Path $downloads "flutter_windows_$FlutterVersion-stable.zip"
        Get-File "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$FlutterVersion-stable.zip" $zip
        Assert-Sha256 $zip $FlutterSha256
        if (Test-Path $flutterDir) { Remove-Item -Recurse -Force $flutterDir }
        Expand-Zip $zip $tc
    }
    & flutter --version
    if ($LASTEXITCODE -ne 0) { throw 'flutter --version failed' }
}

# ---- Android SDK ---------------------------------------------------------------------
function Get-FlutterAndroidDefaults {
    $ext = Join-Path $tc 'flutter\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt'
    $defaults = @{ Ndk = $null; CompileSdk = $null }
    if (Test-Path $ext) {
        $src = Get-Content -Raw $ext
        if ($src -match 'ndkVersion[^"]*"([0-9.]+)"') { $defaults.Ndk = $Matches[1] }
        if ($src -match 'compileSdkVersion[^0-9]*([0-9]+)') { $defaults.CompileSdk = $Matches[1] }
    }
    return $defaults
}

function Install-AndroidSdk {
    $sdk = $env:ANDROID_HOME
    $sdkmanager = Join-Path $sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
    # Pinned on purpose: cmdline-tools 23.0+ replace sdkmanager with the new
    # "Android CLI", which writes package.xml files in schema version 4 that
    # AGP 9.1 cannot read ("Failed to find target with hash string
    # 'android-36'"). cmdline-tools 19.0 is the classic sdkmanager.
    $androidCli = Join-Path $sdk 'cmdline-tools\latest\bin\android.exe'
    if (-not (Test-Path $sdkmanager) -or (Test-Path $androidCli) -or $Force) {
        Write-Step "Installing Android SDK command-line tools $CmdlineToolsVersion"
        $zip = Join-Path $downloads $CmdlineToolsZip
        Get-File "https://dl.google.com/android/repository/$CmdlineToolsZip" $zip
        Assert-Sha1 $zip $CmdlineToolsSha1
        $staging = Join-Path $tc 'cmdline-staging'
        if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
        Expand-Zip $zip $staging
        $dest = Join-Path $sdk 'cmdline-tools\latest'
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
        Move-Item (Join-Path $staging 'cmdline-tools') $dest
        Remove-Item -Recurse -Force $staging
    } else {
        Write-Step 'Android command-line tools already installed'
    }

    $defaults = Get-FlutterAndroidDefaults
    $compileSdk = if ($defaults.CompileSdk) { $defaults.CompileSdk } else { '36' }
    $packages = @('platform-tools', "platforms;android-$compileSdk", "build-tools;$compileSdk.0.0")
    if ($defaults.Ndk) { $packages += "ndk;$($defaults.Ndk)" }

    # Packages installed earlier by the new Android CLI carry schema-v4
    # metadata that AGP cannot read; reinstall them with sdkmanager. The CLI's
    # own package store (.sdk) is not used by the build.
    $cliStore = Join-Path $sdk '.sdk'
    if (Test-Path $cliStore) { Remove-Item -Recurse -Force $cliStore }
    foreach ($dir in Get-ChildItem $sdk -Directory -Recurse -Depth 1 -ErrorAction SilentlyContinue) {
        $xml = Join-Path $dir.FullName 'package.xml'
        if ((Test-Path $xml) -and (Select-String -Path $xml -Pattern 'sdk/android/repo/repository2/04' -Quiet)) {
            Write-Host "    removing $($dir.FullName) (unreadable package metadata)"
            Remove-Item -Recurse -Force $dir.FullName
        }
    }

    Write-Step 'Accepting Android SDK licenses (https://developer.android.com/studio/terms)'
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $yes = ('y' + [Environment]::NewLine) * 50
    $yes | & $sdkmanager "--sdk_root=$sdk" --licenses *> $null
    Write-Step ('Installing SDK packages: ' + ($packages -join ', '))
    # Quote each package so cmd.exe does not split the names on ';'.
    $quoted = $packages | ForEach-Object { '"' + $_ + '"' }
    & $sdkmanager "--sdk_root=$sdk" --install @quoted
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($exit -ne 0) { throw "sdkmanager install failed (exit code $exit)" }
}

# ---- Rust ----------------------------------------------------------------------------------
function Install-Rust {
    $rustup = Join-Path $env:CARGO_HOME 'bin\rustup.exe'
    if (-not (Test-Path $rustup) -or $Force) {
        Write-Step 'Installing rustup (GNU host toolchain, no PATH changes)'
        $init = Join-Path $downloads 'rustup-init.exe'
        Get-File 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' $init
        # The GNU host toolchain ships its own linker, so no Visual Studio Build Tools are needed.
        & $init -y --no-modify-path --profile minimal --default-host x86_64-pc-windows-gnu --default-toolchain stable
        if ($LASTEXITCODE -ne 0) { throw 'rustup-init failed' }
    } else {
        Write-Step 'rustup already installed'
    }
    Write-Step ('Adding Rust targets: ' + ($RustTargets -join ', '))
    & $rustup target add @RustTargets
    if ($LASTEXITCODE -ne 0) { throw 'rustup target add failed' }
    & (Join-Path $env:CARGO_HOME 'bin\rustc.exe') --version
}

if ($Only -contains 'jdk')     { Install-Jdk }
if ($Only -contains 'flutter') { Install-Flutter }
if ($Only -contains 'android') { Install-AndroidSdk }
if ($Only -contains 'rust')    { Install-Rust }

Write-Step 'Toolchain ready. In a new shell, run:  . .\scripts\env.ps1'
