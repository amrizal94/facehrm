# ─────────────────────────────────────────────────────────────────
# FaceHRM Web — Build & Package untuk Deployment
# Jalankan: powershell -ExecutionPolicy Bypass -File build-deploy.ps1
# ─────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$webDir = $PSScriptRoot
$outDir = "$webDir\deploy-package"

Write-Host "=== FaceHRM Web Build & Package ===" -ForegroundColor Cyan

# 1. Build
Write-Host "`n[1/4] Building Next.js (standalone)..." -ForegroundColor Yellow
Set-Location $webDir
npm run build
if ($LASTEXITCODE -ne 0) { Write-Error "Build failed!"; exit 1 }

# 2. Bersihkan folder output
Write-Host "`n[2/4] Preparing deploy-package folder..." -ForegroundColor Yellow
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Path $outDir | Out-Null

# 3. Copy standalone output
Write-Host "`n[3/4] Copying files..." -ForegroundColor Yellow

# Main standalone server
Copy-Item "$webDir\.next\standalone\*" $outDir -Recurse -Force

# Static assets (wajib dicopy ke dalam standalone)
$staticDest = "$outDir\.next\static"
if (-not (Test-Path $staticDest)) { New-Item -ItemType Directory -Path $staticDest | Out-Null }
Copy-Item "$webDir\.next\static\*" $staticDest -Recurse -Force

# Public folder
$publicDest = "$outDir\public"
if (-not (Test-Path $publicDest)) { New-Item -ItemType Directory -Path $publicDest | Out-Null }
if (Test-Path "$webDir\public") {
    Copy-Item "$webDir\public\*" $publicDest -Recurse -Force
}

# PM2 ecosystem config
Copy-Item "$webDir\ecosystem.config.js" $outDir -Force

# 4. Zip
Write-Host "`n[4/4] Creating zip archive..." -ForegroundColor Yellow
$zipPath = "$webDir\facehrm-web-deploy.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path "$outDir\*" -DestinationPath $zipPath

Write-Host "`n=== SELESAI ===" -ForegroundColor Green
Write-Host "File siap upload: $zipPath" -ForegroundColor Green
Write-Host "Ukuran: $([math]::Round((Get-Item $zipPath).Length / 1MB, 1)) MB" -ForegroundColor Green
