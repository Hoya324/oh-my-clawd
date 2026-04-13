# oh-my-clawd v3 Companion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the body-color roulette, fix the "session active but Clawd sleeping" bug, and add a Claude-Haiku-powered companion with natural-language memos, scheduled reminders, and an extensible action DSL.

**Architecture:** The macOS menu-bar Swift app (`ClaudePet`) already polls `~/.claude/pet/pet-state.json` written by a Node daemon (`pet-aggregator.mjs`). We extend this with (1) a new memory store `~/.claude/pet/clawd-memory.json`, (2) a 60-second reminder scheduler inside the Swift app, (3) a `ClawdChat` subprocess wrapper that invokes `claude -p --model claude-haiku-4-5 --output-format json` and parses a `{actions, reply}` JSON envelope, (4) a `ClawdActionRunner` dispatch table that is forward-compatible with unknown action types. Color-related code is deleted in place. The aggregator gains a PID-liveness fallback so Clawd can detect sessions even when the HUD statusline is off.

**Tech Stack:** Swift 5 / SwiftUI / AppKit (macOS 13+), Node 18+ (daemon), `claude` CLI 1.x, `UserNotifications` framework, `swiftc` direct compile (no Xcode project).

**Spec:** `docs/superpowers/specs/2026-04-14-clawd-companion-design.md`

**Build command used as verification throughout:**
```bash
cd pet && bash install.sh
```
This compiles with `swiftc`, installs to `~/Applications/OhMyClawd.app`, and restarts the app. If compilation fails, the script exits non-zero. SourceKit errors in editors are expected and NOT failures; only `swiftc` command-line errors count.

---

## Phase A — Remove Body-Color Feature

Pure deletion. Safest to land first because it shrinks the code we will otherwise have to navigate.

### Task A1: Strip body-color block from `PantsColorPalette.swift`

**Files:**
- Modify: `pet/ClaudePet/Sources/PantsColorPalette.swift`

- [ ] **Step 1: Replace the file with pants-only content**

Open `pet/ClaudePet/Sources/PantsColorPalette.swift` and replace its entire contents with:

```swift
import Foundation

// ============================================================================
// MARK: - Pants Sentinel Colors (used in pants sprite templates)
// ============================================================================
let PANTS_MAIN_SENTINEL   = UInt32(0xFFFE0001)
let PANTS_DARK_SENTINEL   = UInt32(0xFFFE0002)
let PANTS_DETAIL_SENTINEL = UInt32(0xFFFE0003)

// ============================================================================
// MARK: - Pants Color (fixed denim blue)
// ============================================================================

struct PantsColor {
    let main: UInt32
    let dark: UInt32
    let detail: UInt32
}

struct PantsColorPalette {
    static let defaultColor = PantsColor(
        main: 0xFF2196F3, dark: 0xFF1565C0, detail: 0xFFE0E0E0
    )

    /// Replace sentinel pixels in a sprite grid with pants color values.
    static func applyColor(_ color: PantsColor, to grid: [[UInt32?]]) -> [[UInt32?]] {
        grid.map { row in
            row.map { pixel in
                guard let px = pixel else { return nil }
                switch px {
                case PANTS_MAIN_SENTINEL:   return color.main
                case PANTS_DARK_SENTINEL:   return color.dark
                case PANTS_DETAIL_SENTINEL: return color.detail
                default:                    return px
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify `BodyColor` references are isolated to files we will edit**

Run:
```bash
grep -rn 'BodyColor\|BODY_DEFAULT\|bodyColor\|colorChangeTicket\|rollColor\|pendingColor' pet/ClaudePet/Sources/
```
Expected: matches only in `ProgressTracker.swift`, `AppDelegate.swift`, `CollectionView.swift`, `PixelArtRenderer.swift`. No hits in sprite files. If any sprite file is listed, stop and investigate.

- [ ] **Step 3: Don't build yet — the project is temporarily broken**

This file compiles standalone, but callers in other files still reference `BodyColor`. We'll fix them next tasks, then build once.

### Task A2: Remove `bodyColor` param from `PixelArtRenderer`

**Files:**
- Modify: `pet/ClaudePet/Sources/PixelArtRenderer.swift`

- [ ] **Step 1: Find the renderFrame signature**

Run:
```bash
grep -n 'func renderFrame\|bodyColor' pet/ClaudePet/Sources/PixelArtRenderer.swift
```
Record every line where `bodyColor` appears in this file.

- [ ] **Step 2: Delete every `bodyColor` reference**

For each occurrence:
- In the `renderFrame` signature: remove the `bodyColor: BodyColor? = nil,` parameter.
- Inside the function body: remove any `BodyColorPalette.applyColor(...)` call that uses `bodyColor`; leave the un-recolored grid as-is (sprites already paint with `BODY_DEFAULT_*` sentinels which we are no longer recoloring).
- Remove any `BodyColor` type references.

If `BODY_DEFAULT_MAIN` / `BODY_DEFAULT_SHADOW` / `BODY_DEFAULT_HIGHLIGHT` constants are referenced in `PixelArtRenderer.swift`, leave them — they're probably defined in the sprite files. If they were defined only in `PantsColorPalette.swift` (now deleted), add them as file-private constants at the top of the sprite file that uses them (likely `ClaudeSprites.swift`).

- [ ] **Step 3: Verify no stray references**

```bash
grep -n 'bodyColor\|BodyColor' pet/ClaudePet/Sources/PixelArtRenderer.swift
```
Expected: no output.

### Task A3: Remove color fields from `ProgressTracker`

**Files:**
- Modify: `pet/ClaudePet/Sources/ProgressTracker.swift`

- [ ] **Step 1: Strip color fields from `ProgressData`**

Replace the `ProgressData` struct with:

```swift
struct ProgressData: Codable {
    var version: Int
    var stats: ProgressStats
    var unlockedAccessories: [String]
    var selectedHat: String?
    var selectedGlasses: String?
    var selectedPants: String?
    var unlockedAt: [String: String]
}
```

Legacy JSON files include `bodyColor`, `colorChangeTickets`, `lastColorTicketMinutes`, `pantsColor`. With default Codable decoding these unknown keys are silently ignored — we do not need migration code.

- [ ] **Step 2: Delete color methods**

Remove these methods from the file entirely:
- `func bodyColor() -> BodyColor`
- `func colorChangeTickets() -> Int`
- `func consumeColorTicket() -> BodyColor?`

Also remove the `// MARK: - Body color` section header comment.

- [ ] **Step 3: Verify**

```bash
grep -n 'bodyColor\|colorChangeTicket\|consumeColorTicket' pet/ClaudePet/Sources/ProgressTracker.swift
```
Expected: no output.

### Task A4: Remove color state from `AppDelegate`

**Files:**
- Modify: `pet/ClaudePet/Sources/AppDelegate.swift`

- [ ] **Step 1: Delete `currentBodyColor` and related tracking**

Remove these lines:
- `private var currentBodyColor: BodyColor = BodyColorPalette.defaultColor`
- `currentBodyColor = progressTracker.bodyColor()` (in `applicationDidFinishLaunching`)
- `let newBodyColor = progressTracker.bodyColor()` and `let oldBodyColor = currentBodyColor` (in `pollState`)
- `currentBodyColor = newBodyColor` (in `pollState`)
- `|| newBodyColor.name != oldBodyColor.name` (from the `needsReload` computation)
- The `bodyColor: currentBodyColor,` argument in every `PixelArtRenderer.renderFrame` / `PixelArtRenderer.renderComposited` call site in this file.

- [ ] **Step 2: Verify**

```bash
grep -n 'bodyColor\|BodyColor' pet/ClaudePet/Sources/AppDelegate.swift
```
Expected: no output.

### Task A5: Remove color UI from `CollectionView.swift`

**Files:**
- Modify: `pet/ClaudePet/Sources/CollectionView.swift`

- [ ] **Step 1: Strip color fields from `ClawdViewModel`**

Delete these `@Published` declarations:
```swift
@Published var bodyColorName: String = "terracotta"
@Published var bodyColorDisplayKO: String = "테라코타"
@Published var colorChangeTickets: Int = 0
@Published var pendingColorName: String? = nil
@Published var pendingColorDisplayKO: String? = nil
@Published var pendingColorMain: UInt32 = 0
```

Delete these methods entirely:
- `func rollColor()`
- `func applyPendingColor()`
- `func cancelPendingColor()`

In `refresh(stateData:)`, delete:
```swift
let currentBodyColor = progressTracker.bodyColor()
bodyColorName = currentBodyColor.name
bodyColorDisplayKO = currentBodyColor.displayNameKO
colorChangeTickets = progressTracker.colorChangeTickets()
```

- [ ] **Step 2: Replace the header's color block with plain activity text**

In `headerSection`, replace the `if viewModel.pendingColorName != nil { ... } else if viewModel.colorChangeTickets > 0 { ... } else { ... }` block with just:

```swift
Text(viewModel.activityLevel.displayName)
    .font(.system(size: 11, weight: .medium))
    .foregroundColor(viewModel.activityLevel == .supercharged ? .yellow : .secondary)
```

- [ ] **Step 3: Strip `bodyColor` from `ClawdPreviewView`**

Change the struct to:
```swift
struct ClawdPreviewView: NSViewRepresentable {
    let hat: AccessoryType?
    let glasses: AccessoryType?
    var pants: AccessoryType? = nil

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = rendered()
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = rendered()
    }

    private func rendered() -> NSImage {
        PixelArtRenderer.renderFrame(
            state: .normal, activity: .normal,
            hat: hat, glasses: glasses, pants: pants,
            frameIndex: 0
        )
    }
}
```

(Adjust the `renderFrame` arguments to match the signature you produced in Task A2.)

- [ ] **Step 4: Verify**

```bash
grep -n 'bodyColor\|BodyColor\|colorChangeTicket\|rollColor\|pendingColor' pet/ClaudePet/Sources/CollectionView.swift
```
Expected: no output.

### Task A6: Remove color ticket logic from the aggregator

**Files:**
- Modify: `pet/pet-aggregator.mjs`

- [ ] **Step 1: Delete `checkColorTicket` and its call**

Remove the entire function `function checkColorTicket(progress) { ... }` and the single line `checkColorTicket(progress);` inside `tick()`.

- [ ] **Step 2: Simplify `defaultProgress()` and `loadProgress()` field defaults**

In `defaultProgress()`, remove these fields from the returned object:
```js
    selectedPants: null,
    pantsColor: 'blue',
    colorChangeTickets: 0,
    lastColorTicketMinutes: 0,
```
Keep `selectedPants: null` — pants accessory selection stays. Only remove `pantsColor`, `colorChangeTickets`, `lastColorTicketMinutes`.

In `loadProgress()`, remove the forward-compat lines:
```js
  if (data.pantsColor === undefined) data.pantsColor = 'blue';
  if (data.bodyColor === undefined) data.bodyColor = 'terracotta';
  if (data.colorChangeTickets === undefined) data.colorChangeTickets = 3;
  if (data.lastColorTicketMinutes === undefined) data.lastColorTicketMinutes = data.stats.totalTimeMinutes || 0;
```
Leave the v1→v2 migration block alone (it doesn't touch color).

- [ ] **Step 3: Verify**

```bash
grep -n 'colorChangeTicket\|lastColorTicket\|bodyColor\|pantsColor' pet/pet-aggregator.mjs
```
Expected: no output.

### Task A7: Build and smoke test Phase A

- [ ] **Step 1: Build**

```bash
cd pet && bash install.sh
```
Expected: ends with `App → /Users/.../OhMyClawd.app` and no red `Build failed` output.

- [ ] **Step 2: Launch and verify**

```bash
open "$HOME/Applications/OhMyClawd.app"
```
Open a Claude Code session in some project. Click the menu-bar icon. Verify:
- Header shows `Clawd` on the left and `Walking happily` (or similar `activityLevel.displayName`) on the right.
- No `Color (N)` dice button anywhere.
- Clawd sprite is terracotta orange.

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/PantsColorPalette.swift \
        pet/ClaudePet/Sources/PixelArtRenderer.swift \
        pet/ClaudePet/Sources/ProgressTracker.swift \
        pet/ClaudePet/Sources/AppDelegate.swift \
        pet/ClaudePet/Sources/CollectionView.swift \
        pet/pet-aggregator.mjs
git commit -m "$(cat <<'EOF'
refactor: remove body-color roulette, lock Clawd to terracotta

Deletes the 8-hour color ticket system, body-color state tracking, and
all roulette UI. Legacy progress.json fields are silently ignored on
read. Pants color remains fixed denim-blue.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase B — Fix "Session Active but Clawd Sleeping" Bug

### Task B1: PID-alive fallback in aggregator

**Files:**
- Modify: `pet/pet-aggregator.mjs`

- [ ] **Step 1: Restructure the per-session loop to fall back on stale/missing state**

Locate the loop inside `tick()` that begins `for (const session of aliveSessions) {` and currently reads the state file, `continue`s on missing/stale state, and pushes to `sessionDetails`.

Replace the body of that for-loop with:

```js
      try {
        const cwd = session.cwd;
        if (!cwd) continue;

        const stateFile = join(cwd, '.claude', '.hud', 'session-state.json');
        const usageFile = join(cwd, '.claude', '.hud', 'usage-cache.json');

        const rawState = await readJsonSafe(stateFile);
        const now = Date.now();
        const stateFresh =
          rawState?.timestamp &&
          (now - rawState.timestamp) <= IDLE_THRESHOLD_MS;
        const state = stateFresh ? rawState : null;

        if (state) {
          const usage = await readJsonSafe(usageFile);
          if (usage?.timestamp && usage.timestamp > latestUsageTs) {
            latestUsageTs = usage.timestamp;
            latestUsage = usage.data || null;
          }

          sessionDetails.push({
            pid: session.pid,
            project: basename(cwd),
            model: state.model || 'unknown',
            contextPercent: state.contextPercent || 0,
            toolCalls: state.toolCalls || 0,
            runningAgents: state.runningAgents || 0,
            sessionMinutes: state.sessionMinutes || 0,
          });

          if (state.model) models.push(state.model);
        } else {
          // PID is alive but HUD statusline hasn't written (or is disabled).
          // Treat the session as active with safe defaults derived from
          // ~/.claude/sessions/<pid>.json.
          const startedAt = session.startedAt ?? now;
          sessionDetails.push({
            pid: session.pid,
            project: basename(cwd),
            model: 'unknown',
            contextPercent: 0,
            toolCalls: 0,
            runningAgents: 0,
            sessionMinutes: Math.max(0, Math.floor((now - startedAt) / 60_000)),
          });
        }
      } catch { continue; }
```

Note: move the `const now = Date.now();` declaration that used to live above this loop (if present) down inside the loop, OR remove the outer declaration to avoid shadow warnings. The canonical answer is: `now` lives inside the loop body as shown above.

- [ ] **Step 2: Verify the file still parses**

```bash
node --check pet/pet-aggregator.mjs
```
Expected: no output (success). Any syntax error fails loudly.

### Task B2: Surface active project names in the view model

**Files:**
- Modify: `pet/ClaudePet/Sources/CollectionView.swift`

- [ ] **Step 1: Add `activeProjectNames` to `ClawdViewModel`**

Add this `@Published` field near the other session fields:
```swift
@Published var activeProjectNames: [String] = []
```

In `refresh(stateData:)`, inside the `if let data = stateData { ... }` branch, after `activeAgents = data.aggregate.totalRunningAgents`, add:
```swift
activeProjectNames = data.sessions.map { $0.project }
```

In the `else` branch, add:
```swift
activeProjectNames = []
```

- [ ] **Step 2: Render project names in the header**

In `CollectionPopoverView.headerSection`, find the `HStack { Text("Sessions: \(viewModel.activeSessions)") ... Text("Agents: \(viewModel.activeAgents)") }` block. Replace it with:

```swift
HStack {
    Text("Sessions: \(viewModel.activeSessions)")
        .font(.system(size: 11))
        .foregroundColor(.secondary)
    Spacer()
    Text("Agents: \(viewModel.activeAgents)")
        .font(.system(size: 11))
        .foregroundColor(.secondary)
}
if !viewModel.activeProjectNames.isEmpty {
    HStack {
        Text(projectNamesSummary(viewModel.activeProjectNames))
            .font(.system(size: 10))
            .foregroundColor(.secondary.opacity(0.75))
            .lineLimit(1)
            .truncationMode(.tail)
        Spacer()
    }
}
```

Then add this helper inside `CollectionPopoverView` (near `formatResetTime`):
```swift
private func projectNamesSummary(_ names: [String]) -> String {
    let shown = names.prefix(3)
    let extra = names.count - shown.count
    let head = shown.joined(separator: ", ")
    return extra > 0 ? "\(head) +\(extra) more" : head
}
```

### Task B3: Build and smoke test Phase B

- [ ] **Step 1: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

- [ ] **Step 2: Manual test — HUD off**

In the popover, toggle `HUD` to `OFF`. Quit and restart Claude Code in a project. Within ~5 seconds the menu-bar icon should transition from idle (Zzz) to normal. Reopen the popover — you should see `Sessions: 1`, `Agents: 0`, and the project basename on the line below.

- [ ] **Step 3: Manual test — HUD on**

Toggle `HUD` back to `ON`. Verify that after a tool call, `toolCalls`/`model` populate as before (inspect `~/.claude/pet/pet-state.json` directly if unsure).

- [ ] **Step 4: Commit**

```bash
git add pet/pet-aggregator.mjs pet/ClaudePet/Sources/CollectionView.swift
git commit -m "$(cat <<'EOF'
fix: detect active Claude sessions even when HUD statusline is off

pet-aggregator.mjs now treats a live PID as an active session with
safe defaults when session-state.json is missing or stale, instead of
silently dropping it. The popover surfaces active project names so
detection is visibly verifiable.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase C — Companion Data Layer

### Task C1: Create `ClawdMemory.swift`

**Files:**
- Create: `pet/ClaudePet/Sources/ClawdMemory.swift`

- [ ] **Step 1: Write the file**

```swift
import Foundation

// ============================================================================
// MARK: - Model types
// ============================================================================

struct ReminderConfig: Codable, Equatable {
    var enabled: Bool
    var intervalMin: Int?     // water / stretch
    var timeOfDay: String?    // diary, "HH:mm" local
    var lastAt: Double        // unix millis; 0 = never
    var lastDate: String?     // diary only, "YYYY-MM-DD" local
}

struct ClawdReminders: Codable, Equatable {
    var water: ReminderConfig
    var stretch: ReminderConfig
    var diary: ReminderConfig

    static let `default` = ClawdReminders(
        water:   ReminderConfig(enabled: true, intervalMin: 60, timeOfDay: nil, lastAt: 0, lastDate: nil),
        stretch: ReminderConfig(enabled: true, intervalMin: 90, timeOfDay: nil, lastAt: 0, lastDate: nil),
        diary:   ReminderConfig(enabled: true, intervalMin: nil, timeOfDay: "22:00", lastAt: 0, lastDate: nil)
    )
}

struct ClawdMemo: Codable, Identifiable, Equatable {
    let id: String
    var text: String
    let createdAt: String         // ISO8601
    var dueAt: String?            // ISO8601 or nil
    var tags: [String]
    var done: Bool
    var completedAt: String?
}

enum ChatRole: String, Codable { case user, clawd, system }

struct ChatTurn: Codable, Equatable {
    let role: ChatRole
    let text: String
    let ts: Double                // unix millis
}

struct ClawdMemoryFile: Codable, Equatable {
    var version: Int
    var reminders: ClawdReminders
    var memos: [ClawdMemo]
    var chatLog: [ChatTurn]

    static let empty = ClawdMemoryFile(
        version: 1,
        reminders: .default,
        memos: [],
        chatLog: []
    )
}

// ============================================================================
// MARK: - Store
// ============================================================================

final class ClawdMemoryStore {
    private let filePath: String
    private let queue = DispatchQueue(label: "clawd.memory", qos: .utility)

    init() {
        let dir = NSHomeDirectory() + "/.claude/pet"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        filePath = dir + "/clawd-memory.json"
    }

    func read() -> ClawdMemoryFile {
        guard let data = FileManager.default.contents(atPath: filePath),
              let decoded = try? JSONDecoder().decode(ClawdMemoryFile.self, from: data) else {
            return .empty
        }
        return decoded
    }

    /// Atomic write. Safe to call from the main thread; serializes to a
    /// background queue.
    func write(_ file: ClawdMemoryFile) {
        queue.async { [filePath] in
            guard let data = try? JSONEncoder().encode(file) else { return }
            let tmp = filePath + ".tmp"
            FileManager.default.createFile(atPath: tmp, contents: data)
            _ = try? FileManager.default.replaceItemAt(
                URL(fileURLWithPath: filePath),
                withItemAt: URL(fileURLWithPath: tmp)
            )
        }
    }

    /// Atomically mutate the file. Closure receives a mutable copy and
    /// returns the new file to persist. Reads are on the caller thread;
    /// writes are serialized on the store's queue.
    @discardableResult
    func update(_ mutator: (inout ClawdMemoryFile) -> Void) -> ClawdMemoryFile {
        var file = read()
        mutator(&file)
        // Cap chat log at last 20 turns
        if file.chatLog.count > 20 {
            file.chatLog = Array(file.chatLog.suffix(20))
        }
        write(file)
        return file
    }

    // MARK: - Memo helpers

    static func newMemoId() -> String {
        // Short sortable id: "mem_<epochMillis>_<rand>"
        let ms = Int(Date().timeIntervalSince1970 * 1000)
        let rnd = String(UInt32.random(in: 0..<UInt32.max), radix: 36)
        return "mem_\(ms)_\(rnd)"
    }

    static func isoNow() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.string(from: Date())
    }

    static func parseIso(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }
}
```

- [ ] **Step 2: Add the file to the build**

Modify `pet/install.sh` line 43–67 (the `swiftc -o` block) by adding one line after `Sources/ProgressTracker.swift \`:

```bash
  Sources/ClawdMemory.swift \
```

The full additions list for this plan will grow; Phase H does a final verification pass. For now, this single addition is enough to compile C1.

- [ ] **Step 3: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

- [ ] **Step 4: Commit**

```bash
git add pet/ClaudePet/Sources/ClawdMemory.swift pet/install.sh
git commit -m "$(cat <<'EOF'
feat: add ClawdMemory store for memos, reminders, chat log

Introduces ~/.claude/pet/clawd-memory.json with atomic writes and a
capped 20-turn chat log. No UI or consumers yet.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase D — Notification Generalization

### Task D1: Generalize `NotificationManager`

**Files:**
- Modify: `pet/ClaudePet/Sources/NotificationManager.swift`

- [ ] **Step 1: Replace the file with the expanded version**

```swift
import Cocoa
import UserNotifications

final class NotificationManager {
    private var lastByKey: [String: Date] = [:]
    private let rateLimitCooldown: TimeInterval = 300   // 5 min for rate-limit warnings
    private let clawdCooldown: TimeInterval = 60        // 1 min between any two Clawd pings

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, _ in }
    }

    // MARK: - Rate limit (existing behavior)

    func checkAndNotify(rateLimit: RateLimitData) {
        guard let percent = rateLimit.fiveHourPercent, percent >= 80 else { return }
        if let last = lastByKey["rateLimit"],
           Date().timeIntervalSince(last) < rateLimitCooldown { return }
        sendRaw(
            id: "rate-limit-\(Int(Date().timeIntervalSince1970))",
            title: "oh-my-clawd - Rate Limit Warning",
            body: "5-hour rate limit at \(Int(percent))%. Consider taking a break!"
        )
        lastByKey["rateLimit"] = Date()
    }

    // MARK: - Clawd messages (reminders + memos)

    /// Fire a Clawd notification. `key` dedupes within `clawdCooldown`; pass a
    /// unique key per event (e.g. `"water"`, `"memo:<id>"`).
    func sendClawdMessage(key: String, title: String, body: String) {
        if let last = lastByKey[key],
           Date().timeIntervalSince(last) < clawdCooldown { return }
        sendRaw(
            id: "clawd-\(key)-\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body
        )
        lastByKey[key] = Date()
    }

    // MARK: - Private

    private func sendRaw(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
```

- [ ] **Step 2: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/NotificationManager.swift
git commit -m "$(cat <<'EOF'
refactor: generalize NotificationManager with per-key cooldowns

Adds sendClawdMessage(key:title:body:) for reminder/memo notifications,
each with its own 1-minute dedup window. The rate-limit path keeps its
existing 5-minute cooldown.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase E — Reminder Scheduler

### Task E1: Create `ReminderScheduler.swift`

**Files:**
- Create: `pet/ClaudePet/Sources/ReminderScheduler.swift`

- [ ] **Step 1: Write the file**

```swift
import Foundation

final class ReminderScheduler {
    private let memory: ClawdMemoryStore
    private let stateReader: PetStateReader
    private let notifications: NotificationManager
    private var timer: Timer?

    init(memory: ClawdMemoryStore,
         stateReader: PetStateReader,
         notifications: NotificationManager) {
        self.memory = memory
        self.stateReader = stateReader
        self.notifications = notifications
    }

    func start() {
        timer?.invalidate()
        // Tick every 60s; also fire once immediately at start so first
        // launch with enabled reminders doesn't wait a full minute.
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = Date()
        let nowMs = now.timeIntervalSince1970 * 1000
        let activeSessions = stateReader.read()?.activeSessions ?? 0

        memory.update { file in
            // --- Interval reminders (water, stretch) ---
            fireInterval(key: "water",
                         title: "Clawd",
                         body: "물 한 잔 마실 시간이에요 💧",
                         config: &file.reminders.water,
                         nowMs: nowMs,
                         activeSessions: activeSessions)
            fireInterval(key: "stretch",
                         title: "Clawd",
                         body: "잠깐 스트레칭 해볼까요? 🧘",
                         config: &file.reminders.stretch,
                         nowMs: nowMs,
                         activeSessions: activeSessions)

            // --- Diary (once per local day, after timeOfDay) ---
            fireDiary(config: &file.reminders.diary, now: now)

            // --- Due memos ---
            for i in file.memos.indices {
                guard !file.memos[i].done,
                      let dueIso = file.memos[i].dueAt,
                      let due = ClawdMemoryStore.parseIso(dueIso),
                      due <= now else { continue }
                notifications.sendClawdMessage(
                    key: "memo:\(file.memos[i].id)",
                    title: "Clawd 알림",
                    body: file.memos[i].text
                )
                file.memos[i].done = true
                file.memos[i].completedAt = ClawdMemoryStore.isoNow()
            }
        }
    }

    private func fireInterval(key: String,
                              title: String,
                              body: String,
                              config: inout ReminderConfig,
                              nowMs: Double,
                              activeSessions: Int) {
        guard config.enabled,
              activeSessions > 0,
              let interval = config.intervalMin,
              interval >= 30 else { return }
        if config.lastAt == 0 {
            // First-ever schedule: seed lastAt = now so the first ping
            // comes after one full interval, not immediately.
            config.lastAt = nowMs
            return
        }
        let elapsedMin = (nowMs - config.lastAt) / 60_000
        if elapsedMin >= Double(interval) {
            notifications.sendClawdMessage(key: key, title: title, body: body)
            config.lastAt = nowMs
        }
    }

    private func fireDiary(config: inout ReminderConfig, now: Date) {
        guard config.enabled,
              let timeStr = config.timeOfDay else { return }
        let cal = Calendar.current
        let today = Self.localDateString(now)
        if config.lastDate == today { return }

        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }
        let comps = cal.dateComponents([.hour, .minute], from: now)
        guard let nowH = comps.hour, let nowM = comps.minute else { return }
        let nowMinutes = nowH * 60 + nowM
        let targetMinutes = hour * 60 + minute
        guard nowMinutes >= targetMinutes else { return }

        notifications.sendClawdMessage(
            key: "diary",
            title: "Clawd",
            body: "오늘 하루 일기 어떠세요? 📝"
        )
        config.lastDate = today
        config.lastAt = now.timeIntervalSince1970 * 1000
    }

    private static func localDateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt.string(from: date)
    }
}
```

- [ ] **Step 2: Add the file to the build**

Edit `pet/install.sh`. After the line `Sources/ClawdMemory.swift \`, add:
```bash
  Sources/ReminderScheduler.swift \
```

### Task E2: Wire the scheduler into `AppDelegate`

**Files:**
- Modify: `pet/ClaudePet/Sources/AppDelegate.swift`

- [ ] **Step 1: Add the property and store**

Near the other properties (e.g. below `private var notificationManager = NotificationManager()`), add:

```swift
private let clawdMemory = ClawdMemoryStore()
private lazy var reminderScheduler = ReminderScheduler(
    memory: clawdMemory,
    stateReader: stateReader,
    notifications: notificationManager
)
```

- [ ] **Step 2: Start the scheduler**

In `applicationDidFinishLaunching`, after `startStatePolling()`, add:
```swift
reminderScheduler.start()
```

### Task E3: Build and smoke test Phase E

- [ ] **Step 1: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

- [ ] **Step 2: Manual test — force a water reminder immediately**

Create a seeded memory file:
```bash
mkdir -p ~/.claude/pet
cat > ~/.claude/pet/clawd-memory.json <<'EOF'
{
  "version": 1,
  "reminders": {
    "water":   { "enabled": true,  "intervalMin": 30, "timeOfDay": null, "lastAt": 1, "lastDate": null },
    "stretch": { "enabled": false, "intervalMin": 90, "timeOfDay": null, "lastAt": 0, "lastDate": null },
    "diary":   { "enabled": false, "intervalMin": null, "timeOfDay": "22:00", "lastAt": 0, "lastDate": null }
  },
  "memos": [],
  "chatLog": []
}
EOF
```
With `lastAt: 1` (1ms after epoch), the water interval is far past due. Open any Claude Code session (so `activeSessions > 0`), quit and relaunch OhMyClawd, wait up to 60 seconds. You should see a native notification: `Clawd — 물 한 잔 마실 시간이에요 💧`.

After it fires, `~/.claude/pet/clawd-memory.json` should have `water.lastAt` updated to roughly `Date.now() * 1`.

- [ ] **Step 3: Manual test — due memo**

```bash
cat > ~/.claude/pet/clawd-memory.json <<EOF
{
  "version": 1,
  "reminders": { "water":{"enabled":false,"intervalMin":60,"timeOfDay":null,"lastAt":0,"lastDate":null},
                 "stretch":{"enabled":false,"intervalMin":90,"timeOfDay":null,"lastAt":0,"lastDate":null},
                 "diary":{"enabled":false,"intervalMin":null,"timeOfDay":"22:00","lastAt":0,"lastDate":null} },
  "memos": [{"id":"mem_test","text":"테스트 알림","createdAt":"2026-04-14T00:00:00Z","dueAt":"2026-04-14T00:00:00Z","tags":[],"done":false,"completedAt":null}],
  "chatLog": []
}
EOF
```
Relaunch. Within 60 seconds, a notification `Clawd 알림 — 테스트 알림` should fire, and the memo should be flipped to `"done": true`.

- [ ] **Step 4: Commit**

```bash
git add pet/ClaudePet/Sources/ReminderScheduler.swift \
        pet/ClaudePet/Sources/AppDelegate.swift \
        pet/install.sh
git commit -m "$(cat <<'EOF'
feat: schedule water/stretch/diary reminders and due memos

Adds a 60-second ReminderScheduler owned by AppDelegate. Water and
stretch fire only while at least one Claude session is active; diary
fires once per local day after its timeOfDay; memos fire when dueAt
passes and are marked done atomically.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase F — Claude Bridge

### Task F1: Create `ClawdChat.swift`

**Files:**
- Create: `pet/ClaudePet/Sources/ClawdChat.swift`

- [ ] **Step 1: Write the file**

```swift
import Foundation

// ============================================================================
// MARK: - Response types
// ============================================================================

enum ClawdActionType: String, Codable {
    case addMemo       = "add_memo"
    case completeMemo  = "complete_memo"
    case deleteMemo    = "delete_memo"
    case setReminder   = "set_reminder"
    case unknown
}

struct ClawdAction: Codable {
    let type: String
    let text: String?
    let dueAt: String?
    let tags: [String]?
    let id: String?
    let kind: String?
    let enabled: Bool?
    let intervalMin: Int?
    let timeOfDay: String?

    var typed: ClawdActionType {
        ClawdActionType(rawValue: type) ?? .unknown
    }
}

struct ClawdResponse: Codable {
    let actions: [ClawdAction]
    let reply: String
}

enum ClawdChatError: Error {
    case cliNotFound
    case processFailed(String)
    case timeout
    case parseFailed(raw: String)
}

// ============================================================================
// MARK: - Bridge
// ============================================================================

final class ClawdChat {
    static let modelId = "claude-haiku-4-5"
    private let timeoutSeconds: TimeInterval = 10
    private let memory: ClawdMemoryStore

    init(memory: ClawdMemoryStore) {
        self.memory = memory
    }

    /// Runs `claude -p` synchronously on a background thread and completes on
    /// the main queue. Safe to call from UI.
    func send(userText: String,
              completion: @escaping (Result<ClawdResponse, ClawdChatError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.runBlocking(userText: userText)
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - Internal

    private func runBlocking(userText: String) -> Result<ClawdResponse, ClawdChatError> {
        guard let claudePath = Self.resolveClaudePath() else {
            return .failure(.cliNotFound)
        }

        let file = memory.read()
        let systemPrompt = Self.buildSystemPrompt(file: file)
        let stdinPayload = systemPrompt + "\n\nUser: " + userText + "\n"

        let task = Process()
        task.launchPath = claudePath
        task.arguments = [
            "-p",
            "--model", Self.modelId,
            "--output-format", "json",
        ]
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        task.standardInput = stdin
        task.standardOutput = stdout
        task.standardError = stderr

        do {
            try task.run()
        } catch {
            return .failure(.processFailed("launch: \(error.localizedDescription)"))
        }

        stdin.fileHandleForWriting.write(stdinPayload.data(using: .utf8) ?? Data())
        try? stdin.fileHandleForWriting.close()

        // Enforce timeout via wall clock.
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while task.isRunning {
            if Date() > deadline {
                task.terminate()
                return .failure(.timeout)
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        let outStr = String(data: outData, encoding: .utf8) ?? ""
        let errStr = String(data: errData, encoding: .utf8) ?? ""

        guard task.terminationStatus == 0 else {
            return .failure(.processFailed("exit \(task.terminationStatus): \(errStr.prefix(200))"))
        }

        return Self.extractResponse(from: outStr)
    }

    private static func resolveClaudePath() -> String? {
        // Try common locations first, then PATH.
        let candidates = [
            NSHomeDirectory() + "/.claude/local/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
        ]
        for p in candidates where FileManager.default.isExecutableFile(atPath: p) {
            return p
        }
        // Fall back to `which claude` via /bin/sh -l so the user's login PATH applies.
        let which = Process()
        which.launchPath = "/bin/sh"
        which.arguments = ["-lc", "command -v claude"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        do { try which.run() } catch { return nil }
        which.waitUntilExit()
        guard which.terminationStatus == 0 else { return nil }
        let out = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (out?.isEmpty == false) ? out : nil
    }

    // MARK: - Prompt

    private static func buildSystemPrompt(file: ClawdMemoryFile) -> String {
        let now = Date()
        let tz = TimeZone.current.identifier
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime]
        let nowIso = isoFmt.string(from: now)

        let remindersJson = (try? JSONEncoder().encode(file.reminders))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let openMemos = file.memos.filter { !$0.done }.suffix(10)
        let memosJson = (try? JSONEncoder().encode(Array(openMemos)))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let recentChat = file.chatLog.suffix(6)
        let chatJson = (try? JSONEncoder().encode(Array(recentChat)))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return """
        You are Clawd, a pixel-art mascot living in the user's macOS menu bar. \
        Help the user remember things, nudge good habits, and occasionally chat. \
        Reply in the user's language (default 한국어).

        You MUST respond with a single JSON object, no prose, no code fences:
        {"actions": Action[], "reply": string}

        Supported actions (ignore unknown fields, emit none if not needed):
          - add_memo      { "text": string, "dueAt": ISO8601 | null, "tags": string[] }
          - complete_memo { "id": string }
          - delete_memo   { "id": string }
          - set_reminder  { "kind": "water"|"stretch"|"diary",
                            "enabled": bool?,
                            "intervalMin": number?,
                            "timeOfDay": "HH:mm"? }

        If the user asks a general question (weather, news, facts), you may \
        use your web tools and put the answer in `reply` with actions: []. \
        Do not create memos the user did not ask for. Keep `reply` to 1–2 \
        warm sentences.

        Current time: \(nowIso) (\(tz)).
        Resolve relative times ("3시", "내일 오전 10시", "30분 뒤") to absolute ISO8601 \
        in the user's timezone. If ambiguous, leave dueAt null and ask in `reply`.

        Current reminders: \(remindersJson)
        Open memos (newest last, up to 10): \(memosJson)
        Recent chat (last 6, oldest first): \(chatJson)
        """
    }

    // MARK: - Response extraction

    static func extractResponse(from cliOutput: String) -> Result<ClawdResponse, ClawdChatError> {
        // `claude -p --output-format json` emits an envelope whose shape is:
        //   { "type": "result", "subtype": "success", "result": "<assistant text>", ... }
        // We extract `.result` (the assistant's final text) and parse it as our JSON.
        guard let data = cliOutput.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.parseFailed(raw: cliOutput))
        }
        let assistantText: String
        if let s = root["result"] as? String {
            assistantText = s
        } else if let msgs = root["messages"] as? [[String: Any]],
                  let last = msgs.last,
                  let content = last["content"] as? String {
            assistantText = content
        } else {
            return .failure(.parseFailed(raw: cliOutput))
        }

        // Try to parse the assistant text directly; if it's wrapped in a
        // fenced ```json block, strip the fence.
        let cleaned = stripFences(assistantText)
        guard let body = cleaned.data(using: .utf8),
              let response = try? JSONDecoder().decode(ClawdResponse.self, from: body) else {
            return .failure(.parseFailed(raw: assistantText))
        }
        return .success(response)
    }

    private static func stripFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNL = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNL)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3))
            }
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }
}
```

- [ ] **Step 2: Add the file to the build**

Edit `pet/install.sh`. After `Sources/ReminderScheduler.swift \`, add:
```bash
  Sources/ClawdChat.swift \
```

- [ ] **Step 3: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

### Task F2: Create `ClawdActionRunner.swift`

**Files:**
- Create: `pet/ClaudePet/Sources/ClawdActionRunner.swift`

- [ ] **Step 1: Write the file**

```swift
import Foundation

final class ClawdActionRunner {
    private let memory: ClawdMemoryStore

    init(memory: ClawdMemoryStore) {
        self.memory = memory
    }

    /// Apply all actions and append the user/clawd turns to chatLog.
    /// Returns a short summary of what changed (for debug/logging).
    @discardableResult
    func apply(userText: String, response: ClawdResponse) -> [String] {
        var summary: [String] = []
        memory.update { file in
            let ts = Date().timeIntervalSince1970 * 1000
            file.chatLog.append(ChatTurn(role: .user, text: userText, ts: ts))

            for action in response.actions {
                switch action.typed {
                case .addMemo:
                    guard let text = action.text, !text.isEmpty else {
                        summary.append("add_memo: missing text"); continue
                    }
                    let memo = ClawdMemo(
                        id: ClawdMemoryStore.newMemoId(),
                        text: text,
                        createdAt: ClawdMemoryStore.isoNow(),
                        dueAt: action.dueAt,
                        tags: action.tags ?? [],
                        done: false,
                        completedAt: nil
                    )
                    file.memos.append(memo)
                    summary.append("add_memo: \(memo.id)")

                case .completeMemo:
                    guard let id = action.id,
                          let idx = file.memos.firstIndex(where: { $0.id == id }) else {
                        summary.append("complete_memo: id not found"); continue
                    }
                    file.memos[idx].done = true
                    file.memos[idx].completedAt = ClawdMemoryStore.isoNow()
                    summary.append("complete_memo: \(id)")

                case .deleteMemo:
                    guard let id = action.id else {
                        summary.append("delete_memo: missing id"); continue
                    }
                    let before = file.memos.count
                    file.memos.removeAll { $0.id == id }
                    summary.append(before == file.memos.count
                                   ? "delete_memo: id not found"
                                   : "delete_memo: \(id)")

                case .setReminder:
                    guard let kind = action.kind else {
                        summary.append("set_reminder: missing kind"); continue
                    }
                    switch kind {
                    case "water":   apply(config: &file.reminders.water, action: action)
                    case "stretch": apply(config: &file.reminders.stretch, action: action)
                    case "diary":   apply(config: &file.reminders.diary, action: action)
                    default: summary.append("set_reminder: unknown kind \(kind)"); continue
                    }
                    summary.append("set_reminder: \(kind)")

                case .unknown:
                    summary.append("unknown action: \(action.type)")
                }
            }

            file.chatLog.append(ChatTurn(role: .clawd, text: response.reply, ts: ts))
        }
        return summary
    }

    /// Local-only reminder mutation (used by UI toggles, no LLM round-trip).
    func setReminderDirect(kind: String,
                           enabled: Bool? = nil,
                           intervalMin: Int? = nil,
                           timeOfDay: String? = nil) {
        memory.update { file in
            let action = ClawdAction(
                type: ClawdActionType.setReminder.rawValue,
                text: nil, dueAt: nil, tags: nil, id: nil,
                kind: kind, enabled: enabled,
                intervalMin: intervalMin, timeOfDay: timeOfDay
            )
            switch kind {
            case "water":   apply(config: &file.reminders.water, action: action)
            case "stretch": apply(config: &file.reminders.stretch, action: action)
            case "diary":   apply(config: &file.reminders.diary, action: action)
            default: break
            }
        }
    }

    func deleteMemo(id: String) {
        memory.update { file in
            file.memos.removeAll { $0.id == id }
        }
    }

    func completeMemo(id: String) {
        memory.update { file in
            if let idx = file.memos.firstIndex(where: { $0.id == id }) {
                file.memos[idx].done = true
                file.memos[idx].completedAt = ClawdMemoryStore.isoNow()
            }
        }
    }

    // MARK: - Private

    private func apply(config: inout ReminderConfig, action: ClawdAction) {
        if let e = action.enabled { config.enabled = e }
        if let m = action.intervalMin, m >= 30 { config.intervalMin = m }
        if let t = action.timeOfDay, t.count == 5, t.contains(":") {
            config.timeOfDay = t
        }
    }
}
```

- [ ] **Step 2: Add the file to the build**

Edit `pet/install.sh`. After `Sources/ClawdChat.swift \`, add:
```bash
  Sources/ClawdActionRunner.swift \
```

- [ ] **Step 3: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

### Task F3: Smoke test bridge end-to-end from a scratch harness

Skip if `claude` CLI is not available; the companion will fall back to "raw memo" in Phase G.

- [ ] **Step 1: Run a one-shot CLI test**

```bash
claude -p --model claude-haiku-4-5 --output-format json <<'EOF'
Return JSON only: {"actions":[{"type":"add_memo","text":"test","dueAt":null,"tags":[]}],"reply":"저장했어요."}
EOF
```
Expected: a JSON envelope with a `result` field containing the inner JSON we asked for. If this works, the Swift bridge will too.

- [ ] **Step 2: Commit Phase F**

```bash
git add pet/ClaudePet/Sources/ClawdChat.swift \
        pet/ClaudePet/Sources/ClawdActionRunner.swift \
        pet/install.sh
git commit -m "$(cat <<'EOF'
feat: bridge to claude -p for memo/reminder natural language

ClawdChat subprocesses the claude CLI with Haiku 4.5 and parses a
{actions, reply} JSON envelope with a 10-second timeout and fenced-code
tolerance. ClawdActionRunner dispatches each action against the memory
store and appends chat turns. Unknown action types are ignored for
forward compatibility.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase G — Popover UI

### Task G1: Extend `ClawdViewModel` with companion state

**Files:**
- Modify: `pet/ClaudePet/Sources/CollectionView.swift`

- [ ] **Step 1: Add published fields and dependencies**

At the top of `ClawdViewModel` (near the existing `@Published` block), add:

```swift
// Companion
@Published var reminders: ClawdReminders = .default
@Published var openMemos: [ClawdMemo] = []
@Published var lastReply: String = ""
@Published var chatInProgress: Bool = false
@Published var chatError: String? = nil
```

Also add these private fields at the bottom of the same property group (alongside `private let progressTracker = ProgressTracker()`):

```swift
private let clawdMemory = ClawdMemoryStore()
private lazy var actionRunner = ClawdActionRunner(memory: clawdMemory)
private lazy var chat = ClawdChat(memory: clawdMemory)
```

- [ ] **Step 2: Refresh companion state alongside existing state**

At the end of `refresh(stateData:)`, add:
```swift
loadCompanionState()
```

Then add this method anywhere in the class:
```swift
func loadCompanionState() {
    let file = clawdMemory.read()
    reminders = file.reminders
    openMemos = file.memos.filter { !$0.done }
    lastReply = file.chatLog.last(where: { $0.role == .clawd })?.text ?? ""
}
```

- [ ] **Step 3: Add send / toggle / memo mutation methods**

Add below `loadCompanionState()`:

```swift
func sendChat(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !chatInProgress else { return }
    chatInProgress = true
    chatError = nil
    chat.send(userText: trimmed) { [weak self] result in
        guard let self = self else { return }
        self.chatInProgress = false
        switch result {
        case .success(let response):
            self.actionRunner.apply(userText: trimmed, response: response)
            self.loadCompanionState()
        case .failure(let err):
            self.handleChatFailure(userText: trimmed, error: err)
        }
    }
}

private func handleChatFailure(userText: String, error: ClawdChatError) {
    // Fall back: save the raw utterance as a memo so nothing is lost.
    let fallbackResponse = ClawdResponse(
        actions: [ClawdAction(
            type: ClawdActionType.addMemo.rawValue,
            text: userText, dueAt: nil, tags: [], id: nil,
            kind: nil, enabled: nil, intervalMin: nil, timeOfDay: nil
        )],
        reply: Self.errorMessage(for: error)
    )
    actionRunner.apply(userText: userText, response: fallbackResponse)
    chatError = Self.errorMessage(for: error)
    loadCompanionState()
}

private static func errorMessage(for error: ClawdChatError) -> String {
    switch error {
    case .cliNotFound:
        return "Claude CLI를 찾지 못했어요. 메모로 저장만 해둘게요."
    case .timeout:
        return "응답이 느리네요. 메모로 저장만 해둘게요."
    case .processFailed(let msg):
        return "오류: \(msg). 메모로 저장만 해둘게요."
    case .parseFailed:
        return "응답을 이해하지 못했어요. 메모로 저장만 해둘게요."
    }
}

func toggleReminder(kind: String) {
    let current: ReminderConfig
    switch kind {
    case "water":   current = reminders.water
    case "stretch": current = reminders.stretch
    case "diary":   current = reminders.diary
    default: return
    }
    actionRunner.setReminderDirect(kind: kind, enabled: !current.enabled)
    loadCompanionState()
}

func setReminderInterval(kind: String, minutes: Int) {
    actionRunner.setReminderDirect(kind: kind, intervalMin: minutes)
    loadCompanionState()
}

func setDiaryTime(_ time: String) {
    actionRunner.setReminderDirect(kind: "diary", timeOfDay: time)
    loadCompanionState()
}

func completeMemo(_ id: String) {
    actionRunner.completeMemo(id: id)
    loadCompanionState()
}

func deleteMemo(_ id: String) {
    actionRunner.deleteMemo(id: id)
    loadCompanionState()
}
```

### Task G2: Create the `ClawdSection` view

**Files:**
- Create: `pet/ClaudePet/Sources/ClawdSection.swift`

- [ ] **Step 1: Write the file**

```swift
import SwiftUI

struct ClawdSection: View {
    @ObservedObject var viewModel: ClawdViewModel
    @State private var input: String = ""
    @State private var remindersExpanded: Bool = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Clawd")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack(spacing: 6) {
                TextField("Clawd에게 말하기…", text: $input, onCommit: submit)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .focused($inputFocused)
                    .disabled(viewModel.chatInProgress)
                if viewModel.chatInProgress {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: submit) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if !viewModel.lastReply.isEmpty || viewModel.chatError != nil {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: viewModel.chatError != nil
                          ? "exclamationmark.circle"
                          : "bubble.left.fill")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.chatError != nil ? .orange : .secondary)
                    Text(viewModel.chatError ?? viewModel.lastReply)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DisclosureGroup(isExpanded: $remindersExpanded) {
                VStack(spacing: 6) {
                    reminderRow(
                        emoji: "💧", label: "물",
                        kind: "water",
                        config: viewModel.reminders.water,
                        intervals: [30, 60, 90, 120]
                    )
                    reminderRow(
                        emoji: "🧘", label: "스트레칭",
                        kind: "stretch",
                        config: viewModel.reminders.stretch,
                        intervals: [60, 90, 120, 180]
                    )
                    diaryRow(config: viewModel.reminders.diary)
                }
                .padding(.top, 4)
            } label: {
                Text("리마인더")
                    .font(.system(size: 11, weight: .medium))
            }

            if !viewModel.openMemos.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📌 기억 중 (\(viewModel.openMemos.count))")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.top, 2)
                    ForEach(viewModel.openMemos) { memo in
                        memoRow(memo)
                    }
                }
            } else if viewModel.lastReply.isEmpty && viewModel.chatError == nil {
                Text("아직 기억할 게 없어요. 위에 말해보세요.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(12)
    }

    private func submit() {
        let text = input
        input = ""
        viewModel.sendChat(text)
    }

    private func reminderRow(emoji: String,
                             label: String,
                             kind: String,
                             config: ReminderConfig,
                             intervals: [Int]) -> some View {
        HStack(spacing: 6) {
            Text(emoji)
            Text(label)
                .font(.system(size: 11))
                .frame(width: 56, alignment: .leading)
            Toggle("", isOn: Binding(
                get: { config.enabled },
                set: { _ in viewModel.toggleReminder(kind: kind) }
            ))
            .labelsHidden()
            .controlSize(.mini)
            Spacer()
            Picker("", selection: Binding(
                get: { config.intervalMin ?? intervals[1] },
                set: { viewModel.setReminderInterval(kind: kind, minutes: $0) }
            )) {
                ForEach(intervals, id: \.self) { m in
                    Text("\(m)분").tag(m)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 80)
            .disabled(!config.enabled)
        }
    }

    private func diaryRow(config: ReminderConfig) -> some View {
        HStack(spacing: 6) {
            Text("📝")
            Text("일기")
                .font(.system(size: 11))
                .frame(width: 56, alignment: .leading)
            Toggle("", isOn: Binding(
                get: { config.enabled },
                set: { _ in viewModel.toggleReminder(kind: "diary") }
            ))
            .labelsHidden()
            .controlSize(.mini)
            Spacer()
            Picker("", selection: Binding(
                get: { config.timeOfDay ?? "22:00" },
                set: { viewModel.setDiaryTime($0) }
            )) {
                ForEach(["20:00", "21:00", "22:00", "23:00"], id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 80)
            .disabled(!config.enabled)
        }
    }

    private func memoRow(_ memo: ClawdMemo) -> some View {
        HStack(spacing: 6) {
            Button(action: { viewModel.completeMemo(memo.id) }) {
                Image(systemName: "circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Text(memo.text)
                .font(.system(size: 11))
                .lineLimit(2)

            Spacer()

            if let dueIso = memo.dueAt,
               let due = ClawdMemoryStore.parseIso(dueIso) {
                Text(formatDue(due))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Menu {
                Button("완료") { viewModel.completeMemo(memo.id) }
                Button("삭제", role: .destructive) { viewModel.deleteMemo(memo.id) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private func formatDue(_ due: Date) -> String {
        let cal = Calendar.current
        let fmt = DateFormatter()
        if cal.isDateInToday(due) {
            fmt.dateFormat = "오늘 HH:mm"
        } else if cal.isDateInTomorrow(due) {
            fmt.dateFormat = "내일 HH:mm"
        } else {
            fmt.dateFormat = "M/d HH:mm"
        }
        return fmt.string(from: due)
    }
}
```

- [ ] **Step 2: Add the file to the build**

Edit `pet/install.sh`. After `Sources/ClawdActionRunner.swift \`, add:
```bash
  Sources/ClawdSection.swift \
```

### Task G3: Wire `ClawdSection` into the popover

**Files:**
- Modify: `pet/ClaudePet/Sources/CollectionView.swift`

- [ ] **Step 1: Insert the section**

In `CollectionPopoverView.body`, find the block:

```swift
if viewModel.nextUnlockAccessory != nil {
    Divider()
    progressSection
}
```

Replace it with:
```swift
if viewModel.nextUnlockAccessory != nil {
    Divider()
    progressSection
}
Divider()
ClawdSection(viewModel: viewModel)
```

- [ ] **Step 2: Widen the popover to fit the new section**

In `StatusMenuController.swift`, the popover size is `NSSize(width: 280, height: 520)`. Change height to `640`:

```swift
popover.contentSize = NSSize(width: 280, height: 640)
```

And in `CollectionPopoverView.body`, update the outer `.frame(width: 280, height: 520)` to:
```swift
.frame(width: 280, height: 640)
```

### Task G4: Build and full smoke test

- [ ] **Step 1: Build**

```bash
cd pet && bash install.sh
```
Expected: success.

- [ ] **Step 2: Manual test — basic add**

Open the popover. In the Clawd field, type `3시에 회의 기억해줘` and press Enter.

Expected within ~5 seconds:
- Spinner appears then disappears.
- Reply line shows something like `오후 3시 회의 저장했어요.`
- A new memo appears in the `📌 기억 중` list with `오늘 15:00` (or today's date).
- `~/.claude/pet/clawd-memory.json` contains the memo with `dueAt` set to today at 15:00 in your local tz.

- [ ] **Step 3: Manual test — query**

Type `오늘 뭐 기억해둔 거 있어?`. Expected: reply lists the open memos; no new memo appears.

- [ ] **Step 4: Manual test — reminder toggle**

Expand `리마인더`. Toggle `🧘 스트레칭` off. Verify `~/.claude/pet/clawd-memory.json` has `stretch.enabled: false`.

Type `스트레칭 알림 다시 켜줘`. Expected: toggle flips to on within ~5s.

- [ ] **Step 5: Manual test — memo complete**

Click the circle next to a memo. It disappears from the list and `done: true` appears in the file.

- [ ] **Step 6: Manual test — web query**

Type `오늘 날씨 어때?`. Expected: the reply contains a weather summary (pulled via Claude's `WebFetch`/`WebSearch`), no memo is created.

- [ ] **Step 7: Manual test — fallback**

Temporarily break the CLI path:
```bash
mv ~/.claude/local/claude ~/.claude/local/claude.bak 2>/dev/null || true
```
Quit and relaunch OhMyClawd. Type `테스트 폴백`. Expected: a memo `테스트 폴백` is added; reply shows `Claude CLI를 찾지 못했어요. 메모로 저장만 해둘게요.`. Restore:
```bash
mv ~/.claude/local/claude.bak ~/.claude/local/claude 2>/dev/null || true
```

- [ ] **Step 8: Commit**

```bash
git add pet/ClaudePet/Sources/CollectionView.swift \
        pet/ClaudePet/Sources/ClawdSection.swift \
        pet/ClaudePet/Sources/StatusMenuController.swift \
        pet/install.sh
git commit -m "$(cat <<'EOF'
feat: add Clawd companion popover section

TextField feeds utterances to ClawdChat; replies surface under the
field. Collapsible reminder toggles call ClawdActionRunner directly.
Open memos list supports complete and delete. Popover widened to 640px
height to fit the new section.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase H — Final Verification & Polish

### Task H1: Ensure `install.sh` file list is complete

**Files:**
- Modify: `pet/install.sh`

- [ ] **Step 1: Confirm every source file is listed**

Run:
```bash
ls pet/ClaudePet/Sources/*.swift pet/ClaudePet/Sources/Sprites/*.swift
```
Every file in that output must appear in the `swiftc` command in `install.sh`. Compare against the current list. New files expected from this plan (verify all five are present):

```
Sources/ClawdMemory.swift
Sources/ReminderScheduler.swift
Sources/ClawdChat.swift
Sources/ClawdActionRunner.swift
Sources/ClawdSection.swift
```

If any are missing, add them in the same style as the others.

- [ ] **Step 2: Clean build**

```bash
rm -rf pet/ClaudePet/build
cd pet && bash install.sh
```
Expected: success from a cold cache.

### Task H2: End-to-end acceptance pass

Walk through every acceptance criterion in the spec:

- [ ] **Step 1: Color removal**

Run:
```bash
grep -rE 'bodyColor|colorChangeTicket|rollColor|pendingColor|BodyColor' pet/ClaudePet/Sources/ pet/pet-aggregator.mjs
```
Expected: no output.

- [ ] **Step 2: Legacy progress.json loads**

Inject a legacy-style value:
```bash
python3 -c "
import json, pathlib
p = pathlib.Path.home() / '.claude/pet/progress.json'
d = json.loads(p.read_text()) if p.exists() else {}
d['bodyColor'] = 'blue'
d['colorChangeTickets'] = 99
p.write_text(json.dumps(d))
"
```
Relaunch the app. Verify it does not crash and Clawd remains terracotta.

- [ ] **Step 3: Session detection works with HUD off**

Toggle HUD off in the popover. Start a Claude Code session in any project. Wait ≤5s. Verify Clawd transitions to normal and the popover header shows the project name.

- [ ] **Step 4: Companion flows**

Repeat tasks G4 steps 2–7 in one pass and confirm all behaviors still work.

- [ ] **Step 5: Scheduled notifications within ~1 minute**

Seed a due memo `dueAt` exactly 30 seconds in the future. Verify the notification fires within one minute of that timestamp and the memo is marked `done: true`.

### Task H3: Update memory and final commit

- [ ] **Step 1: Refresh the project memory file to reflect v3**

Update `/Users/hoyana/.claude/projects/-Users-hoyana-Desktop-01-sideproject-claude-hud/memory/project_oh_my_clawd_redesign.md` with one additional bullet:

```
- v3 (2026-04-14): body-color roulette removed; session detection now falls
  back to PID liveness; added Claude Haiku 4.5 companion (memos, reminders,
  extensible action DSL) via `claude -p` subprocess.
```

- [ ] **Step 2: Squash-merge check (optional)**

If the branch has many small commits, leave them as-is (the history is valuable for review). Do not squash unless requested.

- [ ] **Step 3: Final build and launch**

```bash
cd pet && bash install.sh
open "$HOME/Applications/OhMyClawd.app"
```
Confirm the app runs cleanly.

- [ ] **Step 4: No additional commit needed if H1–H2 produced none; otherwise commit any fixes discovered during acceptance.**

---

## Notes for the Executor

- **SourceKit editor errors are not failures.** Only `swiftc` command-line errors, run from `pet/install.sh`, count.
- **The `claude` CLI path is user-installed.** If your environment lacks it, Phase F's unit test (F3 Step 1) will fail but the implementation is still correct — the Swift fallback path covers this.
- **macOS notification permission** must be granted on first launch. If notifications don't appear during manual tests, open System Settings → Notifications → OhMyClawd and enable.
- **Do not combine phases in a single commit.** Each phase commit should stand alone so a bad change can be reverted without losing the others.
