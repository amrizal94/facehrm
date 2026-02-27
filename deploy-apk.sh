#!/usr/bin/env bash
set -euo pipefail

SERVER="${SERVER:-root@45.66.153.156}"
REMOTE_DIR="${REMOTE_DIR:-/www/wwwroot/facehrm/web/public/app}"
REMOTE_FILE="${REMOTE_FILE:-facehrm.apk}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
APK_URL="${APK_URL:-https://hrm.kreasikaryaarjuna.co.id/app/facehrm.apk}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Windows warning ────────────────────────────────────────────────────────────
if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "cygwin" ]]; then
  echo "⚠️  Windows detected — pkill tidak efektif di MSYS."
  echo "    Gunakan deploy-apk.ps1 (PowerShell) untuk kill java/dart dengan benar."
fi

# ── Version info ──────────────────────────────────────────────────────────────
VERSION_NAME=$(grep '^version:' "$ROOT_DIR/mobile/pubspec.yaml" \
  | sed 's/version: //' | cut -d'+' -f1 | tr -d '[:space:]')
BUILD_NUM=$(git -C "$ROOT_DIR" rev-list --count HEAD)
echo "==> Version: v$VERSION_NAME (build $BUILD_NUM)"

# ── Build ─────────────────────────────────────────────────────────────────────
cd "$ROOT_DIR/mobile"

echo "==> Stop Gradle daemon (best effort)"
if [[ -f "./android/gradlew" ]]; then
  (cd ./android && ./gradlew --stop >/dev/null 2>&1 || true)
fi

echo "==> Kill lock-prone processes (java/dart/adb)"
pkill -f "java" >/dev/null 2>&1 || true
pkill -f "dart" >/dev/null 2>&1 || true
pkill -f "adb"  >/dev/null 2>&1 || true

echo "==> Clean build artifacts"
rm -rf ./build ./android/.gradle

echo "==> Build APK release (arm64 — ~40% lebih kecil dari fat APK)"
flutter build apk --release \
  --target-platform android-arm64 \
  --build-name="$VERSION_NAME" \
  --build-number="$BUILD_NUM"

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

APK_SIZE=$(du -sh "$APK_PATH" | cut -f1)
echo "==> APK size: $APK_SIZE"

# ── Deploy ────────────────────────────────────────────────────────────────────
STAMP="$(date +%Y%m%d-%H%M%S)"
REMOTE_PATH="$REMOTE_DIR/$REMOTE_FILE"
BACKUP_PATH="$REMOTE_DIR/${REMOTE_FILE}.bak-$STAMP"

echo "==> Backup existing APK (if any): $BACKUP_PATH"
ssh -i "$SSH_KEY" "$SERVER" \
  "if [ -f '$REMOTE_PATH' ]; then cp '$REMOTE_PATH' '$BACKUP_PATH'; fi"

echo "==> Upload APK baru (gunakan Ctrl+C untuk batal)"
scp -i "$SSH_KEY" "$APK_PATH" "$SERVER:$REMOTE_PATH"

echo "==> Write version.txt"
TODAY="$(date +%Y-%m-%d)"
ssh -i "$SSH_KEY" "$SERVER" \
  "echo 'v$VERSION_NAME (build $BUILD_NUM) — $TODAY' > '$REMOTE_DIR/version.txt'"

echo "==> Cleanup backup lebih dari 7 hari"
ssh -i "$SSH_KEY" "$SERVER" \
  "find '$REMOTE_DIR' -name '*.bak-*' -mtime +7 -delete 2>/dev/null || true"

echo "==> Verifikasi file remote"
ssh -i "$SSH_KEY" "$SERVER" \
  "ls -lh '$REMOTE_PATH' && cat '$REMOTE_DIR/version.txt'"

echo "==> Verifikasi URL publik..."
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" -I --max-time 10 "$APK_URL")
if (( HTTP_CODE < 200 || HTTP_CODE >= 400 )); then
  echo "❌ APK tidak accessible di $APK_URL (HTTP $HTTP_CODE)" >&2
  exit 1
fi
echo "✅ APK accessible (HTTP $HTTP_CODE): $APK_URL"

echo "✅ Deploy selesai: v$VERSION_NAME (build $BUILD_NUM)"
