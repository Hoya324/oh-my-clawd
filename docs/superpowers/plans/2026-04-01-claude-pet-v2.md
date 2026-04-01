# Claude Pet v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend Claude Pet from a single-cat menu bar companion to a 12-pet collectible system with muscle stages, condition-based unlocks, SwiftUI popover UI, macOS notifications, and GitHub Pages documentation.

**Architecture:** The pet-aggregator.mjs daemon gains cumulative stats tracking and writes progress.json alongside the existing pet-state.json. The Swift app adds a PetType system with per-pet sprite files, a MuscleStage enum that applies to all pets, and replaces the NSMenu dropdown with an NSPopover hosting SwiftUI views for the collection UI. A separate Node.js script generates SVG badges for the README.

**Tech Stack:** Swift (AppKit + SwiftUI), Node.js, Core Graphics (16x16 pixel art), GitHub Pages (HTML/CSS/JS)

**Spec:** `docs/superpowers/specs/2026-04-01-claude-pet-v2-design.md`

---

## File Structure

### Modified Files

| File | Responsibility |
|------|---------------|
| `pet/pet-aggregator.mjs` | Add cumulative stats tracking → `progress.json`, unlock condition checking |
| `pet/ClaudePet/Sources/PetStateMachine.swift` | Add `MuscleStage` enum, update `PetState.resolve()` to include muscle stage |
| `pet/ClaudePet/Sources/PetStateReader.swift` | Add `ProgressData` struct, read `progress.json` |
| `pet/ClaudePet/Sources/PixelArtRenderer.swift` | Refactor to accept `PetType` + `MuscleStage`, delegate to per-pet sprite files |
| `pet/ClaudePet/Sources/StatusMenuController.swift` | Replace NSMenu with NSPopover + SwiftUI hosting |
| `pet/ClaudePet/Sources/AppDelegate.swift` | Wire popover, notification permission, friend pets in menu bar |
| `pet/install.sh` | Add new Swift source files to swiftc command |

### New Files

| File | Responsibility |
|------|---------------|
| `pet/ClaudePet/Sources/PetType.swift` | `PetType` enum (12 pets), color palettes, unlock condition definitions |
| `pet/ClaudePet/Sources/NotificationManager.swift` | Rate limit macOS notification with 5-min dedup |
| `pet/ClaudePet/Sources/CollectionView.swift` | SwiftUI popover views: pet grid, progress bar, pet selection |
| `pet/ClaudePet/Sources/Sprites/CatSprites.swift` | Cat pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/HamsterSprites.swift` | Hamster pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/ChickSprites.swift` | Chick pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/PenguinSprites.swift` | Penguin pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/FoxSprites.swift` | Fox pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/RabbitSprites.swift` | Rabbit pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/GooseSprites.swift` | Goose pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/CapybaraSprites.swift` | Capybara pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/SlothSprites.swift` | Sloth pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/OwlSprites.swift` | Owl pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/DragonSprites.swift` | Dragon pixel art: normal/buff/macho × 5 frames |
| `pet/ClaudePet/Sources/Sprites/UnicornSprites.swift` | Unicorn pixel art: normal/buff/macho × 5 frames |
| `pet/generate-badge.mjs` | CLI script: reads progress.json → outputs SVG badge |
| `docs/index.html` | GitHub Pages main page |
| `docs/collection.html` | GitHub Pages pet collection / bestiary page |
| `docs/assets/style.css` | Retro dark theme CSS |

---

## Task 1: Progress Tracking in pet-aggregator.mjs

**Files:**
- Modify: `pet/pet-aggregator.mjs`

This task adds cumulative stats tracking and unlock condition checking to the aggregator daemon. It writes `~/.claude/pet/progress.json` alongside the existing `pet-state.json`.

- [ ] **Step 1: Add progress.json constants and unlock definitions**

Add these constants after the existing `MODEL_PRIORITY` constant at line 26:

```javascript
const PROGRESS_PATH = join(PET_DIR, 'progress.json');
const PROGRESS_TMP = join(PET_DIR, 'progress.json.tmp');

const UNLOCK_CONDITIONS = {
  cat:      { type: 'default' },
  hamster:  { type: 'totalSessions', threshold: 10 },
  chick:    { type: 'totalTimeMinutes', threshold: 300 },
  penguin:  { type: 'totalTokens', threshold: 500000 },
  fox:      { type: 'totalAgentRuns', threshold: 50 },
  rabbit:   { type: 'maxConcurrentSessions', threshold: 3 },
  goose:    { type: 'totalTimeMinutes', threshold: 1800 },
  capybara: { type: 'rateLimitHits', threshold: 10 },
  sloth:    { type: 'longSessions', threshold: 20 },
  owl:      { type: 'opusTimeMinutes', threshold: 600 },
  dragon:   { type: 'maxConcurrentAgents', threshold: 5 },
  unicorn:  { type: 'allUnlocked' },
};
```

- [ ] **Step 2: Add progress loading and saving functions**

Add these functions after `writeAtomicJson`:

```javascript
function defaultProgress() {
  return {
    stats: {
      totalSessions: 0,
      totalTimeMinutes: 0,
      totalTokens: 0,
      totalAgentRuns: 0,
      maxConcurrentSessions: 0,
      maxConcurrentAgents: 0,
      rateLimitHits: 0,
      longSessions: 0,
      opusTimeMinutes: 0,
    },
    unlocked: ['cat'],
    selectedPet: 'cat',
    unlockedAt: { cat: new Date().toISOString() },
  };
}

async function loadProgress() {
  const data = await readJsonSafe(PROGRESS_PATH);
  if (!data || !data.stats) return defaultProgress();
  return data;
}

async function writeProgressAtomic(progress) {
  const json = JSON.stringify(progress, null, 2) + '\n';
  await writeFile(PROGRESS_TMP, json, 'utf-8');
  await rename(PROGRESS_TMP, PROGRESS_PATH);
}
```

- [ ] **Step 3: Add seen-sessions tracker and stat update logic**

Add a module-level set and update function before the `tick()` function:

```javascript
const seenPids = new Set();
let lastRateLimitHigh = false;

function updateStats(progress, sessionDetails) {
  const stats = progress.stats;

  // Track new unique sessions
  for (const s of sessionDetails) {
    if (!seenPids.has(s.pid)) {
      seenPids.add(s.pid);
      stats.totalSessions++;
    }
  }

  // Cumulative time: sum all active session minutes (snapshot, not additive)
  // We track the max seen to avoid double-counting
  const totalActiveMinutes = sessionDetails.reduce((sum, s) => sum + s.sessionMinutes, 0);
  if (totalActiveMinutes > stats.totalTimeMinutes) {
    stats.totalTimeMinutes = totalActiveMinutes;
  }

  // Token estimation from context percent (rough: 200k context window)
  const totalTokensNow = sessionDetails.reduce((sum, s) => sum + Math.round(s.contextPercent / 100 * 200000), 0);
  if (totalTokensNow > stats.totalTokens) {
    stats.totalTokens = totalTokensNow;
  }

  // Agent runs
  const currentAgents = sessionDetails.reduce((sum, s) => sum + s.runningAgents, 0);
  stats.totalAgentRuns = Math.max(stats.totalAgentRuns, currentAgents);

  // Max concurrent sessions
  const currentSessions = sessionDetails.length;
  if (currentSessions > stats.maxConcurrentSessions) {
    stats.maxConcurrentSessions = currentSessions;
  }

  // Max concurrent agents
  if (currentAgents > stats.maxConcurrentAgents) {
    stats.maxConcurrentAgents = currentAgents;
  }

  // Long sessions (45+ min)
  const longNow = sessionDetails.filter(s => s.sessionMinutes >= 45).length;
  if (longNow > stats.longSessions) {
    stats.longSessions = longNow;
  }

  // Opus time
  const opusMinutes = sessionDetails
    .filter(s => s.model && s.model.toLowerCase().includes('opus'))
    .reduce((sum, s) => sum + s.sessionMinutes, 0);
  if (opusMinutes > stats.opusTimeMinutes) {
    stats.opusTimeMinutes = opusMinutes;
  }

  return stats;
}
```

- [ ] **Step 4: Add unlock checking logic**

```javascript
function checkUnlocks(progress) {
  const { stats, unlocked } = progress;
  let changed = false;

  for (const [petId, condition] of Object.entries(UNLOCK_CONDITIONS)) {
    if (unlocked.includes(petId)) continue;

    let met = false;
    if (condition.type === 'default') {
      met = true;
    } else if (condition.type === 'allUnlocked') {
      // Unicorn: all other pets must be unlocked
      const otherPets = Object.keys(UNLOCK_CONDITIONS).filter(id => id !== 'unicorn');
      met = otherPets.every(id => unlocked.includes(id));
    } else {
      met = (stats[condition.type] || 0) >= condition.threshold;
    }

    if (met) {
      unlocked.push(petId);
      progress.unlockedAt[petId] = new Date().toISOString();
      changed = true;
      process.stderr.write(`[pet-aggregator] unlocked: ${petId}\n`);
    }
  }

  return changed;
}
```

- [ ] **Step 5: Add rate limit hit tracking**

```javascript
function checkRateLimitHit(progress, rateLimit) {
  const fh = rateLimit.fiveHourPercent;
  if (fh != null && fh >= 80 && !lastRateLimitHigh) {
    progress.stats.rateLimitHits++;
    lastRateLimitHigh = true;
  } else if (fh == null || fh < 80) {
    lastRateLimitHigh = false;
  }
}
```

- [ ] **Step 6: Integrate progress tracking into tick()**

Replace the existing `tick()` function body. After the `petState` object is built (around line 131), before `writeAtomicJson(petState)`, add:

```javascript
    // --- Progress tracking ---
    const progress = await loadProgress();
    updateStats(progress, sessionDetails);
    checkRateLimitHit(progress, rateLimit);
    checkUnlocks(progress);
    await writeProgressAtomic(progress);
    // --- End progress tracking ---
```

- [ ] **Step 7: Verify aggregator runs without errors**

Run:
```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud
node pet/pet-aggregator.mjs &
sleep 5
cat ~/.claude/pet/progress.json
kill %1
```

Expected: progress.json exists with default stats and `"unlocked": ["cat"]`.

- [ ] **Step 8: Commit**

```bash
git add pet/pet-aggregator.mjs
git commit -m "feat(aggregator): add cumulative stats tracking and unlock system"
```

---

## Task 2: PetType Enum and MuscleStage

**Files:**
- Create: `pet/ClaudePet/Sources/PetType.swift`
- Modify: `pet/ClaudePet/Sources/PetStateMachine.swift`

- [ ] **Step 1: Create PetType.swift**

```swift
import Foundation

enum PetType: String, CaseIterable, Codable {
    case cat, hamster, chick, penguin, fox, rabbit
    case goose, capybara, sloth, owl, dragon, unicorn

    var displayName: String {
        switch self {
        case .cat:      return "Cat"
        case .hamster:  return "Hamster"
        case .chick:    return "Chick"
        case .penguin:  return "Penguin"
        case .fox:      return "Fox"
        case .rabbit:   return "Rabbit"
        case .goose:    return "Goose"
        case .capybara: return "Capybara"
        case .sloth:    return "Sloth"
        case .owl:      return "Owl"
        case .dragon:   return "Dragon"
        case .unicorn:  return "Unicorn"
        }
    }

    var unlockDescription: String {
        switch self {
        case .cat:      return "Default pet"
        case .hamster:  return "Total 10 sessions"
        case .chick:    return "5 hours total usage"
        case .penguin:  return "500K tokens used"
        case .fox:      return "50 agent runs"
        case .rabbit:   return "3+ concurrent sessions"
        case .goose:    return "30 hours total usage"
        case .capybara: return "10 rate limit hits"
        case .sloth:    return "20 long sessions (45m+)"
        case .owl:      return "10 hours on Opus"
        case .dragon:   return "5+ concurrent agents"
        case .unicorn:  return "Unlock all pets"
        }
    }
}

enum MuscleStage: Int, CaseIterable {
    case normal = 0
    case buff = 1
    case macho = 2

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .buff:   return "Buff"
        case .macho:  return "Macho!"
        }
    }

    static func resolve(agentCount: Int) -> MuscleStage {
        if agentCount >= 4 { return .macho }
        if agentCount >= 2 { return .buff }
        return .normal
    }
}
```

- [ ] **Step 2: Update PetStateMachine.swift**

Replace the entire file content:

```swift
import Foundation

enum PetState: Int, CaseIterable {
    case idle = 0
    case normal = 1
    case busy = 2
    case bloated = 3
    case stressed = 4
    case tired = 5
    case collab = 6

    var spriteRow: Int { rawValue }

    var frameInterval: TimeInterval {
        switch self {
        case .idle:     return 0.8
        case .normal:   return 0.2
        case .busy:     return 0.1
        case .bloated:  return 0.5
        case .stressed: return 0.15
        case .tired:    return 0.6
        case .collab:   return 0.2
        }
    }

    var displayName: String {
        switch self {
        case .idle:     return "Sleeping..."
        case .normal:   return "Walking happily"
        case .busy:     return "Working hard!"
        case .bloated:  return "Context is full..."
        case .stressed: return "Rate limit warning!"
        case .tired:    return "Getting tired..."
        case .collab:   return "Working together!"
        }
    }

    static func resolve(from data: PetStateData) -> PetState {
        guard data.activeSessions > 0 else { return .idle }
        let rl = data.rateLimit.fiveHourPercent ?? 0
        if rl >= 80 { return .stressed }
        if data.aggregate.maxContextPercent >= 70 { return .bloated }
        if data.aggregate.totalToolCalls > 50 { return .busy }
        if data.aggregate.totalRunningAgents > 1 { return .collab }
        if data.aggregate.longestSessionMinutes >= 45 { return .tired }
        return .normal
    }

    static func resolveMuscle(from data: PetStateData) -> MuscleStage {
        let agents = data.aggregate.totalRunningAgents
        return MuscleStage.resolve(agentCount: agents)
    }
}
```

- [ ] **Step 3: Verify it compiles**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/PetType.swift \
  Sources/PixelArtRenderer.swift \
  Sources/StatusMenuController.swift \
  -framework Cocoa -framework ServiceManagement
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add pet/ClaudePet/Sources/PetType.swift pet/ClaudePet/Sources/PetStateMachine.swift
git commit -m "feat: add PetType enum (12 pets) and MuscleStage system"
```

---

## Task 3: ProgressTracker and PetStateReader Update

**Files:**
- Create: `pet/ClaudePet/Sources/ProgressTracker.swift`
- Modify: `pet/ClaudePet/Sources/PetStateReader.swift`

- [ ] **Step 1: Create ProgressTracker.swift**

```swift
import Foundation

struct ProgressStats: Codable {
    var totalSessions: Int
    var totalTimeMinutes: Int
    var totalTokens: Int
    var totalAgentRuns: Int
    var maxConcurrentSessions: Int
    var maxConcurrentAgents: Int
    var rateLimitHits: Int
    var longSessions: Int
    var opusTimeMinutes: Int
}

struct ProgressData: Codable {
    var stats: ProgressStats
    var unlocked: [String]
    var selectedPet: String
    var unlockedAt: [String: String]
}

class ProgressTracker {
    private let filePath: String

    init() {
        filePath = NSHomeDirectory() + "/.claude/pet/progress.json"
    }

    func read() -> ProgressData? {
        guard let data = FileManager.default.contents(atPath: filePath) else { return nil }
        return try? JSONDecoder().decode(ProgressData.self, from: data)
    }

    func isUnlocked(_ pet: PetType) -> Bool {
        guard let progress = read() else { return pet == .cat }
        return progress.unlocked.contains(pet.rawValue)
    }

    func selectedPet() -> PetType {
        guard let progress = read(),
              let pet = PetType(rawValue: progress.selectedPet) else { return .cat }
        return pet
    }

    func selectPet(_ pet: PetType) {
        guard var progress = read() else { return }
        progress.selectedPet = pet.rawValue
        guard let data = try? JSONEncoder().encode(progress) else { return }
        let tmpPath = filePath + ".tmp"
        FileManager.default.createFile(atPath: tmpPath, contents: data)
        try? FileManager.default.moveItem(atPath: tmpPath, toPath: filePath)
    }

    func unlockProgress(for pet: PetType) -> (current: Int, target: Int)? {
        guard let progress = read() else { return nil }
        let stats = progress.stats

        switch pet {
        case .cat:      return nil // always unlocked
        case .hamster:  return (stats.totalSessions, 10)
        case .chick:    return (stats.totalTimeMinutes, 300)
        case .penguin:  return (stats.totalTokens, 500_000)
        case .fox:      return (stats.totalAgentRuns, 50)
        case .rabbit:   return (stats.maxConcurrentSessions, 3)
        case .goose:    return (stats.totalTimeMinutes, 1800)
        case .capybara: return (stats.rateLimitHits, 10)
        case .sloth:    return (stats.longSessions, 20)
        case .owl:      return (stats.opusTimeMinutes, 600)
        case .dragon:   return (stats.maxConcurrentAgents, 5)
        case .unicorn:
            let allPets = PetType.allCases.filter { $0 != .unicorn }
            let unlocked = allPets.filter { progress.unlocked.contains($0.rawValue) }.count
            return (unlocked, allPets.count)
        }
    }

    /// Returns the locked pet closest to being unlocked
    func nextUnlock() -> PetType? {
        guard let progress = read() else { return nil }
        var bestPet: PetType?
        var bestRatio: Double = -1

        for pet in PetType.allCases {
            guard !progress.unlocked.contains(pet.rawValue) else { continue }
            guard let (current, target) = unlockProgress(for: pet), target > 0 else { continue }
            let ratio = Double(current) / Double(target)
            if ratio > bestRatio {
                bestRatio = ratio
                bestPet = pet
            }
        }
        return bestPet
    }
}
```

- [ ] **Step 2: Update PetStateReader.swift — add progress reading**

Replace the entire file content:

```swift
import Foundation

struct RateLimitData: Codable {
    let fiveHourPercent: Double?
    let weeklyPercent: Double?
    let fiveHourResetsAt: String?
    let weeklyResetsAt: String?
}

struct AggregateData: Codable {
    let maxContextPercent: Double
    let totalToolCalls: Int
    let totalRunningAgents: Int
    let longestSessionMinutes: Int
    let dominantModel: String
}

struct SessionData: Codable {
    let pid: Int
    let project: String
    let model: String
    let contextPercent: Double
    let toolCalls: Int
    let runningAgents: Int
    let sessionMinutes: Int
}

struct PetStateData: Codable {
    let timestamp: Double
    let activeSessions: Int
    let rateLimit: RateLimitData
    let aggregate: AggregateData
    let sessions: [SessionData]
}

class PetStateReader {
    private let filePath: String

    init() {
        filePath = NSHomeDirectory() + "/.claude/pet/pet-state.json"
    }

    func read() -> PetStateData? {
        guard let data = FileManager.default.contents(atPath: filePath) else { return nil }
        return try? JSONDecoder().decode(PetStateData.self, from: data)
    }
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/PetType.swift \
  Sources/ProgressTracker.swift \
  Sources/PixelArtRenderer.swift \
  Sources/StatusMenuController.swift \
  -framework Cocoa -framework ServiceManagement
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add pet/ClaudePet/Sources/ProgressTracker.swift pet/ClaudePet/Sources/PetStateReader.swift
git commit -m "feat: add ProgressTracker for unlock conditions and progress reading"
```

---

## Task 4: Refactor PixelArtRenderer for Multi-Pet Support

**Files:**
- Modify: `pet/ClaudePet/Sources/PixelArtRenderer.swift`

This task strips the existing PixelArtRenderer down to just the rendering core. All cat sprite data moves to CatSprites.swift (Task 5). The renderer becomes a generic pixel-art-to-NSImage converter that can render any pet type at any muscle stage.

- [ ] **Step 1: Define SpriteProvider protocol and refactor PixelArtRenderer**

Replace the entire `PixelArtRenderer.swift` with:

```swift
import Cocoa

// MARK: - Shared Color Palette
// Each pet sprite file can define additional colors as needed
let CLR_CYAN    = UInt32(0xFF06B6D4)
let CLR_DCYAN   = UInt32(0xFF059BB0)
let CLR_WHITE   = UInt32(0xFFFFFFFF)
let CLR_BLACK   = UInt32(0xFF2D2D2D)
let CLR_PINK    = UInt32(0xFFF5A0B8)
let CLR_BLUSH   = UInt32(0xFFFFB8C8)
let CLR_OUTLINE = UInt32(0xFF4A6670)
let CLR_GOLD    = UInt32(0xFFF59E0B)
let CLR_PURPLE  = UInt32(0xFF7C3AED)
let CLR_SKYBLUE = UInt32(0xFF87CEEB)
let CLR_RED     = UInt32(0xFFFF4444)
let CLR_GRAY    = UInt32(0xFFAAAAAA)
let CLR_BROWN   = UInt32(0xFF8B5E3C)
let CLR_DBROWN  = UInt32(0xFF6B4226)
let CLR_ORANGE  = UInt32(0xFFFF8C42)
let CLR_DORANGE = UInt32(0xFFE06B20)
let CLR_YELLOW  = UInt32(0xFFFFD93D)
let CLR_GREEN   = UInt32(0xFF4CAF50)
let CLR_DGREEN  = UInt32(0xFF2E7D32)
let CLR_BEIGE   = UInt32(0xFFFFE0B2)
let CLR_DBEIGE  = UInt32(0xFFDDB892)
let CLR_LGRAY   = UInt32(0xFFCCCCCC)
let CLR_DGRAY   = UInt32(0xFF666666)
let CLR_NAVY    = UInt32(0xFF1A237E)
let CLR_CREAM   = UInt32(0xFFFFF8E1)
let CLR_DCREAM  = UInt32(0xFFFFE0A0)
let CLR_FIRE    = UInt32(0xFFFF5722)
let CLR_DFIRE   = UInt32(0xFFBF360C)
let CLR_RAINBOW1 = UInt32(0xFFFF6B6B)
let CLR_RAINBOW2 = UInt32(0xFFFFD93D)
let CLR_RAINBOW3 = UInt32(0xFF6BCB77)
let CLR_RAINBOW4 = UInt32(0xFF4D96FF)
let CLR_RAINBOW5 = UInt32(0xFFCC6BFF)

/// Protocol for pet sprite providers.
/// Each pet implements this to provide pixel art frames per behavior state and muscle stage.
protocol SpriteProvider {
    /// Returns 5 animation frames for the given behavior state and muscle stage.
    static func frames(state: PetState, muscle: MuscleStage) -> [[[UInt32?]]]
}

// MARK: - Pixel Art Renderer

struct PixelArtRenderer {
    static let pixelSize = 16  // 16x16 grid
    static let displayW: CGFloat = 18
    static let displayH: CGFloat = 18

    static func render(pixels: [[UInt32?]]) -> NSImage {
        let scale = 2 // @2x Retina
        let imgW = pixelSize * scale
        let imgH = pixelSize * scale

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: imgW, pixelsHigh: imgH,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: imgW * 4, bitsPerPixel: 32
        )!

        let ctx = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .none

        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: imgW, height: imgH).fill()

        for (y, row) in pixels.enumerated() {
            for (x, pixel) in row.enumerated() {
                guard let px = pixel else { continue }
                let r = CGFloat((px >> 16) & 0xFF) / 255.0
                let g = CGFloat((px >> 8) & 0xFF) / 255.0
                let b = CGFloat(px & 0xFF) / 255.0
                let a = CGFloat((px >> 24) & 0xFF) / 255.0
                NSColor(red: r, green: g, blue: b, alpha: a).setFill()
                let ry = (pixelSize - 1 - y) * scale
                NSRect(x: x * scale, y: ry, width: scale, height: scale).fill()
            }
        }

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: displayW, height: displayH))
        image.addRepresentation(rep)
        return image
    }

    /// Get the SpriteProvider for a given PetType
    static func spriteProvider(for pet: PetType) -> SpriteProvider.Type {
        switch pet {
        case .cat:      return CatSprites.self
        case .hamster:  return HamsterSprites.self
        case .chick:    return ChickSprites.self
        case .penguin:  return PenguinSprites.self
        case .fox:      return FoxSprites.self
        case .rabbit:   return RabbitSprites.self
        case .goose:    return GooseSprites.self
        case .capybara: return CapybaraSprites.self
        case .sloth:    return SlothSprites.self
        case .owl:      return OwlSprites.self
        case .dragon:   return DragonSprites.self
        case .unicorn:  return UnicornSprites.self
        }
    }

    /// Generate all rendered frames for a specific pet, muscle stage, and behavior state.
    static func renderedFrames(pet: PetType, muscle: MuscleStage, state: PetState) -> [NSImage] {
        let provider = spriteProvider(for: pet)
        let pixelFrames = provider.frames(state: state, muscle: muscle)
        return pixelFrames.map { render(pixels: $0) }
    }

    /// Pre-render all frames for a specific pet type and muscle stage (all behavior states).
    static func allFrames(pet: PetType, muscle: MuscleStage) -> [PetState: [NSImage]] {
        var result: [PetState: [NSImage]] = [:]
        for state in PetState.allCases {
            result[state] = renderedFrames(pet: pet, muscle: muscle, state: state)
        }
        return result
    }

    /// Render a combined menu bar image with main pet + friend pets side by side.
    /// Used for the friend system: multiple sessions = friend pets appear.
    static func renderMenuBarImage(
        mainPet: PetType, muscle: MuscleStage, state: PetState, frameIndex: Int,
        friendPets: [PetType]
    ) -> NSImage {
        let mainProvider = spriteProvider(for: mainPet)
        let mainFrames = mainProvider.frames(state: state, muscle: muscle)
        let mainIdx = frameIndex % max(1, mainFrames.count)

        // If no friends, return single pet image
        if friendPets.isEmpty {
            return render(pixels: mainFrames[mainIdx])
        }

        // Combine: main pet + up to 2 friends, each 16px wide with 2px gap
        let petCount = 1 + min(friendPets.count, 2)
        let totalW = petCount * pixelSize + (petCount - 1) * 2
        let scale = 2
        let imgW = totalW * scale
        let imgH = pixelSize * scale

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: imgW, pixelsHigh: imgH,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: imgW * 4, bitsPerPixel: 32
        )!

        let ctx = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .none

        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: imgW, height: imgH).fill()

        // Helper to draw one pet at xOffset
        func drawPet(pixels: [[UInt32?]], xOffset: Int) {
            for (y, row) in pixels.enumerated() {
                for (x, pixel) in row.enumerated() {
                    guard let px = pixel else { continue }
                    let r = CGFloat((px >> 16) & 0xFF) / 255.0
                    let g = CGFloat((px >> 8) & 0xFF) / 255.0
                    let b = CGFloat(px & 0xFF) / 255.0
                    let a = CGFloat((px >> 24) & 0xFF) / 255.0
                    NSColor(red: r, green: g, blue: b, alpha: a).setFill()
                    let ry = (pixelSize - 1 - y) * scale
                    NSRect(x: (xOffset + x) * scale, y: ry, width: scale, height: scale).fill()
                }
            }
        }

        // Draw main pet
        drawPet(pixels: mainFrames[mainIdx], xOffset: 0)

        // Draw friend pets (normal muscle, normal state)
        for (i, friend) in friendPets.prefix(2).enumerated() {
            let friendProvider = spriteProvider(for: friend)
            let friendFrames = friendProvider.frames(state: .normal, muscle: .normal)
            let fi = frameIndex % max(1, friendFrames.count)
            let xOff = (i + 1) * (pixelSize + 2)
            drawPet(pixels: friendFrames[fi], xOffset: xOff)
        }

        NSGraphicsContext.restoreGraphicsState()

        let displayW = CGFloat(totalW) * displayW / CGFloat(pixelSize)
        let image = NSImage(size: NSSize(width: displayW, height: displayH))
        image.addRepresentation(rep)
        return image
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/PixelArtRenderer.swift
git commit -m "refactor: extract PixelArtRenderer core, add SpriteProvider protocol"
```

Note: This will NOT compile until at least CatSprites.swift exists (Task 5).

---

## Task 5: Cat Sprites (Normal / Buff / Macho)

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/CatSprites.swift`

This task moves the existing cat pixel art to the new sprite system and adds Buff and Macho variants. The cat is the template — all subsequent pets follow this pattern.

**Design intent:**
- **Normal**: Existing v1 cat (cyan body, pink nose, teal outline)
- **Buff**: Wider shoulders, slightly thicker arms, chest puffs out 1-2px
- **Macho**: Absurdly wide shoulders, huge arms, tiny head by comparison, sparkle effects, golden highlights

Each muscle stage provides frames for ALL 7 PetState behavior states. For Buff/Macho, the idle/normal/collab frames are redesigned with bigger body. The busy/bloated/stressed/tired overlays (sweat, red marks, puffiness) are adapted to the larger body shape.

- [ ] **Step 1: Create Sprites directory and CatSprites.swift**

```bash
mkdir -p pet/ClaudePet/Sources/Sprites
```

Create `pet/ClaudePet/Sources/Sprites/CatSprites.swift`. This file must contain all 7 states × 3 muscle stages × 5 frames = 105 frame arrays. The structure:

```swift
import Foundation

// Cat color aliases (matching v1 palette)
private let C = CLR_CYAN
private let D = CLR_DCYAN
private let W = CLR_WHITE
private let B = CLR_BLACK
private let P = CLR_PINK
private let K = CLR_BLUSH
private let O = CLR_OUTLINE
private let Y = CLR_GOLD
private let G = CLR_PURPLE
private let S = CLR_SKYBLUE
private let R = CLR_RED
private let Z = CLR_GRAY
private let T: UInt32? = nil

struct CatSprites: SpriteProvider {
    static func frames(state: PetState, muscle: MuscleStage) -> [[[UInt32?]]] {
        switch muscle {
        case .normal: return normalFrames(state: state)
        case .buff:   return buffFrames(state: state)
        case .macho:  return machoFrames(state: state)
        }
    }

    private static func normalFrames(state: PetState) -> [[[UInt32?]]] {
        switch state {
        case .idle:     return catNormalIdle
        case .normal:   return catNormalWalk
        case .busy:     return catNormalBusy
        case .bloated:  return catNormalBloated
        case .stressed: return catNormalStressed
        case .tired:    return catNormalTired
        case .collab:   return catNormalCollab
        }
    }

    private static func buffFrames(state: PetState) -> [[[UInt32?]]] {
        switch state {
        case .idle:     return catBuffIdle
        case .normal:   return catBuffWalk
        case .busy:     return catBuffBusy
        case .bloated:  return catBuffBloated
        case .stressed: return catBuffStressed
        case .tired:    return catBuffTired
        case .collab:   return catBuffCollab
        }
    }

    private static func machoFrames(state: PetState) -> [[[UInt32?]]] {
        switch state {
        case .idle:     return catMachoIdle
        case .normal:   return catMachoWalk
        case .busy:     return catMachoBusy
        case .bloated:  return catMachoBloated
        case .stressed: return catMachoStressed
        case .tired:    return catMachoTired
        case .collab:   return catMachoCollab
        }
    }
}

// MARK: - Cat Normal (copy from existing v1 PixelArtRenderer.swift idleFrames, normalFrames, etc.)
// Copy ALL existing frame arrays from the current PixelArtRenderer.swift here, renamed:
// idleFrames    → catNormalIdle
// normalFrames  → catNormalWalk
// busyFrames    → catNormalBusy
// bloatedFrames → catNormalBloated
// stressedFrames → catNormalStressed
// tiredFrames   → catNormalTired
// collabFrames  → catNormalCollab
```

Copy the existing 7 frame arrays from the current `PixelArtRenderer.swift` (lines 93-783) into this file, renaming them as shown above. These are the `catNormal*` arrays.

- [ ] **Step 2: Add Buff stage frames**

Add Buff variants after the Normal frames. Buff cat has wider shoulders (+1px each side), slightly thicker body. For the idle state, the sleeping ball is bigger. For walking states, arms are thicker and shoulders wider.

Example — `catBuffIdle` (5 frames, showing frame 0 pattern):

```swift
// MARK: - Cat Buff
// Buff cat: wider shoulders, thicker body, slight muscle definition
// Body is ~2px wider than normal. Head stays same size for comedic proportion.

private let catBuffIdle: [[[UInt32?]]] = [
    // Frame 0: curled sleeping buff cat — bigger ball
    [
        [T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,Z,T,T,T,T,T,T],
        [T,T,O,T,T,T,T,T,T,O,T,T,T,T,T,T],
        [T,O,C,O,T,T,T,T,O,C,O,T,T,T,T,T],
        [O,C,C,C,O,O,O,O,C,C,C,O,T,T,T,T],
        [O,C,C,C,C,C,C,C,C,C,C,O,T,T,T,T],
        [O,C,O,O,C,C,C,O,O,C,C,O,T,T,T,T],
        [O,C,C,C,P,P,C,C,C,C,C,O,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,O,O,O,O,O,O,O,O,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // ... frames 1-4 follow same pattern with breathing/Zzz animation
]
```

Create all 7 state arrays for Buff: `catBuffIdle`, `catBuffWalk`, `catBuffBusy`, `catBuffBloated`, `catBuffStressed`, `catBuffTired`, `catBuffCollab`. Each array has 5 frames. Key visual differences from Normal:
- Body 1-2px wider on each side
- Shoulders more defined (extra pixels on upper arms)
- Legs slightly thicker
- Head stays same small size

- [ ] **Step 3: Add Macho stage frames**

Macho cat is absurdly muscular — comically oversized body with tiny head. Uses `Y` (gold) sparkle pixels around the body.

Example — `catMachoWalk` frame 0 pattern:

```swift
// MARK: - Cat Macho
// Macho cat: absurd bodybuilder. Tiny head, massive torso, huge arms.
// Gold sparkle pixels (Y) appear around body for "glowing" effect.

private let catMachoIdle: [[[UInt32?]]] = [
    // Frame 0: even macho cats need sleep — huge curled ball with sparkles
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,Y,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,O,O,C,C,O,O,C,O,T,T,T,T,T],
        [T,O,C,C,P,P,C,C,C,C,O,T,T,T,T,T],
        [Y,O,D,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,Y,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,O,O,O,O,O,O,O,O,O,O,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // ... frames 1-4
]
```

Create all 7 state arrays for Macho: `catMachoIdle`, `catMachoWalk`, `catMachoBusy`, `catMachoBloated`, `catMachoStressed`, `catMachoTired`, `catMachoCollab`. Key visual differences:
- Body takes up most of the 16x16 grid
- Head is only 3-4px wide (comically tiny)
- Arms are 3px thick with muscle bulge pixels
- Gold sparkle pixels (`Y`) appear at corners, rotating through frames
- Walking animation shows exaggerated arm swinging

- [ ] **Step 4: Verify compilation with CatSprites**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/PetType.swift \
  Sources/ProgressTracker.swift \
  Sources/PixelArtRenderer.swift \
  Sources/Sprites/CatSprites.swift \
  Sources/StatusMenuController.swift \
  -framework Cocoa -framework ServiceManagement
```

- [ ] **Step 5: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/CatSprites.swift
git commit -m "feat: add Cat sprites with Normal/Buff/Macho muscle stages"
```

---

## Task 6: Hamster Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/HamsterSprites.swift`

**Design:**
- **Colors**: Brown body (`CLR_BROWN`/`CLR_DBROWN`), cream belly (`CLR_CREAM`), pink nose, black eyes
- **Normal**: Round chubby hamster with stubby legs, big cheeks
- **Buff**: Cheeks even bigger, arms defined, broader shoulders
- **Macho**: Exploding muscles but still has those adorable round cheeks, gold sparkles

Structure follows CatSprites exactly — `struct HamsterSprites: SpriteProvider` with `frames(state:muscle:)` dispatching to 21 frame arrays (7 states × 3 muscles × 5 frames each).

- [ ] **Step 1: Create HamsterSprites.swift**

Create `pet/ClaudePet/Sources/Sprites/HamsterSprites.swift` following the CatSprites pattern. Define color aliases:

```swift
import Foundation

private let M = CLR_BROWN    // Main body
private let N = CLR_DBROWN   // Body shading
private let E = CLR_CREAM    // Belly/cheeks
private let F = CLR_DCREAM   // Belly shading
private let B = CLR_BLACK    // Eyes
private let P = CLR_PINK     // Nose
private let K = CLR_BLUSH    // Inner ears
private let O = CLR_DBROWN   // Outline
private let Y = CLR_GOLD     // Macho sparkle
private let T: UInt32? = nil
```

Implement all 21 frame arrays with 5 frames each. The hamster should feel distinctly different from the cat — rounder, chubbier, with prominent cheeks that puff out especially when buff/macho.

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck \
  Sources/main.swift Sources/AppDelegate.swift Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift Sources/PetType.swift Sources/ProgressTracker.swift \
  Sources/PixelArtRenderer.swift Sources/Sprites/CatSprites.swift \
  Sources/Sprites/HamsterSprites.swift Sources/StatusMenuController.swift \
  -framework Cocoa -framework ServiceManagement
```

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/HamsterSprites.swift
git commit -m "feat: add Hamster sprites with Normal/Buff/Macho stages"
```

---

## Task 7: Chick Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/ChickSprites.swift`

**Design:**
- **Colors**: Yellow body (`CLR_YELLOW`), orange beak (`CLR_ORANGE`), black eyes, pink blush
- **Normal**: Tiny round chick, almost all head, tiny wings
- **Buff**: Wings become visible arms, chest widens
- **Macho**: Absurdly buff tiny bird, huge pecs, tiny beak on massive body

Follow CatSprites pattern exactly. `struct ChickSprites: SpriteProvider`.

- [ ] **Step 1: Create ChickSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/ChickSprites.swift
git commit -m "feat: add Chick sprites with Normal/Buff/Macho stages"
```

---

## Task 8: Penguin Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/PenguinSprites.swift`

**Design:**
- **Colors**: Black/dark gray body (`CLR_BLACK`/`CLR_DGRAY`), white belly (`CLR_WHITE`), orange feet/beak (`CLR_ORANGE`), blue scarf accent (`CLR_SKYBLUE`)
- **Normal**: Classic tuxedo penguin, waddle animation
- **Buff**: Broader chest, defined pecs visible through white belly
- **Macho**: Huge penguin with tiny wings turned to massive arms, still has adorable waddle

- [ ] **Step 1: Create PenguinSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/PenguinSprites.swift
git commit -m "feat: add Penguin sprites with Normal/Buff/Macho stages"
```

---

## Task 9: Fox Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/FoxSprites.swift`

**Design:**
- **Colors**: Orange body (`CLR_ORANGE`/`CLR_DORANGE`), white chest/tail-tip (`CLR_WHITE`), black legs/ears (`CLR_BLACK`), amber eyes
- **Normal**: Sly-looking fox with big fluffy tail
- **Buff**: Tail gets even fluffier, shoulders broaden
- **Macho**: Massive foxzilla with enormous fluffy tail, gold sparkles

- [ ] **Step 1: Create FoxSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/FoxSprites.swift
git commit -m "feat: add Fox sprites with Normal/Buff/Macho stages"
```

---

## Task 10: Rabbit Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/RabbitSprites.swift`

**Design:**
- **Colors**: White body (`CLR_WHITE`/`CLR_LGRAY`), pink inner ears (`CLR_PINK`), black eyes, pink nose
- **Normal**: Cute bunny with tall ears, hop animation
- **Buff**: Ears get buffer (thicker), body wider, legs more defined
- **Macho**: Absolutely jacked rabbit, ears are like muscular antennae, hop animation with impact lines

- [ ] **Step 1: Create RabbitSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/RabbitSprites.swift
git commit -m "feat: add Rabbit sprites with Normal/Buff/Macho stages"
```

---

## Task 11: Goose Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/GooseSprites.swift`

**Design:**
- **Colors**: White body (`CLR_WHITE`/`CLR_LGRAY`), orange beak/feet (`CLR_ORANGE`), black eyes
- **Normal**: Tall goose with long neck, slightly menacing expression (Untitled Goose Game energy)
- **Buff**: Neck thickens, chest puffs out, more intimidating
- **Macho**: Absolute unit goose, neck like a tree trunk, wings turned to massive arms

- [ ] **Step 1: Create GooseSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/GooseSprites.swift
git commit -m "feat: add Goose sprites with Normal/Buff/Macho stages"
```

---

## Task 12: Capybara Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/CapybaraSprites.swift`

**Design:**
- **Colors**: Brown body (`CLR_BROWN`/`CLR_DBROWN`), beige belly (`CLR_BEIGE`), black nose/eyes, pink ears
- **Normal**: Chill capybara with relaxed expression, flat top head
- **Buff**: Still looks relaxed but with visible muscles, zen energy
- **Macho**: Jacked but STILL looks totally unbothered, gold sparkles don't phase it

- [ ] **Step 1: Create CapybaraSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/CapybaraSprites.swift
git commit -m "feat: add Capybara sprites with Normal/Buff/Macho stages"
```

---

## Task 13: Sloth Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/SlothSprites.swift`

**Design:**
- **Colors**: Dark brown body (`CLR_DBROWN`), beige face (`CLR_BEIGE`), black eye patches, cream claws
- **Normal**: Hanging/slow sloth with droopy eyes and long arms, very slow animation
- **Buff**: Arms get thick (perfect for hanging), body fills out
- **Macho**: Absurdly jacked sloth that still moves at the same glacial pace, ironic muscle mass

- [ ] **Step 1: Create SlothSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/SlothSprites.swift
git commit -m "feat: add Sloth sprites with Normal/Buff/Macho stages"
```

---

## Task 14: Owl Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/OwlSprites.swift`

**Design:**
- **Colors**: Navy/dark blue body (`CLR_NAVY`/`CLR_DGRAY`), golden eyes (`CLR_GOLD`), cream chest (`CLR_CREAM`), purple accents (`CLR_PURPLE`)
- **Normal**: Wise owl with big round eyes, slight head-bob animation
- **Buff**: Puffed up chest, wings show muscle definition
- **Macho**: Absolutely enormous owl, wings are massive arms, eyes still wise but body says gym

- [ ] **Step 1: Create OwlSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/OwlSprites.swift
git commit -m "feat: add Owl sprites with Normal/Buff/Macho stages"
```

---

## Task 15: Dragon Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/DragonSprites.swift`

**Design:**
- **Colors**: Fire orange/red body (`CLR_FIRE`/`CLR_DFIRE`), golden belly (`CLR_GOLD`), green wing membranes (`CLR_GREEN`), yellow eyes
- **Normal**: Small cute dragon with tiny wings, flame flicker animation
- **Buff**: Wings grow larger, body gets stocky, more flame
- **Macho**: Epic dragon filling most of the 16x16, massive wings, fire breath effect pixels

- [ ] **Step 1: Create DragonSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/DragonSprites.swift
git commit -m "feat: add Dragon sprites with Normal/Buff/Macho stages"
```

---

## Task 16: Unicorn Sprites

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/UnicornSprites.swift`

**Design:**
- **Colors**: White body (`CLR_WHITE`), rainbow mane using `CLR_RAINBOW1-5`, golden horn (`CLR_GOLD`), pink nose
- **Normal**: Graceful unicorn with flowing rainbow mane, sparkle animation
- **Buff**: More muscular horse body, mane gets more vibrant
- **Macho**: Absolute unit of a unicorn, rainbow sparkles everywhere, horn radiates gold light

- [ ] **Step 1: Create UnicornSprites.swift with all 21 frame arrays**
- [ ] **Step 2: Verify compilation**
- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/UnicornSprites.swift
git commit -m "feat: add Unicorn sprites with Normal/Buff/Macho stages"
```

---

## Task 17: NotificationManager

**Files:**
- Create: `pet/ClaudePet/Sources/NotificationManager.swift`

- [ ] **Step 1: Create NotificationManager.swift**

```swift
import Cocoa
import UserNotifications

class NotificationManager {
    private var lastNotificationTime: Date?
    private let cooldownSeconds: TimeInterval = 300 // 5 minutes

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkAndNotify(rateLimit: RateLimitData) {
        guard let percent = rateLimit.fiveHourPercent, percent >= 80 else { return }

        // Dedup: don't send again within 5 minutes
        if let last = lastNotificationTime,
           Date().timeIntervalSince(last) < cooldownSeconds {
            return
        }

        sendNotification(percent: percent)
        lastNotificationTime = Date()
    }

    private func sendNotification(percent: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Pet - Rate Limit Warning"
        content.body = "5-hour rate limit at \(Int(percent))%. Consider taking a break!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "rate-limit-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil // immediate
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck \
  Sources/NotificationManager.swift \
  -framework Cocoa -framework UserNotifications
```

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/NotificationManager.swift
git commit -m "feat: add NotificationManager for rate limit alerts"
```

---

## Task 18: SwiftUI CollectionView

**Files:**
- Create: `pet/ClaudePet/Sources/CollectionView.swift`

This is the SwiftUI popover UI showing the pet grid, unlock progress, and pet selection.

- [ ] **Step 1: Create CollectionView.swift**

```swift
import SwiftUI

// MARK: - Data bridge from AppKit to SwiftUI
class PetViewModel: ObservableObject {
    @Published var currentState: PetState = .idle
    @Published var muscleStage: MuscleStage = .normal
    @Published var activeSessions: Int = 0
    @Published var activeAgents: Int = 0
    @Published var unlockedPets: [PetType] = [.cat]
    @Published var selectedPet: PetType = .cat
    @Published var nextUnlockPet: PetType?
    @Published var nextUnlockCurrent: Int = 0
    @Published var nextUnlockTarget: Int = 1

    private let progressTracker = ProgressTracker()

    func refresh(stateData: PetStateData?) {
        if let data = stateData {
            currentState = PetState.resolve(from: data)
            muscleStage = PetState.resolveMuscle(from: data)
            activeSessions = data.activeSessions
            activeAgents = data.aggregate.totalRunningAgents
        } else {
            currentState = .idle
            muscleStage = .normal
            activeSessions = 0
            activeAgents = 0
        }

        if let progress = progressTracker.read() {
            unlockedPets = PetType.allCases.filter { progress.unlocked.contains($0.rawValue) }
            selectedPet = PetType(rawValue: progress.selectedPet) ?? .cat
        }

        if let next = progressTracker.nextUnlock(),
           let (current, target) = progressTracker.unlockProgress(for: next) {
            nextUnlockPet = next
            nextUnlockCurrent = current
            nextUnlockTarget = target
        } else {
            nextUnlockPet = nil
        }
    }

    func selectPet(_ pet: PetType) {
        guard unlockedPets.contains(pet) else { return }
        selectedPet = pet
        progressTracker.selectPet(pet)
    }
}

// MARK: - Main Popover View
struct CollectionPopoverView: View {
    @ObservedObject var viewModel: PetViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            petGridSection
            if viewModel.nextUnlockPet != nil {
                Divider()
                progressSection
            }
            Divider()
            quitSection
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                // Pet pixel art would be rendered as NSImage and shown here
                Text(viewModel.selectedPet.displayName)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(viewModel.muscleStage.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.muscleStage == .macho ? .yellow : .secondary)
            }
            HStack {
                Text("Sessions: \(viewModel.activeSessions)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Agents: \(viewModel.activeAgents)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }

    // MARK: - Pet Grid
    private var petGridSection: some View {
        let columns = Array(repeating: GridItem(.fixed(56), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(PetType.allCases, id: \.self) { pet in
                PetGridCell(
                    pet: pet,
                    isUnlocked: viewModel.unlockedPets.contains(pet),
                    isSelected: viewModel.selectedPet == pet,
                    onSelect: { viewModel.selectPet(pet) }
                )
            }
        }
        .padding(12)
    }

    // MARK: - Progress
    private var progressSection: some View {
        VStack(spacing: 4) {
            if let pet = viewModel.nextUnlockPet {
                HStack {
                    Text("\(pet.displayName)")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text("\(viewModel.nextUnlockCurrent)/\(viewModel.nextUnlockTarget)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                ProgressView(
                    value: Double(viewModel.nextUnlockCurrent),
                    total: Double(max(1, viewModel.nextUnlockTarget))
                )
                .tint(.cyan)
                Text(pet.unlockDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }

    // MARK: - Quit
    private var quitSection: some View {
        HStack {
            Spacer()
            Button("Quit Claude Pet") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            Spacer()
        }
        .padding(8)
    }
}

// MARK: - Pet Grid Cell
struct PetGridCell: View {
    let pet: PetType
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: { if isUnlocked { onSelect() } }) {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.cyan.opacity(0.2) : Color.clear)
                        .frame(width: 48, height: 48)

                    if isUnlocked {
                        // Render actual pixel art NSImage here via NSViewRepresentable
                        PetPixelView(pet: pet, muscle: .normal)
                            .frame(width: 36, height: 36)
                    } else {
                        // Locked silhouette
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                )

                Text(isUnlocked ? pet.displayName : "???")
                    .font(.system(size: 9))
                    .foregroundColor(isUnlocked ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .help(isUnlocked ? pet.displayName : pet.unlockDescription)
    }
}

// MARK: - NSImage to SwiftUI bridge
struct PetPixelView: NSViewRepresentable {
    let pet: PetType
    let muscle: MuscleStage

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        let frames = PixelArtRenderer.renderedFrames(pet: pet, muscle: muscle, state: .normal)
        imageView.image = frames.first
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        let frames = PixelArtRenderer.renderedFrames(pet: pet, muscle: muscle, state: .normal)
        nsView.image = frames.first
    }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet
swiftc -typecheck \
  Sources/CollectionView.swift Sources/PetType.swift Sources/PetStateMachine.swift \
  Sources/PetStateReader.swift Sources/ProgressTracker.swift Sources/PixelArtRenderer.swift \
  Sources/Sprites/CatSprites.swift \
  -framework Cocoa -framework SwiftUI
```

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/CollectionView.swift
git commit -m "feat: add SwiftUI CollectionView for pet grid and unlock progress"
```

---

## Task 19: Rewrite StatusMenuController with NSPopover

**Files:**
- Modify: `pet/ClaudePet/Sources/StatusMenuController.swift`

Replace the NSMenu-based controller with NSPopover hosting the SwiftUI CollectionView.

- [ ] **Step 1: Replace StatusMenuController.swift**

```swift
import Cocoa
import SwiftUI

class StatusMenuController {
    let viewModel = PetViewModel()
    private var popover: NSPopover?

    func setupPopover() -> NSPopover {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: CollectionPopoverView(viewModel: viewModel)
        )
        self.popover = popover
        return popover
    }

    func togglePopover(relativeTo button: NSStatusBarButton) {
        guard let popover = popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Ensure popover closes when user clicks elsewhere
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func updateState(_ stateData: PetStateData?) {
        viewModel.refresh(stateData: stateData)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/StatusMenuController.swift
git commit -m "feat: replace NSMenu with NSPopover + SwiftUI collection UI"
```

---

## Task 20: Update AppDelegate for v2

**Files:**
- Modify: `pet/ClaudePet/Sources/AppDelegate.swift`

Wire up the new popover, multi-pet rendering, muscle stages, notifications, and friend pets in the menu bar.

- [ ] **Step 1: Replace AppDelegate.swift**

```swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var currentState: PetState = .idle
    private var currentMuscle: MuscleStage = .normal
    private var currentPet: PetType = .cat
    private var friendPets: [PetType] = []
    private var frameIndex = 0
    private var currentFrames: [NSImage] = []
    private var activeSessions: Int = 0
    private var stateReader = PetStateReader()
    private var progressTracker = ProgressTracker()
    private var menuController: StatusMenuController!
    private var notificationManager = NotificationManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationManager.requestPermission()

        // Load selected pet from progress
        currentPet = progressTracker.selectedPet()

        menuController = StatusMenuController()
        let popover = menuController.setupPopover()

        setupStatusItem()
        startStatePolling()
        reloadFramesAndAnimate()

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleep),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            // Remove menu so click triggers action instead
            statusItem.menu = nil
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        menuController.togglePopover(relativeTo: button)
    }

    private func startStatePolling() {
        stateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.pollState()
        }
    }

    private func pollState() {
        let data = stateReader.read()

        let newState: PetState
        let newMuscle: MuscleStage
        if let data = data {
            newState = PetState.resolve(from: data)
            newMuscle = PetState.resolveMuscle(from: data)
            notificationManager.checkAndNotify(rateLimit: data.rateLimit)
        } else {
            newState = .idle
            newMuscle = .normal
        }

        // Check if selected pet changed
        let newPet = progressTracker.selectedPet()
        let newSessions = data?.activeSessions ?? 0

        // Determine friend pets based on session count
        var newFriends: [PetType] = []
        if newSessions >= 2, let progress = progressTracker.read() {
            let unlocked = PetType.allCases.filter {
                $0 != newPet && progress.unlocked.contains($0.rawValue)
            }
            // Pick most recently unlocked friends
            let sorted = unlocked.sorted { a, b in
                let aDate = progress.unlockedAt[a.rawValue] ?? ""
                let bDate = progress.unlockedAt[b.rawValue] ?? ""
                return aDate > bDate
            }
            let friendCount = min(newSessions - 1, 2)
            newFriends = Array(sorted.prefix(friendCount))
        }

        let needsReload = (newState != currentState)
                       || (newMuscle != currentMuscle)
                       || (newPet != currentPet)
                       || (newFriends != friendPets)

        currentState = newState
        currentMuscle = newMuscle
        currentPet = newPet
        friendPets = newFriends
        activeSessions = newSessions

        if needsReload {
            frameIndex = 0
            reloadFramesAndAnimate()
        }

        menuController.updateState(data)
    }

    private func reloadFramesAndAnimate() {
        if friendPets.isEmpty {
            currentFrames = PixelArtRenderer.renderedFrames(
                pet: currentPet,
                muscle: currentMuscle,
                state: currentState
            )
        } else {
            // Pre-render combined frames (main + friends)
            let provider = PixelArtRenderer.spriteProvider(for: currentPet)
            let mainFrames = provider.frames(state: currentState, muscle: currentMuscle)
            currentFrames = (0..<mainFrames.count).map { i in
                PixelArtRenderer.renderMenuBarImage(
                    mainPet: currentPet, muscle: currentMuscle,
                    state: currentState, frameIndex: i,
                    friendPets: friendPets
                )
            }
        }
        if let first = currentFrames.first {
            statusItem.button?.image = first
        }

        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(
            timeInterval: currentState.frameInterval,
            target: self,
            selector: #selector(nextFrame),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(frameTimer!, forMode: .common)
    }

    @objc private func nextFrame() {
        guard !currentFrames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % currentFrames.count
        statusItem.button?.image = currentFrames[frameIndex]
    }

    @objc private func onSleep() {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
    }

    @objc private func onWake() {
        startStatePolling()
        reloadFramesAndAnimate()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/AppDelegate.swift
git commit -m "feat: update AppDelegate for v2 — popover, multi-pet, muscle, notifications"
```

---

## Task 21: Update install.sh Build Command

**Files:**
- Modify: `pet/install.sh`

- [ ] **Step 1: Update the swiftc command to include all new source files**

Replace the swiftc block (lines 43-52) with:

```bash
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
```

- [ ] **Step 2: Build and test**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud
./pet/install.sh
```

Expected: Build succeeds, app launches, menu bar shows selected pet with pixel art animation.

- [ ] **Step 3: Commit**

```bash
git add pet/install.sh
git commit -m "feat: update install.sh with all v2 source files and frameworks"
```

---

## Task 22: README Badge Generator

**Files:**
- Create: `pet/generate-badge.mjs`

Node.js CLI script that reads `progress.json` and outputs an SVG badge to stdout.

- [ ] **Step 1: Create generate-badge.mjs**

```javascript
#!/usr/bin/env node

/**
 * generate-badge.mjs
 *
 * Reads ~/.claude/pet/progress.json and generates an SVG badge
 * showing the selected pet, muscle stage, and unlock count.
 *
 * Usage: node pet/generate-badge.mjs > docs/pet-badge.svg
 */

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const PROGRESS_PATH = join(homedir(), '.claude', 'pet', 'progress.json');

function loadProgress() {
  try {
    return JSON.parse(readFileSync(PROGRESS_PATH, 'utf-8'));
  } catch {
    return {
      stats: { totalSessions: 0, totalTimeMinutes: 0 },
      unlocked: ['cat'],
      selectedPet: 'cat',
    };
  }
}

// Simple 8x8 pixel art representations for SVG (scaled up)
const PET_PIXELS = {
  cat: [
    '..OO..OO',
    '.OCCCCCO',
    '.CCOOCCC',
    '.CCCPPCC',
    '..CCCCC.',
    '.DDDDDDD',
    '.DDDDDDD',
    '..OOOOO.',
  ],
  hamster: [
    '..MMMM..',
    '.MMEEMM.',
    'MMEBBEMM',
    'MMEEPEEMM',
    '.MEEEEEM.',
    '..NNNN..',
    '.NNNNNN.',
    '..OOOO..',
  ],
  chick: [
    '...YY...',
    '..YYYY..',
    '.YBYBYY.',
    '.YYOOYY.',
    '..YYYY..',
    '..YYYY..',
    '...OO...',
    '..O..O..',
  ],
  penguin: [
    '..BBBB..',
    '.BBWWBB.',
    '.BWBWWB.',
    '.BWWWWB.',
    '.BBWWBB.',
    '..BWWB..',
    '..BWWB..',
    '..OO.OO.',
  ],
  fox: [
    '.OO..OO.',
    'OOOOOOOO',
    'OWOBBOW0',
    'OOWWWWOO',
    '.OOWWOO.',
    '..OOOO..',
    '.OOOOOO.',
    'OO....OW',
  ],
  rabbit: [
    '.WW..WW.',
    '.WW..WW.',
    '.WWWWWW.',
    'WWBWWBWW',
    'WWWWPWWW',
    '.WWWWWW.',
    '..WWWW..',
    '..WW.WW.',
  ],
  goose: [
    '...WW...',
    '..WWWW..',
    '.WBWWBW.',
    '..OOOO..',
    '...WW...',
    '..WWWW..',
    '.WWWWWW.',
    '..OO.OO.',
  ],
  capybara: [
    '.MMMMMM.',
    'MMMBMMM.',
    'MMBBMMM.',
    'MMMPMMM.',
    '.EEEEEE.',
    '.EEEEEE.',
    '.NNNNNN.',
    '.NN..NN.',
  ],
  sloth: [
    '..NNNN..',
    '.NEENNE.',
    'NEBBEEN.',
    '.NEEPEN.',
    '..NNNN..',
    '.NNNNNN.',
    'NNNNNNNN',
    '.NN..NN.',
  ],
  owl: [
    '..GGGG..',
    '.GYYGYG.',
    'GYBGBYGG',
    '.GGOGG..',
    '..GGGG..',
    '.EEEEEE.',
    '.GGGGGG.',
    '..GG.GG.',
  ],
  dragon: [
    '.RR..RR.',
    'RRRRRRRR',
    'RRBRRBRR',
    'RRRYYRRR',
    '.RYYYR..',
    'GRRRRRRG',
    '.RRRRRR.',
    '.RR..RR.',
  ],
  unicorn: [
    '...Y....',
    '..YY....',
    '.WWWWW..',
    'WWBWWBW.',
    'WWWPWWW.',
    '.WWWWW..',
    'RWYWGWBW',
    '.WW..WW.',
  ],
};

const COLOR_MAP = {
  'C': '#06B6D4', 'D': '#059BB0', 'W': '#FFFFFF', 'B': '#2D2D2D',
  'P': '#F5A0B8', 'K': '#FFB8C8', 'O': '#FF8C42', 'Y': '#FFD93D',
  'G': '#7C3AED', 'S': '#87CEEB', 'R': '#FF5722', 'Z': '#AAAAAA',
  'M': '#8B5E3C', 'N': '#6B4226', 'E': '#FFE0B2',
};

function renderPetSvg(petId, x, y, scale = 4) {
  const pixels = PET_PIXELS[petId];
  if (!pixels) return '';
  let rects = '';
  for (let row = 0; row < pixels.length; row++) {
    for (let col = 0; col < pixels[row].length; col++) {
      const ch = pixels[row][col];
      if (ch === '.') continue;
      const color = COLOR_MAP[ch] || '#888';
      rects += `<rect x="${x + col * scale}" y="${y + row * scale}" width="${scale}" height="${scale}" fill="${color}"/>`;
    }
  }
  return rects;
}

function generateBadge() {
  const progress = loadProgress();
  const pet = progress.selectedPet || 'cat';
  const unlockCount = progress.unlocked?.length || 1;
  const totalMinutes = progress.stats?.totalTimeMinutes || 0;
  const hours = Math.floor(totalMinutes / 60);

  const width = 200;
  const height = 80;

  const petArt = renderPetSvg(pet, 12, 12, 5);
  const petName = pet.charAt(0).toUpperCase() + pet.slice(1);

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <style>
      @keyframes sparkle { 0%,100% { opacity:1; } 50% { opacity:0.3; } }
      .title { font: bold 13px monospace; fill: #E0E0E0; }
      .stat { font: 10px monospace; fill: #AAAAAA; }
      .sparkle { animation: sparkle 2s ease-in-out infinite; }
    </style>
  </defs>
  <rect width="${width}" height="${height}" rx="8" fill="#1a1a2e"/>
  <rect x="1" y="1" width="${width-2}" height="${height-2}" rx="7" fill="none" stroke="#06B6D4" stroke-opacity="0.3"/>
  ${petArt}
  <text x="72" y="28" class="title">Claude Pet</text>
  <text x="72" y="44" class="stat">${petName} | ${unlockCount}/12 unlocked</text>
  <text x="72" y="58" class="stat">${hours}h total coding</text>
  <circle cx="${width-12}" cy="12" r="2" fill="#06B6D4" class="sparkle"/>
</svg>`;
}

process.stdout.write(generateBadge() + '\n');
```

- [ ] **Step 2: Test badge generation**

```bash
node pet/generate-badge.mjs
```

Expected: Valid SVG output to stdout.

- [ ] **Step 3: Commit**

```bash
git add pet/generate-badge.mjs
git commit -m "feat: add README badge SVG generator"
```

---

## Task 23: GitHub Pages — Main Page and Collection

**Files:**
- Create: `docs/index.html`
- Create: `docs/collection.html`
- Create: `docs/assets/style.css`

- [ ] **Step 1: Create docs/assets/style.css**

```css
/* Claude Pet — Retro Dark Theme */
@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Inter:wght@400;600&display=swap');

:root {
  --bg: #0f0f1a;
  --card: #1a1a2e;
  --border: #16213e;
  --cyan: #06B6D4;
  --dcyan: #059BB0;
  --text: #E0E0E0;
  --muted: #888;
  --gold: #F59E0B;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: 'Inter', sans-serif;
  line-height: 1.6;
  min-height: 100vh;
}

.container {
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

h1, h2, h3 {
  font-family: 'Press Start 2P', monospace;
  color: var(--cyan);
}

h1 { font-size: 1.4rem; margin-bottom: 1.5rem; line-height: 1.8; }
h2 { font-size: 0.9rem; margin: 2rem 0 1rem; }
h3 { font-size: 0.75rem; margin: 1rem 0 0.5rem; color: var(--gold); }

p { margin-bottom: 1rem; color: var(--muted); }
a { color: var(--cyan); text-decoration: none; }
a:hover { text-decoration: underline; }

nav {
  display: flex;
  gap: 1.5rem;
  padding: 1rem 0;
  border-bottom: 1px solid var(--border);
  margin-bottom: 2rem;
}

nav a {
  font-family: 'Press Start 2P', monospace;
  font-size: 0.65rem;
  padding: 0.5rem 1rem;
  border: 1px solid var(--border);
  border-radius: 4px;
  transition: border-color 0.2s;
}

nav a:hover, nav a.active {
  border-color: var(--cyan);
  text-decoration: none;
}

/* Pet Cards */
.pet-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 1.5rem;
}

.pet-card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.5rem;
  transition: border-color 0.2s;
}

.pet-card:hover { border-color: var(--cyan); }

.pet-card .stages {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin: 1rem 0;
}

.pet-card .stage {
  text-align: center;
}

.pet-card .stage-label {
  font-size: 0.6rem;
  font-family: 'Press Start 2P', monospace;
  color: var(--muted);
  margin-top: 0.5rem;
}

.pet-card .stage-label.macho { color: var(--gold); }

.pixel-preview {
  width: 48px;
  height: 48px;
  image-rendering: pixelated;
  image-rendering: crisp-edges;
}

.unlock-condition {
  font-size: 0.85rem;
  color: var(--muted);
  padding-top: 0.75rem;
  border-top: 1px solid var(--border);
  margin-top: 0.75rem;
}

.badge-section {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.5rem;
  margin: 2rem 0;
}

code {
  background: #0d0d1a;
  padding: 0.2rem 0.5rem;
  border-radius: 3px;
  font-size: 0.9rem;
  color: var(--cyan);
}

pre {
  background: #0d0d1a;
  padding: 1rem;
  border-radius: 6px;
  overflow-x: auto;
  margin: 1rem 0;
}

pre code { padding: 0; background: none; }

.hero {
  text-align: center;
  padding: 3rem 0;
}

.hero p { color: var(--text); font-size: 1.1rem; }

footer {
  text-align: center;
  padding: 2rem 0;
  color: var(--muted);
  font-size: 0.85rem;
  border-top: 1px solid var(--border);
  margin-top: 3rem;
}
```

- [ ] **Step 2: Create docs/index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Claude Pet — Menu Bar Companion</title>
  <link rel="stylesheet" href="assets/style.css">
</head>
<body>
  <div class="container">
    <nav>
      <a href="index.html" class="active">Home</a>
      <a href="collection.html">Pet Collection</a>
    </nav>

    <div class="hero">
      <h1>Claude Pet</h1>
      <p>A Tamagotchi-style menu bar companion that lives alongside your Claude Code sessions.</p>
      <p>12 collectible pets. 3 muscle stages. Condition-based unlocks.</p>
    </div>

    <h2>Features</h2>
    <p>Your pet reacts to your coding activity in real-time:</p>
    <ul style="color: var(--muted); margin-left: 1.5rem; margin-bottom: 1rem;">
      <li>More agents running = your pet gets buffer (Normal → Buff → Macho)</li>
      <li>Multiple sessions = friend pets appear in the menu bar</li>
      <li>Use more AI = unlock new pets (12 total, each with unique unlock conditions)</li>
      <li>Rate limit warnings via macOS notifications</li>
    </ul>

    <h2>Install</h2>
    <pre><code>git clone https://github.com/Hoya324/claude-hud.git
cd claude-hud
./install.sh        # HUD status line
./pet/install.sh    # Claude Pet menu bar app</code></pre>

    <h2>README Badge</h2>
    <div class="badge-section">
      <p>Show your pet collection in your GitHub README:</p>
      <pre><code>node pet/generate-badge.mjs > docs/pet-badge.svg
git add docs/pet-badge.svg && git push</code></pre>
      <p>Then add to your README:</p>
      <pre><code>![My Claude Pet](https://YOUR_USERNAME.github.io/claude-hud/pet-badge.svg)</code></pre>
    </div>

    <footer>
      Claude Pet — Part of <a href="https://github.com/Hoya324/claude-hud">claude-hud</a>
    </footer>
  </div>
</body>
</html>
```

- [ ] **Step 3: Create docs/collection.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pet Collection — Claude Pet</title>
  <link rel="stylesheet" href="assets/style.css">
  <style>
    .pixel-canvas { image-rendering: pixelated; image-rendering: crisp-edges; }
    @keyframes walk {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-2px); }
    }
    .animated { animation: walk 0.6s ease-in-out infinite; }
  </style>
</head>
<body>
  <div class="container">
    <nav>
      <a href="index.html">Home</a>
      <a href="collection.html" class="active">Pet Collection</a>
    </nav>

    <h1>Pet Collection</h1>
    <p>12 unique pets, each with 3 muscle stages. Unlock them through your Claude Code usage!</p>

    <div class="pet-grid" id="pet-grid"></div>

    <footer>
      Claude Pet — Part of <a href="https://github.com/Hoya324/claude-hud">claude-hud</a>
    </footer>
  </div>

  <script>
    const PETS = [
      { id: 'cat', name: 'Cat', unlock: 'Default pet', concept: 'Your loyal coding companion' },
      { id: 'hamster', name: 'Hamster', unlock: 'Total 10 sessions', concept: 'Your first friend' },
      { id: 'chick', name: 'Chick', unlock: '5 hours total usage', concept: 'Small but mighty' },
      { id: 'penguin', name: 'Penguin', unlock: '500K tokens used', concept: 'The silent worker' },
      { id: 'fox', name: 'Fox', unlock: '50 agent runs', concept: 'Clever helper' },
      { id: 'rabbit', name: 'Rabbit', unlock: '3+ concurrent sessions', concept: 'Fast multitasker' },
      { id: 'goose', name: 'Goose', unlock: '30 hours total usage', concept: 'Veteran coder' },
      { id: 'capybara', name: 'Capybara', unlock: '10 rate limit hits', concept: 'Chill under pressure' },
      { id: 'sloth', name: 'Sloth', unlock: '20 long sessions (45m+)', concept: 'Marathon specialist' },
      { id: 'owl', name: 'Owl', unlock: '10 hours on Opus', concept: 'Wise model user' },
      { id: 'dragon', name: 'Dragon', unlock: '5+ concurrent agents', concept: 'Legendary multi-agent' },
      { id: 'unicorn', name: 'Unicorn', unlock: 'Unlock all pets', concept: 'Hidden collector reward' },
    ];

    const STAGES = ['Normal', 'Buff', 'Macho'];

    const grid = document.getElementById('pet-grid');

    PETS.forEach(pet => {
      const card = document.createElement('div');
      card.className = 'pet-card';
      card.innerHTML = `
        <h3>${pet.name}</h3>
        <p style="font-size: 0.85rem; color: var(--text); margin-bottom: 0.5rem;">${pet.concept}</p>
        <div class="stages">
          ${STAGES.map((stage, i) => `
            <div class="stage">
              <canvas class="pixel-canvas" width="48" height="48"
                data-pet="${pet.id}" data-stage="${i}"></canvas>
              <div class="stage-label ${stage.toLowerCase()}">${stage}</div>
            </div>
          `).join('')}
        </div>
        <div class="unlock-condition">Unlock: ${pet.unlock}</div>
      `;
      grid.appendChild(card);
    });

    // Render pixel art previews on canvases
    // Pet pixel data is embedded — each pet has 8x8 simplified preview per stage
    // Full sprite data would be loaded from assets in production
    document.querySelectorAll('.pixel-canvas').forEach(canvas => {
      const ctx = canvas.getContext('2d');
      ctx.fillStyle = '#1a1a2e';
      ctx.fillRect(0, 0, 48, 48);
      // Placeholder: draw a simple colored square indicating the pet
      const petId = canvas.dataset.pet;
      const stage = parseInt(canvas.dataset.stage);
      const colors = {
        cat: '#06B6D4', hamster: '#8B5E3C', chick: '#FFD93D',
        penguin: '#2D2D2D', fox: '#FF8C42', rabbit: '#FFFFFF',
        goose: '#CCCCCC', capybara: '#8B5E3C', sloth: '#6B4226',
        owl: '#1A237E', dragon: '#FF5722', unicorn: '#CC6BFF'
      };
      const size = 24 + stage * 6; // bigger with each stage
      const offset = (48 - size) / 2;
      ctx.fillStyle = colors[petId] || '#888';
      ctx.fillRect(offset, offset, size, size);
      // Stage indicator
      if (stage >= 1) {
        ctx.fillStyle = '#F59E0B';
        ctx.fillRect(offset + size - 4, offset, 4, 4);
      }
      if (stage >= 2) {
        ctx.fillStyle = '#F59E0B';
        ctx.fillRect(offset, offset, 4, 4);
        ctx.fillRect(offset + size - 4, offset + size - 4, 4, 4);
      }
    });
  </script>
</body>
</html>
```

Note: The canvas rendering above uses simplified placeholders. Once the actual sprite PNGs are exported (from the Swift app), replace the canvas rendering with `<img>` tags pointing to `assets/pets/{petId}-{stage}.png`.

- [ ] **Step 4: Commit**

```bash
git add docs/index.html docs/collection.html docs/assets/style.css
git commit -m "feat: add GitHub Pages docs site with pet collection page"
```

---

## Task 24: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read current README**

Read the existing README.md to understand its current structure.

- [ ] **Step 2: Update README with v2 features and badge**

Add the pet badge image at the top, update feature descriptions to include the v2 collection system, muscle stages, and unlock conditions. Add a "Pet Collection" section with the 12 pets table and a link to the GitHub Pages collection page.

Key sections to add/update:
- Badge: `![Claude Pet](https://Hoya324.github.io/claude-hud/pet-badge.svg)` at the top
- Pet Collection table (12 pets with unlock conditions)
- Muscle stages explanation
- Link to full docs: `https://Hoya324.github.io/claude-hud/collection.html`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update README with v2 pet collection, badge, and docs link"
```

---

## Task 25: Full Build and Integration Test

**Files:** All

- [ ] **Step 1: Full build**

```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud
./pet/install.sh
```

Expected: Successful compilation and app launch.

- [ ] **Step 2: Verify aggregator writes progress.json**

```bash
sleep 5
cat ~/.claude/pet/progress.json
```

Expected: JSON with stats, unlocked array containing at least "cat".

- [ ] **Step 3: Verify badge generation**

```bash
node pet/generate-badge.mjs > docs/pet-badge.svg
cat docs/pet-badge.svg | head -5
```

Expected: Valid SVG output.

- [ ] **Step 4: Verify menu bar app**

- Click the menu bar icon → SwiftUI popover should appear
- Cat should be shown in the pet grid as unlocked
- Other pets should show as locked silhouettes
- Quit button should work

- [ ] **Step 5: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: integration fixes for full v2 build"
```
