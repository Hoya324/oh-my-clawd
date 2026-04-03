#!/bin/bash
# Build a distributable DMG for Claude Pet
# Usage: ./scripts/build-dmg.sh
#
# Outputs: build/ClaudeHud.dmg

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PET_DIR="$REPO_ROOT/pet/ClaudePet"
BUILD_DIR="$REPO_ROOT/build"
APP_NAME="ClaudePet"
INFO_PLIST="$PET_DIR/Info.plist"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# 1. Read version from Info.plist
# ---------------------------------------------------------------------------
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
echo "Building $APP_NAME v$VERSION …"

# ---------------------------------------------------------------------------
# 2. Pre-flight checks
# ---------------------------------------------------------------------------
command -v swiftc &>/dev/null || { echo -e "${RED}Error: Swift compiler not found${NC}"; exit 1; }

# ---------------------------------------------------------------------------
# 3. Compile the Swift app
# ---------------------------------------------------------------------------
echo "  Compiling Swift sources …"
mkdir -p "$BUILD_DIR"

swiftc -o "$BUILD_DIR/$APP_NAME" \
  "$PET_DIR/Sources/main.swift" \
  "$PET_DIR/Sources/AppDelegate.swift" \
  "$PET_DIR/Sources/PetStateReader.swift" \
  "$PET_DIR/Sources/PetStateMachine.swift" \
  "$PET_DIR/Sources/PetType.swift" \
  "$PET_DIR/Sources/ProgressTracker.swift" \
  "$PET_DIR/Sources/NotificationManager.swift" \
  "$PET_DIR/Sources/PixelArtRenderer.swift" \
  "$PET_DIR/Sources/CollectionView.swift" \
  "$PET_DIR/Sources/StatusMenuController.swift" \
  "$PET_DIR/Sources/UpdateChecker.swift" \
  "$PET_DIR/Sources/Sprites/CatSprites.swift" \
  "$PET_DIR/Sources/Sprites/HamsterSprites.swift" \
  "$PET_DIR/Sources/Sprites/ChickSprites.swift" \
  "$PET_DIR/Sources/Sprites/PenguinSprites.swift" \
  "$PET_DIR/Sources/Sprites/FoxSprites.swift" \
  "$PET_DIR/Sources/Sprites/RabbitSprites.swift" \
  "$PET_DIR/Sources/Sprites/GooseSprites.swift" \
  "$PET_DIR/Sources/Sprites/CapybaraSprites.swift" \
  "$PET_DIR/Sources/Sprites/SlothSprites.swift" \
  "$PET_DIR/Sources/Sprites/OwlSprites.swift" \
  "$PET_DIR/Sources/Sprites/DragonSprites.swift" \
  "$PET_DIR/Sources/Sprites/UnicornSprites.swift" \
  -framework Cocoa \
  -framework ServiceManagement \
  -framework SwiftUI \
  -framework UserNotifications \
  -O 2>&1 || { echo -e "${RED}Build failed${NC}"; exit 1; }

echo -e "  ${GREEN}Binary built${NC}"

# ---------------------------------------------------------------------------
# 4. Assemble the .app bundle
# ---------------------------------------------------------------------------
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME"   "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST"             "$APP_BUNDLE/Contents/"

if [[ -f "$PET_DIR/AppIcon.icns" ]]; then
  cp "$PET_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo -e "  ${GREEN}App bundle created${NC}"

# ---------------------------------------------------------------------------
# 5. Create the DMG
# ---------------------------------------------------------------------------
DMG_NAME="ClaudeHud.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DMG_STAGING="$BUILD_DIR/dmg-staging"

# Clean up any previous staging / DMG
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

echo "  Creating DMG …"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" \
  > /dev/null 2>&1

rm -rf "$DMG_STAGING"

echo ""
echo -e "${GREEN}DMG ready:${NC} $DMG_PATH"
echo -e "  Version : $VERSION"
echo -e "  Size    : $(du -h "$DMG_PATH" | cut -f1)"
