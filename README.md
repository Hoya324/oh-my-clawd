<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-HUD-00C4B4?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJMMyA3djEwbDkgNSA5LTVWN2wtOS01eiIgZmlsbD0id2hpdGUiLz48L3N2Zz4=&logoColor=white" alt="Claude HUD" />
</p>

<h1 align="center">Claude HUD</h1>

<p align="center">
  <strong>A lightweight status line for Claude Code</strong><br/>
  Rate limits &bull; Session time &bull; Context usage &bull; Tool calls &bull; Agents &bull; Model info
</p>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/install-one_liner-blue?style=flat-square" alt="Install" /></a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="macOS" />
  <img src="https://img.shields.io/badge/node-%3E%3D18-green?style=flat-square" alt="Node >= 18" />
  <img src="https://img.shields.io/github/license/Hoya324/claude-hud?style=flat-square" alt="License" />
</p>

---

## Preview

```
[HUD] | 5h:14%(3h51m) | wk:62%(3d5h) | session:29m | ctx:39% | 🔧53 | agents:2 | opus-4-6
```

| Segment | Description | Color Logic |
|---------|-------------|-------------|
| `5h:14%` | 5-hour rate limit usage | Green < 70% < Yellow < 90% < Red |
| `(3h51m)` | Time until 5h limit resets | Dim |
| `wk:62%` | Weekly rate limit usage | Same as above |
| `session:29m` | Current session duration | Green < 30m < Yellow < 60m < Red |
| `ctx:39%` | Context window usage | Green < 70% < Yellow < 85% < Red |
| `🔧53` | Total tool calls in session | — |
| `agents:2` | Currently running agents | Cyan |
| `opus-4-6` | Active model | Dim |

## Installation

### Quick Install

```bash
git clone https://github.com/Hoya324/claude-hud.git ~/.claude-hud
~/.claude-hud/install.sh
```

Then **restart Claude Code**.

### Manual Install

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c 'node \"$HOME/.claude-hud/hud.mjs\"'"
  }
}
```

## Uninstall

```bash
~/.claude-hud/install.sh remove
rm -rf ~/.claude-hud
```

## How It Works

```
┌─────────────────────────────────────────────────┐
│  Claude Code stdin (JSON)                       │
│  ├─ context_window.used_percentage              │
│  ├─ model.id                                    │
│  └─ transcript_path                             │
├─────────────────────────────────────────────────┤
│  Anthropic OAuth API                            │
│  └─ api.anthropic.com/api/oauth/usage           │
│     ├─ five_hour.utilization + resets_at         │
│     └─ seven_day.utilization + resets_at         │
├─────────────────────────────────────────────────┤
│  Transcript parsing                             │
│  ├─ Session start time                          │
│  ├─ Tool call count (tool_use blocks)           │
│  └─ Running agent count (Agent/Task blocks)     │
└─────────────────────────────────────────────────┘
          │
          ▼
   ┌──────────────┐
   │   [HUD] ...  │  ← rendered status line
   └──────────────┘
```

- **Rate limits** are fetched from the Anthropic OAuth API using your Claude Code credentials (keychain or file). Results are cached for 90 seconds to minimize API calls.
- **Session / tools / agents** are parsed from the Claude Code transcript file (JSONL).
- **Context window** percentage comes directly from Claude Code's stdin JSON.

## Requirements

- **macOS** (keychain credential reading uses `/usr/bin/security`)
- **Node.js >= 18**
- **jq** (for `install.sh` only — `brew install jq`)
- **Claude Code** with OAuth login (for rate limit data)

## License

MIT
