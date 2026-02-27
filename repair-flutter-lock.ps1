param(
  [switch]$Run,
  [switch]$PubGet,
  [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }
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
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\android\.gradle -ErrorAction SilentlyContinue

if ($PubGet) {
  Write-Host "==> flutter pub get"
  flutter pub get
}

if ($Run) {
  Write-Host "==> flutter run"
  if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    flutter run
  } else {
    flutter run -d $DeviceId
  }
} else {
  Write-Host "✅ Repair selesai. Jalankan: flutter run"
}
