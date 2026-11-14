<#
.SYNOPSIS
  Copies the Firebase settings for app.bvm.messenger from google-services.json
  into .env (FIREBASE_APP_ID, FIREBASE_API_KEY, FIREBASE_MESSAGING_SENDER_ID,
  FIREBASE_PROJECT_ID).

.DESCRIPTION
  Download google-services.json from the Firebase console (Project settings >
  Your apps > Android app app.bvm.messenger), then run:

    powershell -ExecutionPolicy Bypass -File scripts\firebase-env.ps1 C:\Users\me\Downloads\google-services.json

  The JSON file itself is not needed by the build afterwards and should not be
  committed (it is git-ignored). Other lines in .env are kept.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $GoogleServicesJson,
    [string] $PackageName = 'app.bvm.messenger'
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repo '.env'

if (-not (Test-Path $GoogleServicesJson)) { throw "File not found: $GoogleServicesJson" }
$json = Get-Content -Raw $GoogleServicesJson | ConvertFrom-Json
$client = $json.client | Where-Object { $_.client_info.android_client_info.package_name -eq $PackageName } | Select-Object -First 1
if (-not $client) {
    throw "google-services.json has no Android app with package '$PackageName'. Add one in the Firebase console."
}

$values = [ordered]@{
    FIREBASE_APP_ID              = $client.client_info.mobilesdk_app_id
    FIREBASE_API_KEY             = ($client.api_key | Select-Object -First 1).current_key
    FIREBASE_MESSAGING_SENDER_ID = $json.project_info.project_number
    FIREBASE_PROJECT_ID          = $json.project_info.project_id
}
foreach ($k in $values.Keys) {
    if ([string]::IsNullOrWhiteSpace([string]$values[$k])) { throw "Could not read $k from $GoogleServicesJson" }
}

if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $repo '.env.example') $envFile
    Write-Warning '.env did not exist; created it from .env.example. Fill in SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY too.'
}
$lines = [System.Collections.Generic.List[string]]::new()
$lines.AddRange([string[]](Get-Content $envFile))
foreach ($k in $values.Keys) {
    $line = "$k=$($values[$k])"
    $index = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match "^\s*$k\s*=") { $index = $i; break } }
    if ($index -ge 0) { $lines[$index] = $line } else { $lines.Add($line) }
}
[System.IO.File]::WriteAllLines($envFile, $lines, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Updated $envFile with the Firebase settings of project $($values.FIREBASE_PROJECT_ID)."
Write-Host 'Rebuild the APK so they take effect: scripts\build-apk.ps1 -SkipTests'
