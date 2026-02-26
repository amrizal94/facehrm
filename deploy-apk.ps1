param(
  [string]$Server    = "root@45.66.153.156",
  [string]$RemoteDir = "/www/wwwroot/facehrm/web/public/app",
  [string]$RemoteFile = "facehrm.apk"
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }

# ── Version info ──────────────────────────────────────────────────────────────
$pubspecLine = Get-Content (Join-Path $root "mobile\pubspec.yaml") |
               Where-Object { $_ -match "^version:" } |
               Select-Object -First 1
$versionName = ($pubspecLine -replace "version:\s*", "").Trim().Split("+")[0]
$buildNum    = (git -C $root rev-list --count HEAD).Trim()
Write-Host "==> Version: v$versionName (build $buildNum)"

# ── Build ─────────────────────────────────────────────────────────────────────
Set-Location (Join-Path $root "mobile")

Write-Host "==> Kill java.exe locks & clean build"
taskkill /F /IM java.exe 2>$null | Out-Null
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue

Write-Host "==> Build APK release"
flutter build apk --release `
  --build-name="$versionName" `
  --build-number="$buildNum"

$localApk = ".\build\app\outputs\flutter-apk\app-release.apk"
if (!(Test-Path $localApk)) {
  throw "APK tidak ditemukan: $localApk"
}

# ── Deploy ────────────────────────────────────────────────────────────────────
$stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$remotePath = "$RemoteDir/$RemoteFile"
$backupPath = "$RemoteDir/$RemoteFile.bak-$stamp"

Write-Host "==> Backup file lama (jika ada): $backupPath"
ssh $Server "if [ -f '$remotePath' ]; then cp '$remotePath' '$backupPath'; fi"

Write-Host "==> Upload APK baru"
scp $localApk "${Server}:${remotePath}"

Write-Host "==> Write version.txt"
$today       = Get-Date -Format "yyyy-MM-dd"
$versionText = "v$versionName (build $buildNum) — $today"
ssh $Server "echo '$versionText' > '$RemoteDir/version.txt'"

Write-Host "==> Verifikasi file remote"
ssh $Server "ls -lh '$remotePath' && cat '$RemoteDir/version.txt'"

Write-Host "✅ Deploy selesai: v$versionName (build $buildNum)"
