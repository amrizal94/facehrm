#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# FaceHRM — Update Script
# Jalankan di server setiap kali ada update dari GitHub:
#   bash /www/wwwroot/facehrm/deploy/update.sh
# ─────────────────────────────────────────────────────────────────

set -e
APP_DIR="/www/wwwroot/facehrm"
PHP="/www/server/php/83/bin/php"

cd "$APP_DIR"

echo "=== FaceHRM Update ==="

# ── 1. Pull latest code ───────────────────────────────────────────
echo "[1/4] Git pull..."
git pull origin main

# ── 2. Backend update ────────────────────────────────────────────
echo "[2/4] Backend update..."
cd "$APP_DIR/backend"
COMPOSER2="/usr/local/bin/composer2"
[ ! -f "$COMPOSER2" ] && COMPOSER2="/www/server/composer/composer.phar"
$PHP $COMPOSER2 install --no-dev --optimize-autoloader --no-interaction
$PHP artisan migrate --force
$PHP artisan config:cache
$PHP artisan route:cache
$PHP artisan view:cache
/etc/init.d/php-fpm-83 reload

# ── 3. Frontend update ───────────────────────────────────────────
echo "[3/4] Frontend build..."
cd "$APP_DIR/web"
npm install --omit=dev
npm run build

# ── 4. Restart PM2 ───────────────────────────────────────────────
echo "[4/4] Restart PM2..."
pm2 restart facehrm-web

echo ""
echo "✅ Update selesai!"
pm2 status facehrm-web
