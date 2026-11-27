#!/bin/bash
# Build OhMyClawd.app (unsigned). Single source of truth for the compile
# step, used by pet/install.sh, scripts/build-dmg.sh and CI.
#
# Usage: scripts/build-app.sh [--out DIR] [--native]
#   --out DIR   output directory (default: <repo>/build)
#   --native    build only for this Mac's architecture (faster, for local
#               installs). Default is a universal arm64 + x86_64 binary.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PET_DIR="$REPO_ROOT/pet/ClaudePet"
APP_NAME="OhMyClawd"
MIN_MACOS="13.0"
OUT_DIR="$REPO_ROOT/build"
NATIVE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT_DIR="$2"; shift 2 ;;
    --native) NATIVE=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

command -v swiftc >/dev/null || { echo "Error: Swift compiler not found (install Xcode Command Line Tools)" >&2; exit 1; }

# Every Swift file under Sources/ — no hand-maintained list to drift.
SOURCES=()
while IFS= read -r f; do SOURCES+=("$f"); done < <(find "$PET_DIR/Sources" -name '*.swift' | LC_ALL=C sort)

if [[ $NATIVE -eq 1 ]]; then
  ARCHS=("$(uname -m)")
else
  ARCHS=(arm64 x86_64)
fi

mkdir -p "$OUT_DIR"
BINARIES=()
for arch in "${ARCHS[@]}"; do
  echo "  Compiling ($arch) …"
  out="$OUT_DIR/$APP_NAME-$arch"
  swiftc -o "$out" \
    -target "$arch-apple-macos$MIN_MACOS" \
    "${SOURCES[@]}" \
    -framework Cocoa \
    -framework ServiceManagement \
    -framework SwiftUI \
    -framework UserNotifications \
    -O
  BINARIES+=("$out")
done

APP_BUNDLE="$OUT_DIR/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

if [[ ${#BINARIES[@]} -gt 1 ]]; then
  lipo -create "${BINARIES[@]}" -output "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
else
  cp "${BINARIES[0]}" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
fi
rm -f "${BINARIES[@]}"

cp "$PET_DIR/Info.plist" "$APP_BUNDLE/Contents/"
[[ -f "$PET_DIR/AppIcon.icns" ]] && cp "$PET_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Bundle the Node runtime (HUD + aggregator). The app installs it to
# ~/.claude/pet/runtime and manages the aggregator LaunchAgent itself.
RUNTIME_DST="$APP_BUNDLE/Contents/Resources/runtime"
mkdir -p "$RUNTIME_DST/lib"
cp "$REPO_ROOT/runtime/hud.mjs" "$REPO_ROOT/runtime/pet-aggregator.mjs" "$REPO_ROOT/runtime/unlocks.json" "$RUNTIME_DST/"
cp "$REPO_ROOT/runtime/lib/"*.mjs "$RUNTIME_DST/lib/"

echo "  Built $APP_BUNDLE (${ARCHS[*]})"
