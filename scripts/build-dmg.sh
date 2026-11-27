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
# 2-4. Compile (universal) and assemble the .app bundle
# ---------------------------------------------------------------------------
"$REPO_ROOT/scripts/build-app.sh" --out "$BUILD_DIR" || { echo -e "${RED}Build failed${NC}"; exit 1; }
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
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
