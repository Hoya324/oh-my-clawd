#!/bin/bash
# oh-my-clawd menu bar app — build from source and install
# Usage: ./pet/install.sh                 install / update
#        ./pet/install.sh remove          uninstall (keeps memos and progress)
#        ./pet/install.sh remove --purge  uninstall and delete all Clawd data

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="OhMyClawd"
APP_BUNDLE="$HOME/Applications/$APP_NAME.app"
AGENT_LABEL="com.claude.clawd-aggregator"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
PET_DIR="$HOME/.claude/pet"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ "${1:-}" == "remove" ]]; then
  echo "Uninstalling oh-my-clawd..."
  killall "$APP_NAME" 2>/dev/null && echo "  Stopped $APP_NAME" || true
  if [[ -f "$AGENT_PLIST" ]]; then
    launchctl bootout "gui/$(id -u)/$AGENT_LABEL" 2>/dev/null || true
    rm -f "$AGENT_PLIST"
    echo "  Removed aggregator daemon"
  fi
  [[ -d "$APP_BUNDLE" ]] && rm -rf "$APP_BUNDLE" && echo "  Removed $APP_BUNDLE"
  rm -rf "$PET_DIR/runtime"
  if [[ "${2:-}" == "--purge" ]]; then
    rm -rf "$PET_DIR"
    echo "  Deleted all Clawd data ($PET_DIR)"
  else
    echo -e "  ${YELLOW}Kept memos and progress in $PET_DIR (use 'remove --purge' to delete)${NC}"
  fi
  echo -e "${GREEN}oh-my-clawd uninstalled.${NC}"
  exit 0
fi

echo "Installing oh-my-clawd..."
command -v swiftc &>/dev/null || { echo -e "${RED}Error: Swift compiler required (xcode-select --install)${NC}"; exit 1; }
command -v node &>/dev/null || echo -e "${YELLOW}  Node.js not found: usage still works, Claude Code session tracking needs Node (brew install node)${NC}"

BUILD_DIR="$SCRIPT_DIR/ClaudePet/build"
"$REPO_ROOT/scripts/build-app.sh" --out "$BUILD_DIR" --native || { echo -e "${RED}Build failed${NC}"; exit 1; }

killall "$APP_NAME" 2>/dev/null || true
mkdir -p "$HOME/Applications"
rm -rf "$APP_BUNDLE"
ditto "$BUILD_DIR/$APP_NAME.app" "$APP_BUNDLE"
# Ad-hoc sign so macOS keeps notification / keychain permissions stable.
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
echo -e "  ${GREEN}App → $APP_BUNDLE${NC}"

# The app installs the runtime scripts and the aggregator LaunchAgent on
# launch (~/.claude/pet/runtime, $AGENT_LABEL).
open "$APP_BUNDLE"
echo ""
echo -e "${GREEN}oh-my-clawd installed!${NC}"
echo -e "${YELLOW}  Clawd is now in your menu bar. Click it for details.${NC}"
