#!/bin/bash
# Claude Pet Installer (part of claude-hud)
# Usage: ./pet/install.sh        (install)
#        ./pet/install.sh remove  (uninstall)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="ClaudePet"
APP_BUNDLE="$HOME/Applications/$APP_NAME.app"
AGGREGATOR_PLIST_NAME="com.claude.pet-aggregator"
AGGREGATOR_PLIST="$HOME/Library/LaunchAgents/$AGGREGATOR_PLIST_NAME.plist"
NODE_PATH="$(which node 2>/dev/null || echo '/usr/local/bin/node')"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ "${1:-}" == "remove" ]]; then
  echo "Uninstalling Claude Pet..."
  killall "$APP_NAME" 2>/dev/null && echo "  Stopped $APP_NAME" || true
  if [[ -f "$AGGREGATOR_PLIST" ]]; then
    launchctl bootout "gui/$(id -u)/$AGGREGATOR_PLIST_NAME" 2>/dev/null || true
    rm -f "$AGGREGATOR_PLIST"
    echo "  Removed aggregator daemon"
  fi
  [[ -d "$APP_BUNDLE" ]] && rm -rf "$APP_BUNDLE" && echo "  Removed $APP_BUNDLE"
  rm -rf "$HOME/.claude/pet"
  echo -e "${GREEN}Claude Pet uninstalled.${NC}"
  exit 0
fi

echo "Installing Claude Pet..."

command -v node &>/dev/null || { echo -e "${RED}Error: Node.js required (brew install node)${NC}"; exit 1; }
command -v swiftc &>/dev/null || { echo -e "${RED}Error: Swift compiler required${NC}"; exit 1; }

# Build
echo "  Building Swift app..."
cd "$SCRIPT_DIR/ClaudePet"
mkdir -p build
swiftc -o "build/$APP_NAME" \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/PetType.swift \
  Sources/ProgressTracker.swift \
  Sources/NotificationManager.swift \
  Sources/PixelArtRenderer.swift \
  Sources/CollectionView.swift \
  Sources/StatusMenuController.swift \
  Sources/Sprites/CatSprites.swift \
  Sources/Sprites/HamsterSprites.swift \
  Sources/Sprites/ChickSprites.swift \
  Sources/Sprites/PenguinSprites.swift \
  Sources/Sprites/FoxSprites.swift \
  Sources/Sprites/RabbitSprites.swift \
  Sources/Sprites/GooseSprites.swift \
  Sources/Sprites/CapybaraSprites.swift \
  Sources/Sprites/SlothSprites.swift \
  Sources/Sprites/OwlSprites.swift \
  Sources/Sprites/DragonSprites.swift \
  Sources/Sprites/UnicornSprites.swift \
  -framework Cocoa \
  -framework ServiceManagement \
  -framework SwiftUI \
  -framework UserNotifications \
  -O 2>&1 || { echo -e "${RED}Build failed${NC}"; exit 1; }

# Install app bundle
mkdir -p "$HOME/Applications"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "build/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$SCRIPT_DIR/ClaudePet/Info.plist" "$APP_BUNDLE/Contents/"
if [[ -f "$SCRIPT_DIR/ClaudePet/AppIcon.icns" ]]; then
  cp "$SCRIPT_DIR/ClaudePet/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
echo -e "  ${GREEN}App → $APP_BUNDLE${NC}"

# Install aggregator daemon
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.claude/pet"
cat > "$AGGREGATOR_PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$AGGREGATOR_PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$NODE_PATH</string>
        <string>$SCRIPT_DIR/pet-aggregator.mjs</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/claude-pet-aggregator.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-pet-aggregator.err</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/$(id -u)/$AGGREGATOR_PLIST_NAME" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGGREGATOR_PLIST"
echo "  Aggregator daemon started"

open "$APP_BUNDLE"
echo ""
echo -e "${GREEN}Claude Pet installed!${NC}"
echo -e "${YELLOW}  The cat is now in your menu bar. Click it for details.${NC}"
