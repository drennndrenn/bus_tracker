# Runs Flutter on Android with the project SSL truststore (Norton/antivirus HTTPS scanning).
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$userTrustStore = Join-Path $env:USERPROFILE '.gradle\windows-truststore.jks'
if (-not (Test-Path $userTrustStore)) {
    Write-Host 'Creating SSL truststore (first run only)...'
    & powershell -ExecutionPolicy Bypass -File (Join-Path $root 'android\gradle\sync-truststore.ps1')
}

$path = (Resolve-Path $userTrustStore).Path.Replace('\', '/')
$env:GRADLE_OPTS = "-Djavax.net.ssl.trustStore=$path -Djavax.net.ssl.trustStorePassword=changeit"
$env:JAVA_TOOL_OPTIONS = $env:GRADLE_OPTS

Push-Location $root
try {
    flutter @args
} finally {
    Pop-Location
}
