#!/bin/bash
# Build a distributable DMG for Claude Pet
# Usage: ./scripts/build-dmg.sh
#
# Outputs: build/OhMyClawd.dmg

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PET_DIR="$REPO_ROOT/pet/ClaudePet"
BUILD_DIR="$REPO_ROOT/build"
APP_NAME="OhMyClawd"
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
  "$PET_DIR/Sources/AccessoryType.swift" \
  "$PET_DIR/Sources/ProgressTracker.swift" \
  "$PET_DIR/Sources/ClawdMemory.swift" \
  "$PET_DIR/Sources/ReminderScheduler.swift" \
  "$PET_DIR/Sources/ClawdChat.swift" \
  "$PET_DIR/Sources/ClawdActionRunner.swift" \
  "$PET_DIR/Sources/ClawdSection.swift" \
  "$PET_DIR/Sources/NotificationManager.swift" \
  "$PET_DIR/Sources/PixelArtRenderer.swift" \
  "$PET_DIR/Sources/CollectionView.swift" \
  "$PET_DIR/Sources/StatusMenuController.swift" \
  "$PET_DIR/Sources/UpdateChecker.swift" \
  "$PET_DIR/Sources/Sprites/ClaudeSprites.swift" \
  "$PET_DIR/Sources/Sprites/ClaudeEffects.swift" \
  "$PET_DIR/Sources/Sprites/AccessorySprites.swift" \
  "$PET_DIR/Sources/PantsColorPalette.swift" \
  "$PET_DIR/Sources/Sprites/PantsSprites.swift" \
  "$PET_DIR/Sources/Sprites/InteractionSprites.swift" \
  "$PET_DIR/Sources/Sprites/IdleMotionSprites.swift" \
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
# 5. Code sign
# ---------------------------------------------------------------------------
SIGN_IDENTITY="Developer ID Application: GYEONGHO NA (H7825NYH4G)"
TEAM_ID="H7825NYH4G"

echo "  Signing app bundle …"
codesign --force --deep --options runtime \
  --sign "$SIGN_IDENTITY" \
  "$APP_BUNDLE" 2>&1 || { echo -e "${RED}Code signing failed${NC}"; exit 1; }

echo -e "  ${GREEN}Code signed${NC}"

# ---------------------------------------------------------------------------
# 6. Create the DMG
# ---------------------------------------------------------------------------
DMG_NAME="OhMyClawd.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

rm -f "$DMG_PATH"

echo "  Creating DMG …"
if command -v create-dmg &>/dev/null; then
  # create-dmg produces a proper .DS_Store so Finder shows both
  # OhMyClawd.app and the Applications drop-link at known positions.
  create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 560 360 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 140 180 \
    --app-drop-link 420 180 \
    --hide-extension "$APP_NAME.app" \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_BUNDLE" \
    > /dev/null 2>&1 || { echo -e "${RED}DMG creation failed${NC}"; exit 1; }
else
  # Fallback: plain hdiutil (no custom layout — Finder may position
  # icons unpredictably). Prefer installing create-dmg (brew install create-dmg).
  DMG_STAGING="$BUILD_DIR/dmg-staging"
  rm -rf "$DMG_STAGING"
  mkdir -p "$DMG_STAGING"
  cp -R "$APP_BUNDLE" "$DMG_STAGING/"
  ln -s /Applications "$DMG_STAGING/Applications"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" \
    > /dev/null 2>&1
  rm -rf "$DMG_STAGING"
fi

# Sign the DMG too
codesign --force --sign "$SIGN_IDENTITY" "$DMG_PATH" 2>&1

# ---------------------------------------------------------------------------
# 7. Notarize
# ---------------------------------------------------------------------------
echo "  Submitting for notarization …"
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "notarytool-profile" \
  --wait 2>&1 || {
    echo -e "${YELLOW}Notarization failed. To set up credentials run:${NC}"
    echo "  xcrun notarytool store-credentials notarytool-profile --apple-id YOUR_APPLE_ID --team-id $TEAM_ID"
    echo -e "${YELLOW}Then re-run this script.${NC}"
    echo ""
    echo -e "${GREEN}DMG ready (unsigned):${NC} $DMG_PATH"
    exit 0
  }

# Staple the notarization ticket
xcrun stapler staple "$DMG_PATH" 2>&1

echo ""
echo -e "${GREEN}DMG ready (signed + notarized):${NC} $DMG_PATH"
echo -e "  Version : $VERSION"
echo -e "  Size    : $(du -h "$DMG_PATH" | cut -f1)"
