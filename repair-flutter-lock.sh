#!/usr/bin/env bash
set -euo pipefail

RUN="${RUN:-0}"
PUBGET="${PUBGET:-0}"
DEVICE_ID="${DEVICE_ID:-}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

if [[ "$PUBGET" == "1" ]]; then
  echo "==> flutter pub get"
  flutter pub get
fi

if [[ "$RUN" == "1" ]]; then
  echo "==> flutter run"
  if [[ -n "$DEVICE_ID" ]]; then
    flutter run -d "$DEVICE_ID"
  else
    flutter run
  fi
else
  echo "✅ Repair selesai. Jalankan: flutter run"
fi
