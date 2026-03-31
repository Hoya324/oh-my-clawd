#!/bin/bash
# Claude HUD Installer
# Usage: ./install.sh        (install)
#        ./install.sh remove  (uninstall)

set -euo pipefail

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HUD_PATH="$SCRIPT_DIR/hud.mjs"

if [[ ! -f "$HUD_PATH" ]]; then
  echo "Error: hud.mjs not found at $HUD_PATH"
  exit 1
fi

# Ensure jq is available
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

# Ensure settings file exists
if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
  mkdir -p "$HOME/.claude"
  echo '{}' > "$CLAUDE_SETTINGS"
fi

if [[ "${1:-}" == "remove" ]]; then
  # Remove statusLine from settings
  jq 'del(.statusLine)' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
  echo "HUD removed from Claude Code settings."
  exit 0
fi

# Build statusLine command
STATUS_CMD="bash -c 'node \"$HUD_PATH\"'"

# Update settings.json — add or overwrite statusLine
jq --arg cmd "$STATUS_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"

echo "HUD installed successfully."
echo "  Path: $HUD_PATH"
echo "  Restart Claude Code to see the status line."
