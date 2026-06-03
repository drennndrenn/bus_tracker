# Builds debug APK and saves it as Bus-Tracking.apk (Flutter default name is app-debug.apk).
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

flutter build apk --debug

$apkDir = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk"
$defaultApk = Join-Path $apkDir "app-debug.apk"
$namedApk = Join-Path $apkDir "Bus-Tracking.apk"

if (-not (Test-Path $defaultApk)) {
    throw "Expected APK not found: $defaultApk"
}

if (Test-Path $namedApk) {
    Remove-Item $namedApk -Force
}

Rename-Item -Path $defaultApk -NewName "Bus-Tracking.apk"

Write-Host ""
Write-Host "Built: $namedApk" -ForegroundColor Green
