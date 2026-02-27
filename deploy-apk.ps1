param(
  [string]$Server    = "root@45.66.153.156",
  [string]$RemoteDir = "/www/wwwroot/facehrm/web/public/app",
  [string]$RemoteFile = "facehrm.apk",
  [string]$SshKey    = "$env:USERPROFILE\.ssh\id_ed25519",
  [string]$ApkUrl    = "https://hrm.kreasikaryaarjuna.co.id/app/facehrm.apk"
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }

# -- Version info --------------------------------------------------------------
$pubspecLine = Get-Content (Join-Path $root "mobile\pubspec.yaml") |
               Where-Object { $_ -match "^version:" } |
               Select-Object -First 1
$versionName = ($pubspecLine -replace "version:\s*", "").Trim().Split("+")[0]
$buildNum    = (git -C $root rev-list --count HEAD).Trim()
Write-Host "==> Version: v$versionName (build $buildNum)"

# -- Build ---------------------------------------------------------------------
Set-Location (Join-Path $root "mobile")

Write-Host "==> Stop Gradle daemon (best effort)"
Set-Location .\android
if (Test-Path .\gradlew.bat) {
  .\gradlew.bat --stop 2>$null | Out-Null
} elseif (Test-Path .\gradlew) {
  .\gradlew --stop 2>$null | Out-Null
}
Set-Location ..

Write-Host "==> Kill lock-prone processes (java/dart/adb)"
taskkill /F /IM java.exe 2>$null | Out-Null
taskkill /F /IM dart.exe 2>$null | Out-Null
taskkill /F /IM adb.exe  2>$null | Out-Null

Write-Host "==> Clean build artifacts"
Remove-Item -Recurse -Force .\build          -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\android\.gradle -ErrorAction SilentlyContinue

Write-Host "==> Build APK release (arm64 - ~40% lebih kecil dari fat APK)"
flutter build apk --release `
  --target-platform android-arm64 `
  --build-name="$versionName" `
  --build-number="$buildNum"

$localApk = ".\build\app\outputs\flutter-apk\app-release.apk"
if (!(Test-Path $localApk)) {
  throw "APK tidak ditemukan: $localApk"
}

$apkSize = (Get-Item $localApk).Length / 1MB
Write-Host ("==> APK size: {0:N1} MB" -f $apkSize)

# -- Deploy --------------------------------------------------------------------
$stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$remotePath = "$RemoteDir/$RemoteFile"
$backupPath = "$RemoteDir/$RemoteFile.bak-$stamp"

Write-Host "==> Backup file lama (jika ada): $backupPath"
ssh -i $SshKey $Server "if [ -f '$remotePath' ]; then cp '$remotePath' '$backupPath'; fi"

Write-Host "==> Upload APK baru (gunakan Ctrl+C untuk batal)"
scp -i $SshKey $localApk "${Server}:${remotePath}"

Write-Host "==> Write version.txt"
$today       = Get-Date -Format "yyyy-MM-dd"
$versionText = "v$versionName (build $buildNum) - $today"
ssh -i $SshKey $Server "echo '$versionText' > '$RemoteDir/version.txt'"

Write-Host "==> Cleanup backup lebih dari 7 hari"
ssh -i $SshKey $Server "find '$RemoteDir' -name '*.bak-*' -mtime +7 -delete 2>/dev/null; true"

Write-Host "==> Verifikasi file remote"
ssh -i $SshKey $Server "ls -lh '$remotePath' && cat '$RemoteDir/version.txt'"

Write-Host "==> Verifikasi URL publik..."
try {
  $response = Invoke-WebRequest -Uri $ApkUrl -Method Head `
                                -TimeoutSec 10 -UseBasicParsing
  $httpCode = $response.StatusCode
} catch {
  $httpCode = 0
}
if ($httpCode -lt 200 -or $httpCode -ge 400) {
  throw "APK tidak accessible di $ApkUrl (HTTP $httpCode)"
}
Write-Host "OK APK accessible (HTTP $httpCode): $ApkUrl"

Write-Host "DONE Deploy selesai: v$versionName (build $buildNum)"
