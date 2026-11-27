#!/bin/bash
# oh-my-clawd HUD (Claude Code status line) installer
# Usage: ./install.sh         install / update
#        ./install.sh remove  uninstall (only removes a statusLine we installed)
#
# The HUD is copied to ~/.claude/pet/runtime — the same place the menu bar
# app installs it — so both setups point Claude Code at one path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"
RUNTIME_DIR="$HOME/.claude/pet/runtime"
STATUS_CMD="bash -c 'node \"\$HOME/.claude/pet/runtime/hud.mjs\"'"
BACKUP="$HOME/.claude/pet/statusline-backup.json"

command -v jq &>/dev/null || { echo "Error: jq is required. Install with: brew install jq"; exit 1; }

mkdir -p "$HOME/.claude"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# Refuse to touch a settings file we cannot parse.
jq empty "$SETTINGS" 2>/dev/null || { echo "Error: $SETTINGS is not valid JSON; not modifying it."; exit 1; }

is_ours() {
  local cmd
  cmd="$(jq -r '.statusLine.command // ""' "$SETTINGS")"
  # Last form: what the app's HUD toggle wrote up to v2.1.8.
  [[ "$cmd" == *".claude/pet/runtime/hud.mjs"* || "$cmd" == *"oh-my-clawd"* \
     || "$cmd" == "bash -c 'node \"\$HOME/.claude-hud/hud.mjs\"'" ]]
}

write_settings() {
  local tmp
  tmp="$(mktemp "$SETTINGS.XXXXXX")"
  jq "$@" "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
}

if [[ "${1:-}" == "remove" ]]; then
  if ! is_ours; then
    echo "statusLine is not oh-my-clawd's; leaving it alone."
    exit 0
  fi
  if [[ -f "$BACKUP" ]]; then
    write_settings --slurpfile b "$BACKUP" '.statusLine = $b[0].statusLine'
    rm -f "$BACKUP"
    echo "HUD removed; previous status line restored."
  else
    write_settings 'del(.statusLine)'
    echo "HUD removed from Claude Code settings."
  fi
  exit 0
fi

# Install runtime (atomic swap)
mkdir -p "$HOME/.claude/pet"
STAGING="$(mktemp -d "$HOME/.claude/pet/.runtime-XXXXXX")"
mkdir -p "$STAGING/lib"
cp "$SCRIPT_DIR/runtime/hud.mjs" "$SCRIPT_DIR/runtime/pet-aggregator.mjs" "$SCRIPT_DIR/runtime/unlocks.json" "$STAGING/"
cp "$SCRIPT_DIR/runtime/lib/"*.mjs "$STAGING/lib/"
echo "source-$(date +%s)" > "$STAGING/.version"
rm -rf "$RUNTIME_DIR.old"
[[ -d "$RUNTIME_DIR" ]] && mv "$RUNTIME_DIR" "$RUNTIME_DIR.old"
mv "$STAGING" "$RUNTIME_DIR"
rm -rf "$RUNTIME_DIR.old"

# Keep a third-party status line so 'remove' can restore it.
if [[ "$(jq -r '.statusLine // empty' "$SETTINGS")" != "" ]] && ! is_ours; then
  jq '{statusLine: .statusLine}' "$SETTINGS" > "$BACKUP"
fi

write_settings --arg cmd "$STATUS_CMD" '.statusLine = {"type": "command", "command": $cmd}'

echo "HUD installed successfully."
echo "  Runtime: $RUNTIME_DIR"
echo "  Restart Claude Code to see the status line."
