#!/usr/bin/env pwsh
# One-time setup for a fresh clone. Captures the machine-level steps that
# otherwise aren't obvious (the native-assets flag especially), so a from-zero
# checkout runs without tribal knowledge.
#
# Prerequisite: FVM (https://fvm.app). Then, from anywhere:  ./tool/bootstrap.ps1

$ErrorActionPreference = "Stop"

# Run from the repo root regardless of where the script was invoked.
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Get-Command fvm -ErrorAction SilentlyContinue)) {
    Write-Error "FVM not found. Install it first: https://fvm.app"
    exit 1
}

Write-Host "==> Installing the pinned Flutter SDK (.fvmrc)..."
fvm install

# sqlite3 5.x ships its native lib via a Dart build hook, which Flutter has off
# by default — without this the APK silently lacks libsqlite3.so and crashes.
Write-Host "==> Enabling native assets (required by sqlite3)..."
fvm flutter config --enable-native-assets

Write-Host "==> Fetching packages..."
fvm flutter pub get

# config/*.json is gitignored (holds real credentials), so a clone has none.
# Seed dev from the committed example; never clobber an existing real one.
$devConfig = "config/dev.json"
if (Test-Path $devConfig) {
    Write-Host "==> $devConfig exists — leaving it untouched."
} else {
    Write-Host "==> Creating $devConfig from the example (placeholder backend)..."
    Copy-Item "config/dev.example.json" $devConfig
}

Write-Host ""
Write-Host "Setup complete. Run the app on a connected device with:"
Write-Host "  fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json"
