# Dot-source this file to use the project-local toolchain in the current shell:
#   . .\scripts\env.ps1
#
# Everything lives under <repo>\.toolchain (git-ignored). Nothing is written to
# the system PATH or the registry, and no admin rights are needed. Deleting the
# .toolchain folder removes the whole toolchain again.

$script:RepoRoot = Split-Path -Parent $PSScriptRoot
$script:Toolchain = Join-Path $script:RepoRoot '.toolchain'

$env:BVM_TOOLCHAIN     = $script:Toolchain
$env:JAVA_HOME         = Join-Path $script:Toolchain 'jdk'
$env:ANDROID_HOME      = Join-Path $script:Toolchain 'android-sdk'
$env:ANDROID_SDK_ROOT  = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $script:Toolchain 'android-user-home'
$env:GRADLE_USER_HOME  = Join-Path $script:Toolchain 'gradle-home'
$env:PUB_CACHE         = Join-Path $script:Toolchain 'pub-cache'
$env:RUSTUP_HOME       = Join-Path $script:Toolchain 'rustup'
$env:CARGO_HOME        = Join-Path $script:Toolchain 'cargo'
# Keep Flutter/Dart from sending usage analytics from this machine.
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'

$prepend = @(
    (Join-Path $script:Toolchain 'flutter\bin'),
    (Join-Path $env:JAVA_HOME 'bin'),
    (Join-Path $env:ANDROID_HOME 'platform-tools'),
    (Join-Path $env:ANDROID_HOME 'cmdline-tools\latest\bin'),
    (Join-Path $env:CARGO_HOME 'bin')
)
$current = $env:PATH -split ';' | Where-Object { $_ -and ($prepend -notcontains $_) }
$env:PATH = (($prepend + $current) -join ';')
