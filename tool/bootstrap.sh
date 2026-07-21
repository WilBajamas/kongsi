#!/usr/bin/env bash
# One-time setup for a fresh clone. Captures the machine-level steps that
# otherwise aren't obvious (the native-assets flag especially), so a from-zero
# checkout runs without tribal knowledge.
#
# Prerequisite: FVM (https://fvm.app). Then, from anywhere:  ./tool/bootstrap.sh

set -euo pipefail

# Run from the repo root regardless of where the script was invoked.
cd "$(dirname "$0")/.."

if ! command -v fvm >/dev/null 2>&1; then
  echo "FVM not found. Install it first: https://fvm.app" >&2
  exit 1
fi

echo "==> Installing the pinned Flutter SDK (.fvmrc)..."
fvm install

# sqlite3 5.x ships its native lib via a Dart build hook, which Flutter has off
# by default — without this the APK silently lacks libsqlite3.so and crashes.
echo "==> Enabling native assets (required by sqlite3)..."
fvm flutter config --enable-native-assets

echo "==> Fetching packages..."
fvm flutter pub get

# config/*.json is gitignored (holds real credentials), so a clone has none.
# Seed dev from the committed example; never clobber an existing real one.
if [ -f config/dev.json ]; then
  echo "==> config/dev.json exists — leaving it untouched."
else
  echo "==> Creating config/dev.json from the example (placeholder backend)..."
  cp config/dev.example.json config/dev.json
fi

echo ""
echo "Setup complete. Run the app on a connected device with:"
echo "  fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json"
