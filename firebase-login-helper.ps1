# Firebase CLI login helper (Windows PowerShell)
# Run:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#        .\firebase-login-helper.ps1
#
# Fixes "Failed to make request to https://auth.firebase.tools/attest" when caused by
# TLS inspection, strict corporate proxies, or Node not trusting your AV root CA.

Write-Host "=== 1) Quick reachability check ===" -ForegroundColor Cyan
try {
    $null = Invoke-WebRequest -Uri "https://auth.firebase.tools/" -TimeoutSec 20 -UseBasicParsing
    Write-Host "auth.firebase.tools: reachable" -ForegroundColor Green
} catch {
    Write-Host "auth.firebase.tools: FAILED — $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try: mobile hotspot, turn VPN off/on, or set HTTPS_PROXY to your local proxy (e.g. Clash http://127.0.0.1:7890)." -ForegroundColor Yellow
}

Write-Host "`n=== 2) Optional: local HTTP(S) proxy (uncomment and edit if you use Clash / v2rayN) ===" -ForegroundColor Cyan
# $env:HTTP_PROXY  = "http://127.0.0.1:7890"
# $env:HTTPS_PROXY = "http://127.0.0.1:7890"

Write-Host "`n=== 3) Optional: trust extra CA (corporate MITM) — set path to your PEM file ===" -ForegroundColor Cyan
# $env:NODE_EXTRA_CA_CERTS = "C:\path\to\company-root.pem"

Write-Host "`n=== 4) LAST RESORT ONLY: relax TLS verification for this session ===" -ForegroundColor Yellow
Write-Host "    This weakens security; only use if antivirus HTTPS scanning breaks Node." -ForegroundColor Yellow
$useInsecureTls = Read-Host "    Type YES to set NODE_TLS_REJECT_UNAUTHORIZED=0 for this window (anything else skips)"
if ($useInsecureTls -eq "YES") {
    $env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
    Write-Host "    NODE_TLS_REJECT_UNAUTHORIZED=0 is set for this PowerShell session only." -ForegroundColor Yellow
}

# Quieter Node 22+ punycode deprecation noise from firebase-tools dependencies
$env:NODE_OPTIONS = "--no-deprecation"

Write-Host "`n=== 5) Firebase login (no localhost callback) ===" -ForegroundColor Cyan
firebase logout 2>$null
firebase login --no-localhost
