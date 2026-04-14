<p align="center">
  <img src="docs/assets/icon-preview.png" width="128" alt="oh-my-clawd Icon" />
</p>

<p align="center"><em>clawd has infiltrated my computer</em></p>

<p align="center">
  <img src="docs/assets/clawd/normal.gif" width="64" alt="Clawd Normal" />
  <img src="docs/assets/clawd/fashion/casual.gif" width="64" alt="Casual" />
  <img src="docs/assets/clawd/busy.gif" width="64" alt="Clawd Busy" />
  <img src="docs/assets/clawd/fashion/gentleman.gif" width="64" alt="Gentleman" />
  <img src="docs/assets/clawd/stressed.gif" width="64" alt="Clawd Stressed" />
  <img src="docs/assets/clawd/fashion/cowboy.gif" width="64" alt="Cowboy" />
  <img src="docs/assets/clawd/collab.gif" width="64" alt="Clawd Collab" />
  <img src="docs/assets/clawd/fashion/party.gif" width="64" alt="Party" />
  <img src="docs/assets/clawd/idle.gif" width="64" alt="Clawd Idle" />
</p>

<h1 align="center">oh-my-clawd</h1>

<p align="center">
  <strong>A status line + menu bar Tamagotchi for Claude Code</strong>
</p>

<p align="center">
  English · <a href="README_KO.md">한국어</a>
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
<img width="2058" height="670" alt="image" src="https://github.com/user-attachments/assets/3e5326dd-19ec-4985-b7d7-5a11c3fa8e04" />

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

A Tamagotchi-style 32x32 pixel art character that lives in your macOS menu bar.
**Clawd** (#D97757), the official Claude Code mascot, reacts to your Claude Code activity in real time.

> 8 States | 3 Activity Levels | 14 Accessories | Claude-powered Companion

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

### Accessory Collection (14 Accessories)

Unlock accessories for Clawd based on your Claude Code usage milestones.
Mix and match hats, glasses, and pants to create your own unique Clawd style!

#### Hats (5)

| Accessory | | Unlock Condition |
|-----------|--|-----------------|
| Cap | <img src="docs/assets/clawd/acc-cap.gif" width="32"> | 10 sessions |
| Party Hat | <img src="docs/assets/clawd/acc-partyhat.gif" width="32"> | 5 hours total usage |
| Santa Hat | <img src="docs/assets/clawd/acc-santahat.gif" width="32"> | 500K tokens used |
| Silk Hat | <img src="docs/assets/clawd/acc-silkhat.gif" width="32"> | 50 agent runs |
| Cowboy Hat | <img src="docs/assets/clawd/acc-cowboyhat.gif" width="32"> | 30 hours total usage |

#### Glasses (4)

| Accessory | | Unlock Condition |
|-----------|--|-----------------|
| Horn-rimmed | <img src="docs/assets/clawd/acc-hornrimmed.gif" width="32"> | 3+ concurrent sessions |
| Sunglasses | <img src="docs/assets/clawd/acc-sunglasses.gif" width="32"> | 10 rate limit hits |
| Round Glasses | <img src="docs/assets/clawd/acc-roundglasses.gif" width="32"> | 20 long sessions (45m+) |
| Star Glasses | <img src="docs/assets/clawd/acc-starglasses.gif" width="32"> | 10 hours on Opus |

#### Pants (5)

| Accessory | | Unlock Condition |
|-----------|--|-----------------|
| Jeans | <img src="docs/assets/clawd/acc-jeans.gif" width="32"> | 15 hours total usage |
| Shorts | <img src="docs/assets/clawd/acc-shorts.gif" width="32"> | 100 sessions |
| Slacks | <img src="docs/assets/clawd/acc-slacks.gif" width="32"> | 1M tokens used |
| Joggers | <img src="docs/assets/clawd/acc-joggers.gif" width="32"> | 100 agent runs |
| Cargo Pants | <img src="docs/assets/clawd/acc-cargo.gif" width="32"> | 50 hours total usage |

### Clawd Fashion Show

Mix and match hats + glasses + pants to create your own unique style.

<p align="center">
  <img src="docs/assets/clawd/fashion/casual.gif" width="64" alt="Casual" />
  <img src="docs/assets/clawd/fashion/gentleman.gif" width="64" alt="Gentleman" />
  <img src="docs/assets/clawd/fashion/cowboy.gif" width="64" alt="Cowboy" />
  <img src="docs/assets/clawd/fashion/party.gif" width="64" alt="Party" />
  <img src="docs/assets/clawd/fashion/santa.gif" width="64" alt="Santa" />
  <img src="docs/assets/clawd/fashion/nerd.gif" width="64" alt="Nerd" />
  <img src="docs/assets/clawd/fashion/sporty.gif" width="64" alt="Sporty" />
</p>

<p align="center">
  <sub>Casual · Gentleman · Cowboy · Party · Santa · Nerd · Sporty</sub>
</p>

> With **5 hats x 4 glasses x 5 pants = 100+** possible combinations (even more if you include no-accessory slots!)

## Clawd Companion

Clawd isn't just decoration — it's a lightweight daily assistant powered by Claude Haiku. Type naturally, and it parses time, saves memos, toggles reminders, or just chats back.

<p align="center">
  <img src="docs/assets/companion/popover-full.png" width="320" alt="Full companion popover" />
</p>

### Natural language memos + reminders

Ask in plain Korean or English. Clawd resolves relative times to concrete timestamps and fires a native notification when due.

<p align="center">
  <img src="docs/assets/companion/companion-chat.png" width="420" alt="Chat example" />
</p>

- `3시에 회의 있다고 알려줘` → memo with `dueAt: 15:00`, notification at 3pm
- `12시 40분에 밥 먹으라고` → memo with `dueAt: 12:40`
- `오늘 뭐 기억해둔 거 있어?` → lists open memos in the reply, creates nothing
- `스트레칭 알림 2시간마다` → flips the stretch reminder to 120m

### Scheduled reminders

Three built-in habit nudges with per-kind on/off and interval control:

<p align="center">
  <img src="docs/assets/companion/reminders-panel.png" width="320" alt="Reminders panel" />
</p>

| Reminder | Default | Fires when |
|----------|---------|-----------|
| 💧 Water | every 60m | a Claude session is active |
| 🧘 Stretch | every 90m | a Claude session is active |
| 📝 Diary | once a day at 22:00 | you've used Claude today |

Native macOS notifications, cooldowns per kind, and the intervals persist across restarts in `~/.claude/pet/clawd-memory.json`.

<p align="center">
  <img src="docs/assets/companion/notif-water.png" width="380" alt="Water reminder notification" />
  <img src="docs/assets/companion/notif-welcome.png" width="380" alt="Welcome notification" />
</p>

### How does it run?

- **Direct Anthropic API** via your Claude Code OAuth token (read from the macOS keychain). 0.5–2s round-trip, no API-plan billing — it counts against your Claude subscription rate limit just like `claude -p`.
- **Fallback**: spawns the local `claude` CLI when the keychain path fails.
- **AI off**: flip the `✨ AI` pill in the header to `✏️ 메모`. Your input saves as a raw memo instantly — no LLM call, no tokens.
- **Web questions** (weather, news, facts) work through Claude's built-in WebFetch / WebSearch. No extra config.

## Updates

**Auto in-app install.** A few seconds after launch Clawd pings GitHub. If a newer release is published, the popover footer shows `v<current> → v<new> 설치`. Click it — Clawd downloads the DMG, replaces itself, and relaunches. No browser required.

Click the `최신` label to manually re-check.

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

This project is licensed under the MIT License. However, the Clawd character design is copyrighted by [Anthropic](https://anthropic.com). This is a non-commercial fan project and cannot be used for commercial purposes — nor do we have any intention to. If any copyright issues arise, we will remove it immediately. Please have mercy.
