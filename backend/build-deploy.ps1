# ─────────────────────────────────────────────────────────────────
# FaceHRM Backend — Package untuk Deployment
# Jalankan: powershell -ExecutionPolicy Bypass -File build-deploy.ps1
# ─────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$backendDir = $PSScriptRoot
$zipPath    = "$backendDir\facehrm-backend-deploy.zip"

# Folder/file yang TIDAK diikutkan
$excludes = @(
    "vendor",
    ".env",
    ".env.*.template",
    "storage\logs",
    "storage\framework\cache",
    "storage\framework\sessions",
    "storage\framework\views",
    "public\storage",       # symlink dari storage:link, dibuat ulang di server
    ".git",
    "node_modules",
    "*.zip",
    "build-deploy.ps1"
)

Write-Host "=== FaceHRM Backend Package ===" -ForegroundColor Cyan

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# Buat temp folder
$tmpDir = "$env:TEMP\facehrm-backend-$(Get-Random)"
New-Item -ItemType Directory -Path $tmpDir | Out-Null

Write-Host "Copying files (exclude: vendor, .env, logs, cache)..." -ForegroundColor Yellow

# Copy semua file kecuali yang di-exclude
Get-ChildItem -Path $backendDir -Recurse -Attributes !ReparsePoint | ForEach-Object {
    $relativePath = $_.FullName.Substring($backendDir.Length + 1)

    # Cek apakah path diexclude
    $skip = $false
    foreach ($exc in $excludes) {
        if ($relativePath -like "$exc*" -or $relativePath -like "*\$exc*") {
            $skip = $true; break
        }
    }
    if ($skip) { return }

    $dest = Join-Path $tmpDir $relativePath
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    } else {
        $destParent = Split-Path $dest -Parent
        if (-not (Test-Path $destParent)) {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }
        Copy-Item $_.FullName -Destination $dest -Force
    }
}

# Pastikan storage/logs dan framework dirs ada (kosong)
@(
    "storage\logs",
    "storage\framework\cache\data",
    "storage\framework\sessions",
    "storage\framework\views",
    "storage\app\public"
) | ForEach-Object {
    $d = Join-Path $tmpDir $_
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Zip
Write-Host "Creating zip..." -ForegroundColor Yellow
Compress-Archive -Path "$tmpDir\*" -DestinationPath $zipPath

# Cleanup temp
Remove-Item $tmpDir -Recurse -Force

$sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
Write-Host "`n=== SELESAI ===" -ForegroundColor Green
Write-Host "File: $zipPath" -ForegroundColor Green
Write-Host "Size: $sizeMB MB" -ForegroundColor Green
Write-Host "`nLangkah selanjutnya:" -ForegroundColor Cyan
Write-Host "  1. Upload facehrm-backend-deploy.zip ke /www/wwwroot/facehrm-api/ di aaPanel" -ForegroundColor White
Write-Host "  2. Extract di sana" -ForegroundColor White
Write-Host "  3. Jalankan laravel-setup.sh di server" -ForegroundColor White
