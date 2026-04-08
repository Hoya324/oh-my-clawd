<p align="center">
  <img src="docs/assets/icon-preview.png" width="128" alt="oh-my-clawd Icon" />
</p>

<p align="center"><em>clawd has infiltrated my computer</em></p>

<p align="center">
  <img src="docs/assets/clawd/normal.gif" width="64" alt="Clawd Normal" />
  <img src="docs/assets/clawd/busy.gif" width="64" alt="Clawd Busy" />
  <img src="docs/assets/clawd/stressed.gif" width="64" alt="Clawd Stressed" />
  <img src="docs/assets/clawd/collab.gif" width="64" alt="Clawd Collab" />
  <img src="docs/assets/clawd/idle.gif" width="64" alt="Clawd Idle" />
</p>

<h1 align="center">oh-my-clawd</h1>

<p align="center">
  <strong>A status line + menu bar Clawd for Claude Code</strong>
</p>

<p align="center">
  English · <a href="README.md">한국어</a>
</p>

<p align="center">
  <a href="https://github.com/Hoya324/oh-my-clawd/releases/latest/download/OhMyClawd.dmg"><img src="https://img.shields.io/badge/DMG-download-blue?style=flat-square" alt="DMG Download" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/node-%3E%3D18-green?style=flat-square" alt="Node >= 18" />
  <img src="https://img.shields.io/github/license/Hoya324/oh-my-clawd?style=flat-square" alt="License" />
</p>

---

## Preview

```
[HUD] | 5h:14%(3h51m) | wk:62%(3d5h) | session:29m | ctx:39% | 53 | agents:2 | opus-4-6
```

## Installation

### DMG Download (Recommended)

Download the `.dmg` file from the [latest release page](https://github.com/Hoya324/oh-my-clawd/releases/latest/download/OhMyClawd.dmg) and install.

### Manual Install

```bash
git clone https://github.com/Hoya324/oh-my-clawd.git ~/.oh-my-clawd
~/.oh-my-clawd/install.sh
```

Then **restart Claude Code**.

## HUD Status Line

| Segment | Description | Color Logic |
|---------|-------------|-------------|
| `5h:14%` | 5-hour rate limit usage | Green < 70% < Yellow < 90% < Red |
| `(3h51m)` | Time until 5h limit resets | Dim |
| `wk:62%` | Weekly rate limit usage | Same as above |
| `session:29m` | Current session duration | Green < 30m < Yellow < 60m < Red |
| `ctx:39%` | Context window usage | Green < 70% < Yellow < 85% < Red |
| `53` | Total tool calls in session | -- |
| `agents:2` | Currently running agents | Cyan |
| `opus-4-6` | Active model | Dim |

## Clawd — Menu Bar Companion

A Tamagotchi-style pixel art character that lives in your macOS menu bar. Clawd (#D97757), the official Claude Code mascot, reacts to your Claude Code activity. Collect 9 accessories and watch Clawd's activity level change.

### Clawd States

| State | | Description | Trigger |
|-------|-|-------------|---------|
| Sleeping | <img src="docs/assets/clawd/idle.gif" width="32"> | Eyes closed, Zzz | No active sessions |
| Waking up | <img src="docs/assets/clawd/wakeup.gif" width="32"> | Jumps awake | idle→active transition |
| Walking | <img src="docs/assets/clawd/normal.gif" width="32"> | Walking happily | Default active state |
| Working hard | <img src="docs/assets/clawd/busy.gif" width="32"> | Fast movement | 50+ tool calls |
| Bloated | <img src="docs/assets/clawd/bloated.gif" width="32"> | Puffed up, slow | Context >= 70% |
| Stressed | <img src="docs/assets/clawd/stressed.gif" width="32"> | Shaking, alert | Rate limit >= 80% |
| Tired | <img src="docs/assets/clawd/tired.gif" width="32"> | Droopy eyes | Session >= 45 min |
| Collab | <img src="docs/assets/clawd/collab.gif" width="32"> | Multi-agent anim | 2+ agents |

### Activity Levels

Clawd's activity level changes based on concurrent agent count.

| Level | Condition | Description |
|-------|-----------|-------------|
| Normal | 0-1 agents | Default appearance |
| Glowing | 2-3 agents | Glowing effect |
| Supercharged! | 4+ agents | Maximum energy |

### Accessory Collection (9 Accessories)

Unlock accessories for Clawd based on your Claude Code usage milestones.

**Hats (5)**

| Accessory | Unlock Condition |
|-----------|-----------------|
| Cap | 10 sessions |
| Party Hat | 5 hours total usage |
| Santa Hat | 500K tokens used |
| Silk Hat | 50 agent runs |
| Cowboy Hat | 30 hours total usage |

**Glasses (4)**

| Accessory | Unlock Condition |
|-----------|-----------------|
| Horn-rimmed | 3+ concurrent sessions |
| Sunglasses | 10 rate limit hits |
| Round Glasses | 20 long sessions (45m+) |
| Star Glasses | 10 hours on Opus |

## Updates

Click the **Check for Updates** button in the menu bar popover to check for the latest version on GitHub Releases. If a new version is available, it will open the download page.

## Requirements

- **macOS 13.0+**
- **Node.js >= 18**
- **Claude Code** with OAuth login (for rate limit data)

## Uninstall

```bash
~/.oh-my-clawd/install.sh remove
rm -rf ~/.oh-my-clawd
```

If you installed the oh-my-clawd app separately:

```bash
~/.oh-my-clawd/pet/install.sh remove
```

## License

MIT

---

## License

This project is licensed under the MIT License. However, the Clawd character design is copyrighted by [Anthropic](https://anthropic.com). This is a non-commercial fan project and cannot be used for commercial purposes — nor do we have any intention to. If any copyright issues arise, we will remove it immediately. Please have mercy.
