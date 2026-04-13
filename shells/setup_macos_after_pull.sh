#!/usr/bin/env bash
#
# -----------------------------------------------------------------------------
# BijecBet macOS post-pull setup script
# -----------------------------------------------------------------------------
# Run this script after pulling fresh changes from GitHub (especially on a new
# machine or after switching branches) to rehydrate all macOS build pieces that
# are easy to get out of sync in this project.
#
# Why this exists:
# - This app uses Flutter + CocoaPods + Rust (flutter_rust_bridge).
# - We now rely on Rust linkage/runtime behavior that is sensitive to stale
#   build artifacts and missing local dependencies.
# - A normal "flutter run -d macos" can fail if Pods, Flutter ephemeral files,
#   or Rust build outputs are not aligned.
#
# What this script does:
# 1. Validates required tools are installed (`flutter`, `cargo`, `rustup`, `pod`).
# 2. Clears stale Flutter/macOS build outputs that can cause locked DB/linker issues.
# 3. Restores Dart/Flutter dependencies (`flutter pub get`).
# 4. Reinstalls CocoaPods dependencies under `macos/` (`pod install`).
# 5. Ensures Rust macOS targets exist for both Apple Silicon and Intel.
# 6. Builds the Rust bridge library in release mode so linkage artifacts exist.
#
# Notes:
# - The Xcode project and runtime loader are configured to resolve the Rust lib
#   through project build settings and process-linked symbols on macOS.
# - This script is safe to run repeatedly.
# - After this completes, run: `flutter run -d macos`
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: required command not found: ${cmd}" >&2
    exit 1
  fi
}

echo "==> Validating toolchain"
require_cmd flutter
require_cmd cargo
require_cmd rustup
require_cmd pod

cd "${REPO_ROOT}"

echo "==> Cleaning Flutter/macOS build state"
rm -f build/macos/Build/Intermediates.noindex/XCBuildData/build.db
flutter clean

echo "==> Restoring Flutter packages"
flutter pub get

echo "==> Installing macOS pods"
(
  cd macos
  pod install
)

echo "==> Ensuring Rust macOS targets"
rustup target add aarch64-apple-darwin
rustup target add x86_64-apple-darwin

echo "==> Building Rust bridge library (release)"
cargo build --manifest-path rust/Cargo.toml --release

echo "==> Done. Next step: flutter run -d macos"
