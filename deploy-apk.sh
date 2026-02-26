#!/usr/bin/env bash
set -euo pipefail

SERVER="${SERVER:-root@45.66.153.156}"
REMOTE_DIR="${REMOTE_DIR:-/www/wwwroot/facehrm/web/public/app}"
REMOTE_FILE="${REMOTE_FILE:-facehrm.apk}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Version info ──────────────────────────────────────────────────────────────
VERSION_NAME=$(grep '^version:' "$ROOT_DIR/mobile/pubspec.yaml" \
  | sed 's/version: //' | cut -d'+' -f1 | tr -d '[:space:]')
BUILD_NUM=$(git -C "$ROOT_DIR" rev-list --count HEAD)
echo "==> Version: v$VERSION_NAME (build $BUILD_NUM)"

# ── Build ─────────────────────────────────────────────────────────────────────
cd "$ROOT_DIR/mobile"
echo "==> Build APK release"
flutter build apk --release \
  --build-name="$VERSION_NAME" \
  --build-number="$BUILD_NUM"

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

# ── Deploy ────────────────────────────────────────────────────────────────────
STAMP="$(date +%Y%m%d-%H%M%S)"
REMOTE_PATH="$REMOTE_DIR/$REMOTE_FILE"
BACKUP_PATH="$REMOTE_DIR/${REMOTE_FILE}.bak-$STAMP"

echo "==> Backup existing APK (if any): $BACKUP_PATH"
ssh "$SERVER" "if [ -f '$REMOTE_PATH' ]; then cp '$REMOTE_PATH' '$BACKUP_PATH'; fi"

echo "==> Upload new APK"
scp "$APK_PATH" "$SERVER:$REMOTE_PATH"

echo "==> Write version.txt"
ssh "$SERVER" "echo 'v$VERSION_NAME (build $BUILD_NUM) — $(date +%Y-%m-%d)' > '$REMOTE_DIR/version.txt'"

echo "==> Verify remote file"
ssh "$SERVER" "ls -lh '$REMOTE_PATH' && cat '$REMOTE_DIR/version.txt'"

echo "✅ Deploy selesai: v$VERSION_NAME (build $BUILD_NUM)"
