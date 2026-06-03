# Syncs Windows root CA certificates into a Gradle truststore (fixes PKIX / SSL errors on Windows).
# Run once:  powershell -ExecutionPolicy Bypass -File android/gradle/sync-truststore.ps1

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$trustStore = Join-Path $scriptDir 'windows-truststore.jks'
$storePass = 'changeit'

$jbrCandidates = @(
    $env:JAVA_HOME,
    'C:\Program Files\Android\Android Studio\jbr',
    'C:\Program Files\Java\jdk-21',
    'C:\Program Files\Eclipse Adoptium\jdk-21*'
)

$javaHome = $null
foreach ($candidate in $jbrCandidates) {
    if (-not $candidate) { continue }
    $resolved = $null
    if ($candidate -like '*`**') {
        $resolved = (Get-Item $candidate -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    } elseif (Test-Path $candidate) {
        $resolved = $candidate
    }
    if ($resolved -and (Test-Path (Join-Path $resolved 'bin\keytool.exe'))) {
        $javaHome = $resolved
        break
    }
}

if (-not $javaHome) {
    throw 'Could not find a JDK with keytool. Set JAVA_HOME or install Android Studio.'
}

$keytool = Join-Path $javaHome 'bin\keytool.exe'
$defaultCacerts = Join-Path $javaHome 'lib\security\cacerts'

Write-Host "Using JDK: $javaHome"
Write-Host "Creating truststore: $trustStore"

if (Test-Path $trustStore) {
    Remove-Item $trustStore -Force
}

Copy-Item $defaultCacerts $trustStore

function Import-CertToTrustStore {
    param(
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [string]$Alias
    )
    $tempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.cer')
    try {
        Export-Certificate -Cert $Certificate -FilePath $tempFile -Force | Out-Null
        & $keytool -delete -alias $Alias -keystore $trustStore -storepass $storePass 2>$null | Out-Null
        & $keytool -importcert -noprompt -trustcacerts `
            -alias $Alias -file $tempFile `
            -keystore $trustStore -storepass $storePass | Out-Null
        return $LASTEXITCODE -eq 0
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

$imported = 0
$skipped = 0
$certStores = @(
    'Cert:\LocalMachine\Root',
    'Cert:\CurrentUser\Root',
    'Cert:\LocalMachine\CA',
    'Cert:\CurrentUser\CA'
)

$seen = @{}
foreach ($store in $certStores) {
    if (-not (Test-Path $store)) { continue }
    foreach ($cert in Get-ChildItem -Path $store) {
        if ($seen.ContainsKey($cert.Thumbprint)) { continue }
        $seen[$cert.Thumbprint] = $true
        $alias = "cert-$($cert.Thumbprint)"
        if (Import-CertToTrustStore -Certificate $cert -Alias $alias) {
            $imported++
        } else {
            $skipped++
        }
    }
}

# Norton / antivirus HTTPS scanning roots are required on many Windows PCs.
$nortonRoots = Get-ChildItem Cert:\LocalMachine\Root, Cert:\CurrentUser\Root |
    Where-Object { $_.Subject -like '*Norton*' -or $_.Subject -like '*Web/Mail Shield*' }
foreach ($cert in $nortonRoots) {
    if (Import-CertToTrustStore -Certificate $cert -Alias 'norton-shield-root') {
        Write-Host "Imported Norton SSL inspection root: $($cert.Subject)"
        $imported++
    }
}

# Also add Norton root to Android Studio JBR cacerts (fixes Gradle without custom trustStore).
if ($nortonRoots) {
    $nortonCer = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.cer')
    try {
        Export-Certificate -Cert ($nortonRoots | Select-Object -First 1) -FilePath $nortonCer -Force | Out-Null
        & $keytool -delete -alias norton-shield-root -cacerts -storepass $storePass 2>$null | Out-Null
        & $keytool -importcert -noprompt -trustcacerts -alias norton-shield-root -file $nortonCer `
            -cacerts -storepass $storePass | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Imported Norton root into Android Studio JBR cacerts (-cacerts)."
        } else {
            Write-Warning "Could not update JBR cacerts. Run this script in an elevated terminal if needed."
        }
    } finally {
        Remove-Item $nortonCer -Force -ErrorAction SilentlyContinue
    }
}

# Copy to user .gradle folder so the path has no spaces (Gradle JVM args break on spaces).
$userTrustStore = Join-Path $env:USERPROFILE '.gradle\windows-truststore.jks'
$userGradleDir = Split-Path $userTrustStore -Parent
if (-not (Test-Path $userGradleDir)) {
    New-Item -ItemType Directory -Force -Path $userGradleDir | Out-Null
}
Copy-Item $trustStore $userTrustStore -Force

$trustStorePath = (Resolve-Path $userTrustStore).Path.Replace('\', '/')
$iniPath = Join-Path $scriptDir 'truststore.ini'
@"
javax.net.ssl.trustStore=$trustStorePath
javax.net.ssl.trustStorePassword=changeit
"@ | Set-Content -Path $iniPath -Encoding UTF8

Write-Host "Done. Imported $imported certs ($skipped skipped)."
Write-Host "Truststore: $trustStorePath"
Write-Host "Re-run: flutter run"
