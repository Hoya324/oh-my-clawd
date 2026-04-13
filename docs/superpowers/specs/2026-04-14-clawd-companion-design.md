# oh-my-clawd v3 — Companion Mode Design

- **Date**: 2026-04-14
- **Scope**: (1) Remove body-color change feature. (2) Fix "Clawd stays asleep while a session is active" bug. (3) Add a Claude-powered companion: natural-language memos, reminders, and an extensible action layer for future tools (weather, news, etc.).

---

## 1. Remove Body-Color Feature

### Motivation
The 8-hour roulette + random recoloring adds UX surface area that the user no longer wants. Default terracotta (`#D97757`) is Clawd's brand color and should be fixed.

### Changes

**`pet/pet-aggregator.mjs`**
- Delete `checkColorTicket()` and its call in `tick()`.
- In `defaultProgress()` and `loadProgress()`, stop emitting `pantsColor`, `bodyColor`, `colorChangeTickets`, `lastColorTicketMinutes`. When reading legacy JSON, silently drop those fields.

**`pet/ClaudePet/Sources/PantsColorPalette.swift`**
- Delete the entire "Body Color" block: `BODY_DEFAULT_*` constants stay (spritesheets reference them), but `BodyColor` struct, `BodyColorPalette`, `applyColor` variant for body all go.
- `PantsColorPalette` keeps its single `defaultColor` (blue denim) — pants color is hard-coded, no user choice.

**`pet/ClaudePet/Sources/ProgressTracker.swift`**
- Remove `bodyColor`, `colorChangeTickets`, `lastColorTicketMinutes` from `ProgressData`.
- Delete `bodyColor()`, `colorChangeTickets()`, `consumeColorTicket()`.

**`pet/ClaudePet/Sources/AppDelegate.swift`**
- Remove `currentBodyColor` field and all `newBodyColor` tracking in `pollState()`.
- Delete `bodyColor` param from `reloadFramesAndAnimate()` / interaction / idle motion render paths.

**`pet/ClaudePet/Sources/PixelArtRenderer.swift`** (and callers)
- Drop the `bodyColor` parameter from `renderFrame(...)`. Sprites render with default body colors only.

**`pet/ClaudePet/Sources/CollectionView.swift`**
- `ClawdViewModel`: remove `bodyColorName`, `bodyColorDisplayKO`, `colorChangeTickets`, `pendingColor*`, `rollColor()`, `applyPendingColor()`, `cancelPendingColor()`.
- Header: remove the "Color (N) 🎲" button and pending-color preview block. Always show `activityLevel.displayName` on the right.
- `ClawdPreviewView`: drop `bodyColor` field.

### Acceptance
- Fresh launch: Clawd is terracotta.
- Existing `progress.json` with `bodyColor: "blue"` loads without error; user sees terracotta anyway.
- `grep -rE "bodyColor|colorChangeTicket|rollColor|pendingColor"` in `pet/` returns zero hits (except in migration code that strips the fields).

---

## 2. Fix "Session Active but Clawd Sleeping" Bug

### Root Cause
`pet-aggregator.mjs` only counts a session as active if `<cwd>/.claude/.hud/session-state.json` exists **and** its `timestamp` is within 15 minutes. That file is written exclusively by `hud.mjs`, the statusline hook. Therefore:

1. If the user disables HUD (the popover toggle sets `statusLine: null`), `session-state.json` is never written → every session is invisible to Clawd.
2. Even with HUD on, the file is only updated when the statusline refreshes. Between turns (long thinking, waiting for user input), timestamps go stale.
3. At session start, there's a window before the first statusline render where the file does not yet exist.

### Fix

In `pet/pet-aggregator.mjs` `tick()`, when `state` is missing or stale, **still include the session** using fallback values derived from the live `~/.claude/sessions/<pid>.json`:

```js
const rawState = await readJsonSafe(stateFile);
const stateFresh = rawState?.timestamp && (now - rawState.timestamp) <= IDLE_THRESHOLD_MS;
const effectiveState = stateFresh ? rawState : null;

if (effectiveState) {
  // Use state-file values as before
} else {
  // PID is alive (we already filtered on isPidAlive) — treat as active with defaults
  sessionDetails.push({
    pid: session.pid,
    project: basename(cwd),
    model: 'unknown',
    contextPercent: 0,
    toolCalls: 0,
    runningAgents: 0,
    sessionMinutes: Math.floor((now - (session.startedAt ?? now)) / 60_000),
  });
}
```

PID liveness (`isPidAlive`) is the source of truth; `session-state.json` becomes a richer signal layered on top.

### Visibility Enhancement

Make "Clawd sees your session" obvious in the popover so the user can verify detection:

- Header's `Sessions: N` line gains a second line listing project basenames (up to 3, comma-separated, overflow → `+M more`).
- `ClawdViewModel` exposes `activeProjectNames: [String]` computed from `data.sessions.map { $0.project }`.

### Acceptance
- Kill `hud.mjs` statusline (HUD off). Open a Claude Code session. Within 5s the menu-bar icon transitions idle → normal and the popover shows the project name.
- Re-enable HUD; behavior unchanged (state file just provides richer context/tool-call data).

---

## 3. Claude-Powered Companion

### Vision
Clawd becomes a lightweight companion living in the menu bar. The user types in a free-text field, Claude Haiku 4.5 (via the local `claude` CLI in `-p` mode) classifies intent, executes an action, and returns a short reply. Native macOS notifications fire for scheduled reminders (water, stretch, diary) and for due memos.

The same pipeline is the **extension point** for future capabilities: once the action DSL is in place, adding a "weather" tool is adding one action handler. Free-form questions ("오늘 날씨?", "최근 기사") rely on Claude's built-in `WebFetch` / `WebSearch` tools and come back as a `chitchat` reply — no new Swift code needed for them.

### 3.1 Data Model

**File**: `~/.claude/pet/clawd-memory.json` (atomic writes, same pattern as `progress.json`)

```json
{
  "version": 1,
  "reminders": {
    "water":   { "enabled": true,  "intervalMin": 60,  "lastAt": 0 },
    "stretch": { "enabled": true,  "intervalMin": 90,  "lastAt": 0 },
    "diary":   { "enabled": true,  "timeOfDay": "22:00", "lastDate": "" }
  },
  "memos": [
    {
      "id": "mem_<ulid-ish>",
      "text": "3시 회의",
      "createdAt": "2026-04-14T08:00:00Z",
      "dueAt":     "2026-04-14T06:00:00Z",
      "tags": ["work"],
      "done": false,
      "completedAt": null
    }
  ],
  "chatLog": [
    { "role": "user", "text": "3시 회의 기억해줘", "ts": 0 },
    { "role": "clawd", "text": "오후 3시 회의 저장했어요.", "ts": 0 }
  ]
}
```

`chatLog` is capped at last 20 entries (sliding window) — enough context for conversational continuity ("방금 저장한 거 취소해줘"), small enough not to bloat prompts.

### 3.2 Claude Bridge

**Helper**: `pet/ClaudePet/Sources/ClawdChat.swift`

Given a user utterance `text`:

1. Build a system prompt (below) including the current reminders config, the top ~10 open memos, and the last ~6 chat turns.
2. `Process` launches:
   ```
   claude -p --model claude-haiku-4-5 --output-format json --no-interactive
   ```
   stdin: `<system prompt>\n\nUser: <text>`
3. Read stdout, extract the final assistant message (Claude's `-p` JSON shape has `result` / `messages`).
4. Parse the assistant text as JSON (fenced or raw) into `ClawdResponse`.
5. Dispatch each action, append `reply` to `chatLog`, persist memory.

**Timeouts / failure**:
- 10-second hard timeout on the subprocess.
- If `claude` binary is missing, parsing fails, or timeout hits → reply falls back to `"Claude CLI를 찾지 못했어요. 프리셋 토글과 메모 리스트는 계속 쓸 수 있어요."` and the typed utterance is saved as a raw memo (so nothing is lost).
- Errors surface in the popover reply area with a subtle icon, not as blocking alerts.

### 3.3 Action DSL

Claude returns a single JSON object:

```jsonc
{
  "actions": [
    { "type": "add_memo",       "text": "3시 회의", "dueAt": "2026-04-14T06:00:00Z", "tags": ["work"] },
    { "type": "complete_memo",  "id": "mem_abc" },
    { "type": "delete_memo",    "id": "mem_abc" },
    { "type": "set_reminder",   "kind": "water", "enabled": true, "intervalMin": 90 },
    { "type": "set_reminder",   "kind": "diary", "enabled": false }
  ],
  "reply": "오후 3시 회의 저장했어요."
}
```

**Swift dispatcher** (`ClawdActionRunner.swift`) handles each `type`. Unknown `type` → ignored with a warning; the `reply` is still shown. This makes forward-compatible extension trivial: new action types can be added to the system prompt without breaking older builds, and old builds degrade gracefully.

For pure-conversation turns ("오늘 뭐 기억해둔 거 있어?"), Claude returns `actions: []` and the `reply` carries the answer — it already has the context of open memos injected in the system prompt.

### 3.4 System Prompt Sketch

```
You are Clawd, a pixel-art mascot living in the user's macOS menu bar.
Your job is to help the user remember things, nudge good habits,
and occasionally chat. Respond in the user's language (default 한국어).

You MUST reply with a single JSON object, no prose around it:
{
  "actions": Action[],   // zero or more side effects
  "reply":   string      // 1-2 sentences, warm & brief
}

Supported actions (extensible — ignore unknown fields):
- add_memo      { text, dueAt?: ISO8601, tags?: string[] }
- complete_memo { id }
- delete_memo   { id }
- set_reminder  { kind: "water"|"stretch"|"diary",
                  enabled?: bool,
                  intervalMin?: number,     // for water/stretch
                  timeOfDay?: "HH:mm" }     // for diary

When the user asks a general question (weather, news, facts), you may
use your web tools to fetch and answer directly in `reply` with
`actions: []`. Do not invent memos the user did not ask for.

Current state (for your reasoning, not to echo):
  Reminders: <json>
  Open memos (up to 10, newest first): <json>
  Recent chat (last 6): <json>

Time right now: <ISO timestamp + timezone>.
Resolve relative times ("3시", "내일 오전 10시", "30분 뒤") to absolute ISO8601.
If the user's time intent is ambiguous, leave `dueAt` null and ask in `reply`.
```

The `Time right now + timezone` injection is the key to correct `dueAt` resolution — Haiku has no wall-clock of its own.

### 3.5 Reminder Scheduler

**`pet/ClaudePet/Sources/ReminderScheduler.swift`**, owned by `AppDelegate`, fires every 60 seconds.

On each tick:
1. Read `clawd-memory.json` and `pet-state.json`.
2. **Water / Stretch**: only fire if `activeSessions > 0` **and** `now - lastAt >= intervalMin`. Update `lastAt` on fire.
3. **Diary**: if `enabled`, today's local date ≠ `lastDate`, and local time ≥ `timeOfDay`, and today had any session activity (any session with `sessionMinutes > 0` observed). Set `lastDate = today` on fire.
4. **Memos**: any memo with `done=false && dueAt != null && dueAt <= now`. Fire, mark `done=true`, `completedAt=now`.

**Fire = call `NotificationManager.sendClawdMessage(title, body, id)`**:

| Source | Title | Body |
|---|---|---|
| water | `Clawd` | `물 한 잔 마실 시간이에요 💧` |
| stretch | `Clawd` | `잠깐 스트레칭 해볼까요? 🧘` |
| diary | `Clawd` | `오늘 하루 일기 어떠세요? 📝` |
| memo | `Clawd 알림` | `<memo.text>` |

Cooldown: the existing `NotificationManager.lastNotificationTime` / `cooldownSeconds` dedup is preserved but scoped per-source (separate `lastSent[id]` map) so water doesn't suppress a memo.

### 3.6 Popover UI

New section inserted in `CollectionPopoverView` between `progressSection` and `footerSection`: **"Clawd"**.

```
┌─────────────────────────────────────┐
│  Clawd                              │
│  ┌─────────────────────────────┐    │
│  │ Clawd에게 말하기…           │ ⏎  │
│  └─────────────────────────────┘    │
│  💬 오후 3시 회의 저장했어요.       │  ← last reply, 1-2 lines
│                                     │
│  ▾ 리마인더                         │  ← collapsible
│    💧 물        [on]  60m ▾         │
│    🧘 스트레칭  [on]  90m ▾         │
│    📝 일기      [on]  22:00 ▾       │
│                                     │
│  📌 기억 중 (3)                     │
│    □ 3시 회의        오늘 15:00  ⋯  │
│    □ 장보기                     ⋯   │
│    □ 책 반납        금 18:00    ⋯   │
└─────────────────────────────────────┘
```

- **Input**: `TextField("Clawd에게 말하기…")`, submit on Return. While request is in flight, show a tiny spinner and disable the field.
- **Reply line**: fades in; truncates with tooltip showing full text. Subtle icon prefix indicates error vs success. If the response was purely conversational (no actions), the reply is the payload.
- **Reminders block**: default collapsed; expand reveals per-reminder toggle + interval/time drop-down. Toggling fires a local `set_reminder` directly (no LLM round-trip needed for a button click).
- **Memo list**: open memos only by default; tap a memo for actions menu (`완료` / `삭제` / `시간 변경` — last one just pre-fills the text field with `시간 변경: "<text>"`).
- Empty-state copy: `"아직 기억할 게 없어요. 위에 말해보세요."`

**Accessibility & UX polish**:
- Enter sends; Shift-Enter newline (rare but cheap).
- Cmd-. cancels an in-flight request.
- The text field autofocuses when the popover opens (opt-in via a small setting — default on).
- No confirmation dialogs. Destructive actions (`delete_memo`) are reversible via Undo chip next to the reply for 5 seconds.

### 3.7 Extensibility Hooks

The design anticipates future capabilities without paying their cost now:

- **New actions** (`fetch_weather`, `search_news`, `add_calendar_event`, etc.): add a handler in `ClawdActionRunner` and a one-line description to the system prompt. Old builds ignore unknown types, so the action layer is forward-compatible.
- **Web queries**: already work today through Claude's built-in `WebFetch` / `WebSearch` — Clawd inherits them for free in `-p` mode. No Swift code needed.
- **Custom tools via MCP**: if/when we want Clawd-specific tools (calendar, specific APIs), a small `clawd-mcp` server can be referenced via `--mcp-config`. Not in v3 scope, but the subprocess invocation is the natural place to add it.
- **Model swap**: the model id lives in a single constant; upgrading to Sonnet is a one-line change and can be a user setting later.

### 3.8 Acceptance

- Typing `"3시 회의 기억해줘"` adds a memo with `dueAt` set to today 15:00 local; reply confirms. At 15:00, a notification fires.
- Typing `"오늘 뭐 기억해둔 거 있어?"` returns a list in the reply, no action fired.
- Typing `"물 알림 2시간마다로 해줘"` updates `water.intervalMin` to 120; toggle UI reflects change next frame.
- Typing `"오늘 날씨 어때?"` — Claude uses its web tools and replies with a summary; no memo/reminder created.
- With `claude` CLI uninstalled, typing text saves a raw memo (timestamped `createdAt`, `dueAt=null`) and shows the fallback message.
- Scheduled notifications fire within one minute of their target time.

---

## 4. File Map

### Modified
- `pet/pet-aggregator.mjs` — remove color ticket logic; PID-alive fallback for session detection.
- `pet/ClaudePet/Sources/PantsColorPalette.swift` — delete body-color section.
- `pet/ClaudePet/Sources/ProgressTracker.swift` — drop color fields & getters.
- `pet/ClaudePet/Sources/AppDelegate.swift` — drop body-color state; own `ReminderScheduler`; wire `ClawdChat` to popover.
- `pet/ClaudePet/Sources/CollectionView.swift` — remove roulette UI; add Clawd section; expose `activeProjectNames`.
- `pet/ClaudePet/Sources/PixelArtRenderer.swift` — drop `bodyColor` param throughout.
- `pet/ClaudePet/Sources/NotificationManager.swift` — generalize to `sendClawdMessage(title, body, id)` with per-id cooldown.

### Added
- `pet/ClaudePet/Sources/ClawdMemory.swift` — load/save `clawd-memory.json`; memo/reminder mutation helpers.
- `pet/ClaudePet/Sources/ClawdChat.swift` — `claude -p` subprocess wrapper; JSON parse; returns `ClawdResponse`.
- `pet/ClaudePet/Sources/ClawdActionRunner.swift` — dispatch table for action types.
- `pet/ClaudePet/Sources/ReminderScheduler.swift` — 60s tick loop for reminders and due memos.
- `pet/ClaudePet/Sources/ClawdSection.swift` — the popover UI block (SwiftUI).

### Deleted
- None as whole files; the color-specific code is removed in place.

---

## 5. Out of Scope (v3)

- Editing a memo's text after creation (use delete + re-add).
- Recurring memos ("매주 월요일 9시") — reminders cover habits; memos are single-shot.
- Syncing memos across machines.
- Voice input.
- An MCP server for Clawd-specific tools (explicitly left as a hook, not built).
- Locale switching for reply language beyond what Claude infers from the user's message.

---

## 6. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| `claude -p` latency spikes (>5s on cold API) | Async UI with spinner + 10s timeout + fallback. |
| Claude returns malformed JSON | Strict parse; on failure, fall back to raw memo and log the raw reply in `chatLog`. |
| User privacy — memos contain personal info | File is local only (`~/.claude/pet/`). No network transmission beyond the `claude` CLI call, which the user already trusts. |
| Notification spam if scheduler clock drifts | Per-source `lastAt` comparison + 30-minute minimum floor on intervals. |
| PID-alive fallback misattributes project when `cwd` is unusual | `project` is just a display string; if `cwd` missing, fall back to `"session #<pid>"`. |
