# Pants, Color Gacha, Click Interaction & Idle Motions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add pants accessory category with color gacha, click-triggered jump+wave animation, and random idle motions to the Clawd pet.

**Architecture:** Extends the existing accessory/overlay system by adding a `pants` category with color-templated sprites, a ticket-based color change system persisted in `progress.json`, click interaction animations layered on top of the state-based animation loop, and a probabilistic idle motion timer.

**Tech Stack:** Swift (macOS AppKit + SwiftUI), Node.js (pet-aggregator daemon), pixel art via 32x32 UInt32 grids.

---

## File Structure

### New Files
| File | Responsibility |
|------|----------------|
| `pet/ClaudePet/Sources/Sprites/PantsSprites.swift` | 5 pants type overlay grids (32x32) with color-template sentinel values |
| `pet/ClaudePet/Sources/Sprites/InteractionSprites.swift` | 6 frames of jump+wave character sprites (32x32) |
| `pet/ClaudePet/Sources/Sprites/IdleMotionSprites.swift` | 4 idle motion sprite sets (wave, blink, tilt, stretch) |
| `pet/ClaudePet/Sources/PantsColorPalette.swift` | Color palette definition, sentinel replacement logic |

### Modified Files
| File | Changes |
|------|---------|
| `pet/ClaudePet/Sources/AccessoryType.swift` | Add `pants` category, 5 pants cases, unlock descriptions |
| `pet/ClaudePet/Sources/Sprites/AccessorySprites.swift` | Add pants overlay dispatch, `pantsColor` parameter to `overlay()` |
| `pet/ClaudePet/Sources/PixelArtRenderer.swift` | Add `pants` + `pantsColor` params to `renderFrame()` |
| `pet/ClaudePet/Sources/ProgressTracker.swift` | Add `selectedPants`, `pantsColor`, `colorChangeTickets`, selection/color methods |
| `pet/ClaudePet/Sources/CollectionView.swift` | Add pants grid section, color change button, ViewModel properties |
| `pet/ClaudePet/Sources/AppDelegate.swift` | Track pants, interaction animation, idle motion timer |
| `pet/pet-aggregator.mjs` | Add 5 pants unlock conditions, color ticket accumulation logic |
| `pet/install.sh` | Add 4 new .swift files to `swiftc` command |

---

### Task 1: Add `pants` category and types to `AccessoryType.swift`

**Files:**
- Modify: `pet/ClaudePet/Sources/AccessoryType.swift`

- [ ] **Step 1: Add `pants` to `AccessoryCategory`**

In `AccessoryType.swift`, add `pants` to the category enum:

```swift
enum AccessoryCategory: String, CaseIterable, Codable {
    case hat
    case glasses
    case pants
}
```

- [ ] **Step 2: Add 5 pants cases to `AccessoryType`**

Add after the glasses cases:

```swift
enum AccessoryType: String, CaseIterable, Codable {
    // Hats (5)
    case cap
    case partyHat
    case santaHat
    case silkHat
    case cowboyHat
    // Glasses (4)
    case hornRimmed
    case sunglasses
    case roundGlasses
    case starGlasses
    // Pants (5)
    case jeans
    case shorts
    case slacks
    case joggers
    case cargo
```

- [ ] **Step 3: Update `category` computed property**

Add pants cases to the switch:

```swift
    var category: AccessoryCategory {
        switch self {
        case .cap, .partyHat, .santaHat, .silkHat, .cowboyHat:
            return .hat
        case .hornRimmed, .sunglasses, .roundGlasses, .starGlasses:
            return .glasses
        case .jeans, .shorts, .slacks, .joggers, .cargo:
            return .pants
        }
    }
```

- [ ] **Step 4: Update `displayName`, `displayNameKO`, `unlockDescription`, `unlockDescriptionKO`**

Add to each switch:

```swift
    // displayName
    case .jeans:    return "Jeans"
    case .shorts:   return "Shorts"
    case .slacks:   return "Slacks"
    case .joggers:  return "Joggers"
    case .cargo:    return "Cargo Pants"

    // displayNameKO
    case .jeans:    return "청바지"
    case .shorts:   return "반바지"
    case .slacks:   return "정장바지"
    case .joggers:  return "운동바지"
    case .cargo:    return "카고바지"

    // unlockDescription
    case .jeans:    return "15 hours total usage"
    case .shorts:   return "Total 100 sessions"
    case .slacks:   return "1M tokens used"
    case .joggers:  return "100 agent runs"
    case .cargo:    return "50 hours total usage"

    // unlockDescriptionKO
    case .jeans:    return "총 15시간 사용"
    case .shorts:   return "총 100회 세션"
    case .slacks:   return "100만 토큰 사용"
    case .joggers:  return "에이전트 100회 실행"
    case .cargo:    return "총 50시간 사용"
```

- [ ] **Step 5: Add `pants` static accessor**

Add alongside existing `hats` and `glasses`:

```swift
    static var pants: [AccessoryType] {
        allCases.filter { $0.category == .pants }
    }
```

- [ ] **Step 6: Build to verify**

Run: `cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet && swiftc -typecheck Sources/AccessoryType.swift`

Expected: Compilation errors in other files referencing AccessoryType switch exhaustiveness (expected at this stage — they'll be fixed in later tasks).

- [ ] **Step 7: Commit**

```bash
git add pet/ClaudePet/Sources/AccessoryType.swift
git commit -m "feat: add pants accessory category with 5 types (jeans, shorts, slacks, joggers, cargo)"
```

---

### Task 2: Create `PantsColorPalette.swift`

**Files:**
- Create: `pet/ClaudePet/Sources/PantsColorPalette.swift`

- [ ] **Step 1: Create the color palette file**

Create `pet/ClaudePet/Sources/PantsColorPalette.swift`:

```swift
import Foundation

// Sentinel colors used in pants sprite templates.
// PixelArtRenderer replaces these with the active palette entry.
let PANTS_MAIN_SENTINEL    = UInt32(0xFFFE0001) // unique sentinel for main color
let PANTS_DARK_SENTINEL    = UInt32(0xFFFE0002) // unique sentinel for dark color
let PANTS_DETAIL_SENTINEL  = UInt32(0xFFFE0003) // unique sentinel for detail (stitching, pockets)

struct PantsColor: Codable, Equatable {
    let name: String
    let displayName: String
    let displayNameKO: String
    let main: UInt32
    let dark: UInt32
    let detail: UInt32

    // Codable support for UInt32
    enum CodingKeys: String, CodingKey {
        case name, displayName, displayNameKO, main, dark, detail
    }

    init(name: String, displayName: String, displayNameKO: String,
         main: UInt32, dark: UInt32, detail: UInt32) {
        self.name = name
        self.displayName = displayName
        self.displayNameKO = displayNameKO
        self.main = main
        self.dark = dark
        self.detail = detail
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        displayName = try c.decode(String.self, forKey: .displayName)
        displayNameKO = try c.decode(String.self, forKey: .displayNameKO)
        main = UInt32(try c.decode(Int.self, forKey: .main))
        dark = UInt32(try c.decode(Int.self, forKey: .dark))
        detail = UInt32(try c.decode(Int.self, forKey: .detail))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(displayNameKO, forKey: .displayNameKO)
        try c.encode(Int(main), forKey: .main)
        try c.encode(Int(dark), forKey: .dark)
        try c.encode(Int(detail), forKey: .detail)
    }
}

struct PantsColorPalette {
    static let colors: [PantsColor] = [
        PantsColor(name: "blue",   displayName: "Blue",   displayNameKO: "파란색",
                   main: 0xFF2196F3, dark: 0xFF1565C0, detail: 0xFFE0E0E0),
        PantsColor(name: "red",    displayName: "Red",    displayNameKO: "빨간색",
                   main: 0xFFE53935, dark: 0xFFC62828, detail: 0xFFFFCDD2),
        PantsColor(name: "green",  displayName: "Green",  displayNameKO: "초록색",
                   main: 0xFF4CAF50, dark: 0xFF2E7D32, detail: 0xFFC8E6C9),
        PantsColor(name: "purple", displayName: "Purple", displayNameKO: "보라색",
                   main: 0xFF7C3AED, dark: 0xFF5B21B6, detail: 0xFFE1BEE7),
        PantsColor(name: "brown",  displayName: "Brown",  displayNameKO: "갈색",
                   main: 0xFF8B5E3C, dark: 0xFF6B4226, detail: 0xFFD7CCC8),
        PantsColor(name: "black",  displayName: "Black",  displayNameKO: "검정색",
                   main: 0xFF333333, dark: 0xFF1A1A1A, detail: 0xFF555555),
        PantsColor(name: "white",  displayName: "White",  displayNameKO: "흰색",
                   main: 0xFFEEEEEE, dark: 0xFFCCCCCC, detail: 0xFFFFFFFF),
        PantsColor(name: "yellow", displayName: "Yellow", displayNameKO: "노란색",
                   main: 0xFFFFD93D, dark: 0xFFF59E0B, detail: 0xFFFFF9C4),
        PantsColor(name: "pink",   displayName: "Pink",   displayNameKO: "핑크색",
                   main: 0xFFF5A0B8, dark: 0xFFE91E8D, detail: 0xFFFCE4EC),
        PantsColor(name: "khaki",  displayName: "Khaki",  displayNameKO: "카키색",
                   main: 0xFFBDB76B, dark: 0xFF8B8000, detail: 0xFFE8E5C0),
    ]

    static let defaultColor = colors[0] // blue

    static func color(named name: String) -> PantsColor {
        return colors.first { $0.name == name } ?? defaultColor
    }

    static func randomColor() -> PantsColor {
        return colors.randomElement() ?? defaultColor
    }

    /// Replace sentinel pixels in a sprite grid with actual colors
    static func applyColor(_ color: PantsColor, to grid: [[UInt32?]]) -> [[UInt32?]] {
        return grid.map { row in
            row.map { pixel -> UInt32? in
                guard let px = pixel else { return nil }
                switch px {
                case PANTS_MAIN_SENTINEL:   return color.main
                case PANTS_DARK_SENTINEL:   return color.dark
                case PANTS_DETAIL_SENTINEL: return color.detail
                default: return px
                }
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/PantsColorPalette.swift
git commit -m "feat: add pants color palette with 10 colors and sentinel replacement"
```

---

### Task 3: Create `PantsSprites.swift` with 5 pants overlay templates

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/PantsSprites.swift`

Character body layout reference (from `ClaudeSprites.swift` normal frame 0):
- Rows 19-22: Lower body (`S` shadow, cols 4-27)
- Rows 23-26: Legs (cols 6-7 + 10-11 left leg, cols 20-21 + 24-25 right leg)

Pants overlays cover rows 19-26 using sentinel colors `PC` (main), `PD` (dark), `PX` (detail).

- [ ] **Step 1: Create pants sprites file**

Create `pet/ClaudePet/Sources/Sprites/PantsSprites.swift`:

```swift
import Foundation

// Color aliases for pants templates (sentinel values, replaced at render time)
private let PC: UInt32? = PANTS_MAIN_SENTINEL    // Main pants color
private let PD: UInt32? = PANTS_DARK_SENTINEL    // Dark pants color
private let PX: UInt32? = PANTS_DETAIL_SENTINEL  // Detail (stitch/pocket)
private let T: UInt32? = nil                      // Transparent

struct PantsSprites {

    static func baseOverlay(pants: AccessoryType) -> [[UInt32?]]? {
        switch pants {
        case .jeans:   return jeansOverlay
        case .shorts:  return shortsOverlay
        case .slacks:  return slacksOverlay
        case .joggers: return joggersOverlay
        case .cargo:   return cargoOverlay
        default:       return nil
        }
    }
}

// ============================================================================
// MARK: - Jeans: Full-length denim with stitch detail
// Covers rows 19-26 of the 32x32 grid
// ============================================================================
private let jeansOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 19: waistband
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 20: upper thigh
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 21: pocket stitch
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 22: lower thigh
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 23: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 24: legs
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // row 25: cuffs
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // row 26: cuffs
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// ============================================================================
// MARK: - Shorts: Cut off at row 23, no leg coverage
// ============================================================================
private let shortsOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 19: waistband
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 20
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 21
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // row 22: hem
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23: legs exposed
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// ============================================================================
// MARK: - Slacks: Crisp creases, clean lines
// ============================================================================
private let slacksOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // row 19: belt line
    [T,T,T,T,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,T,T,T,T], // row 20: crease
    [T,T,T,T,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,T,T,T,T], // row 21: crease
    [T,T,T,T,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,T,T,T,T], // row 22: crease
    [T,T,T,T,T,T,PC,PX,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PX,PC,T,T,T,T,T,T], // row 23: leg crease
    [T,T,T,T,T,T,PC,PX,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PX,PC,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,PC,PX,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PX,PC,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// ============================================================================
// MARK: - Joggers: Elastic cuffs, sporty stripe
// ============================================================================
private let joggersOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 19: waistband
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 20
    [T,T,T,T,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,T,T,T,T], // row 21: side stripe
    [T,T,T,T,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,T,T,T,T], // row 22: side stripe
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 23: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // row 25: elastic cuff
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // row 26: elastic cuff
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// ============================================================================
// MARK: - Cargo: Big pockets on sides
// ============================================================================
private let cargoOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 19: waistband
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // row 20
    [T,T,T,T,PX,PX,PX,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PX,PX,PX,PC,T,T,T,T], // row 21: pocket
    [T,T,T,T,PX,PD,PX,PC,PC,PC,PC,PC,PC,PC,PC,PD,PD,PC,PC,PC,PC,PC,PC,PC,PX,PD,PX,PC,T,T,T,T], // row 22: pocket flap
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 23: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // row 26: cuffs
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]
```

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/PantsSprites.swift
git commit -m "feat: add 5 pants sprite overlays with color-templated sentinel pixels"
```

---

### Task 4: Wire pants into `AccessorySprites.swift` and `PixelArtRenderer.swift`

**Files:**
- Modify: `pet/ClaudePet/Sources/Sprites/AccessorySprites.swift:27-91`
- Modify: `pet/ClaudePet/Sources/PixelArtRenderer.swift:122-148`

- [ ] **Step 1: Add pantsColor parameter to `AccessorySprites.overlay()`**

In `AccessorySprites.swift`, update the `overlay` method to handle pants with color:

```swift
    /// Get overlay for an accessory at a given state and frame
    static func overlay(accessory: AccessoryType, state: PetState, frameIndex: Int,
                         pantsColor: PantsColor? = nil) -> [[UInt32?]]? {
        let base: [[UInt32?]]?
        if accessory.category == .pants {
            base = PantsSprites.baseOverlay(pants: accessory)
        } else {
            base = baseOverlay(accessory: accessory)
        }
        guard var grid = base else { return nil }

        // Apply color to pants templates
        if accessory.category == .pants, let color = pantsColor {
            grid = PantsColorPalette.applyColor(color, to: grid)
        }

        let yOffset = verticalOffset(state: state, frameIndex: frameIndex)
        if yOffset == 0 { return grid }
        return shiftVertically(grid, by: yOffset)
    }
```

Note: Keep the existing `baseOverlay` method unchanged — it still handles hat/glasses. The pants dispatch goes through `PantsSprites.baseOverlay()`.

- [ ] **Step 2: Update `PixelArtRenderer.renderFrame()` to accept pants**

In `PixelArtRenderer.swift`, update `renderFrame`:

```swift
    static func renderFrame(
        state: PetState,
        activity: ActivityLevel,
        hat: AccessoryType?,
        glasses: AccessoryType?,
        pants: AccessoryType? = nil,
        pantsColor: PantsColor? = nil,
        frameIndex: Int
    ) -> NSImage {
        let baseFrames = ClaudeSprites.frames(state: state)
        let base = baseFrames[frameIndex % max(1, baseFrames.count)]

        var overlays: [[[UInt32?]]?] = []
        // Glasses first (under pants and hat)
        if let glasses = glasses {
            overlays.append(AccessorySprites.overlay(
                accessory: glasses, state: state, frameIndex: frameIndex))
        }
        // Pants second
        if let pants = pants {
            overlays.append(AccessorySprites.overlay(
                accessory: pants, state: state, frameIndex: frameIndex,
                pantsColor: pantsColor ?? PantsColorPalette.defaultColor))
        }
        // Hat on top
        if let hat = hat {
            overlays.append(AccessorySprites.overlay(
                accessory: hat, state: state, frameIndex: frameIndex))
        }

        let effect = ClaudeEffects.effectOverlay(
            activity: activity, frameIndex: frameIndex)

        return renderComposited(base: base, overlays: overlays, effect: effect)
    }
```

- [ ] **Step 3: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/AccessorySprites.swift pet/ClaudePet/Sources/PixelArtRenderer.swift
git commit -m "feat: wire pants overlay into rendering pipeline with color support"
```

---

### Task 5: Update `ProgressTracker.swift` for pants selection and color tickets

**Files:**
- Modify: `pet/ClaudePet/Sources/ProgressTracker.swift`

- [ ] **Step 1: Update `ProgressData` struct**

Add new fields to `ProgressData`:

```swift
struct ProgressData: Codable {
    var version: Int
    var stats: ProgressStats
    var unlockedAccessories: [String]
    var selectedHat: String?
    var selectedGlasses: String?
    var selectedPants: String?
    var pantsColor: String?
    var colorChangeTickets: Int?
    var lastColorTicketMinutes: Int?
    var unlockedAt: [String: String]
}
```

- [ ] **Step 2: Add pants and color query/setter methods**

Add after the existing `selectGlasses` method:

```swift
    // MARK: - Pants selection

    func selectedPants() -> AccessoryType? {
        guard let progress = read(),
              let raw = progress.selectedPants else { return nil }
        return AccessoryType(rawValue: raw)
    }

    func selectPants(_ pants: AccessoryType?) {
        guard var progress = read() else { return }
        progress.selectedPants = pants?.rawValue
        writeBack(progress)
    }

    // MARK: - Pants color

    func pantsColor() -> PantsColor {
        guard let progress = read(),
              let name = progress.pantsColor else {
            return PantsColorPalette.defaultColor
        }
        return PantsColorPalette.color(named: name)
    }

    func colorChangeTickets() -> Int {
        return read()?.colorChangeTickets ?? 0
    }

    func consumeColorTicket() -> PantsColor? {
        guard var progress = read() else { return nil }
        let tickets = progress.colorChangeTickets ?? 0
        guard tickets > 0 else { return nil }
        let newColor = PantsColorPalette.randomColor()
        progress.colorChangeTickets = tickets - 1
        progress.pantsColor = newColor.name
        writeBack(progress)
        return newColor
    }
```

- [ ] **Step 3: Add pants unlock progress cases**

In the `unlockProgress(for:)` method, add:

```swift
        case .jeans:    return (stats.totalTimeMinutes, 900)
        case .shorts:   return (stats.totalSessions, 100)
        case .slacks:   return (stats.totalTokens, 1_000_000)
        case .joggers:  return (stats.totalAgentRuns, 100)
        case .cargo:    return (stats.totalTimeMinutes, 3000)
```

- [ ] **Step 4: Update v1 migration to include pants defaults**

In the `migrateV1` method, after building v2, ensure the new fields get default values. Since `ProgressData` uses optionals for pants fields, they'll default to nil which is correct.

- [ ] **Step 5: Commit**

```bash
git add pet/ClaudePet/Sources/ProgressTracker.swift
git commit -m "feat: add pants selection, color tracking, and ticket system to ProgressTracker"
```

---

### Task 6: Update `CollectionView.swift` with pants grid and color change UI

**Files:**
- Modify: `pet/ClaudePet/Sources/CollectionView.swift`

- [ ] **Step 1: Add pants-related published properties to `ClawdViewModel`**

Add to the `ClawdViewModel` class:

```swift
    @Published var selectedPants: AccessoryType? = nil
    @Published var pantsColorName: String = "blue"
    @Published var pantsColorDisplayKO: String = "파란색"
    @Published var colorChangeTickets: Int = 0
```

- [ ] **Step 2: Update `refresh()` in ViewModel**

After existing `selectedGlasses` line, add:

```swift
        selectedPants = progressTracker.selectedPants()
        let currentPantsColor = progressTracker.pantsColor()
        pantsColorName = currentPantsColor.name
        pantsColorDisplayKO = currentPantsColor.displayNameKO
        colorChangeTickets = progressTracker.colorChangeTickets()
```

- [ ] **Step 3: Add `selectPants()` method to ViewModel**

After `selectGlasses`:

```swift
    func selectPants(_ pants: AccessoryType?) {
        let newPants: AccessoryType? = (pants == selectedPants) ? nil : pants
        selectedPants = newPants
        progressTracker.selectPants(newPants)
        NotificationCenter.default.post(name: .accessoryChanged, object: nil)
    }

    func useColorTicket() {
        if let newColor = progressTracker.consumeColorTicket() {
            pantsColorName = newColor.name
            pantsColorDisplayKO = newColor.displayNameKO
            colorChangeTickets = progressTracker.colorChangeTickets()
            NotificationCenter.default.post(name: .accessoryChanged, object: nil)
        }
    }
```

- [ ] **Step 4: Add pants grid section to `CollectionPopoverView`**

In `CollectionPopoverView.body`, add after `glassesGridSection`:

```swift
            Divider()
            pantsGridSection
```

Then add the section implementation:

```swift
    // MARK: - Pants Grid
    private var pantsGridSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Pants")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.colorChangeTickets > 0 {
                    Button(action: { viewModel.useColorTicket() }) {
                        HStack(spacing: 2) {
                            Image(systemName: "dice.fill")
                                .font(.system(size: 9))
                            Text("Color (\(viewModel.colorChangeTickets))")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(viewModel.pantsColorDisplayKO)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            let columns = Array(repeating: GridItem(.fixed(44), spacing: 6), count: 5)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AccessoryType.pants, id: \.self) { pants in
                    AccessoryGridCell(
                        accessory: pants,
                        isUnlocked: viewModel.unlockedAccessories.contains(pants),
                        isSelected: viewModel.selectedPants == pants,
                        onSelect: { viewModel.selectPants(pants) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
```

- [ ] **Step 5: Update `ClawdPreviewView` to include pants**

Update the preview to render pants too:

```swift
struct ClawdPreviewView: NSViewRepresentable {
    let hat: AccessoryType?
    let glasses: AccessoryType?
    var pants: AccessoryType? = nil
    var pantsColor: PantsColor? = nil

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
            state: .normal,
            activity: .normal,
            hat: hat,
            glasses: glasses,
            pants: pants,
            pantsColor: pantsColor,
            frameIndex: 0
        )
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add pet/ClaudePet/Sources/CollectionView.swift
git commit -m "feat: add pants grid section and color change button to collection popover"
```

---

### Task 7: Update `AppDelegate.swift` — pants tracking and rendering

**Files:**
- Modify: `pet/ClaudePet/Sources/AppDelegate.swift`

- [ ] **Step 1: Add pants state tracking**

Add instance variables:

```swift
    private var currentPants: AccessoryType? = nil
    private var currentPantsColor: PantsColor = PantsColorPalette.defaultColor
```

- [ ] **Step 2: Load pants in `applicationDidFinishLaunching`**

After loading hat and glasses:

```swift
        currentPants = progressTracker.selectedPants()
        currentPantsColor = progressTracker.pantsColor()
```

- [ ] **Step 3: Update `pollState()` to track pants changes**

In `pollState()`, after loading `newGlasses`, add:

```swift
        let newPants = progressTracker.selectedPants()
        let newPantsColor = progressTracker.pantsColor()
```

After `let oldGlasses = currentGlasses`, add:

```swift
        let oldPants = currentPants
        let oldPantsColor = currentPantsColor
```

After setting `currentGlasses`, add:

```swift
        currentPants = newPants
        currentPantsColor = newPantsColor
```

Update the `needsReload` check to include pants:

```swift
            let needsReload = newState != oldState
                           || newActivity != oldActivity
                           || newHat?.rawValue != oldHat?.rawValue
                           || newGlasses?.rawValue != oldGlasses?.rawValue
                           || newPants?.rawValue != oldPants?.rawValue
                           || newPantsColor.name != oldPantsColor.name
```

- [ ] **Step 4: Update `reloadFramesAndAnimate()` to pass pants**

```swift
    private func reloadFramesAndAnimate() {
        let count = PixelArtRenderer.frameCount(state: currentState)
        currentFrames = (0..<count).map { i in
            PixelArtRenderer.renderFrame(
                state: currentState,
                activity: currentActivity,
                hat: currentHat,
                glasses: currentGlasses,
                pants: currentPants,
                pantsColor: currentPantsColor,
                frameIndex: i
            )
        }
        // ... rest unchanged
    }
```

- [ ] **Step 5: Commit**

```bash
git add pet/ClaudePet/Sources/AppDelegate.swift
git commit -m "feat: track and render pants accessory with color in AppDelegate"
```

---

### Task 8: Update `pet-aggregator.mjs` — pants unlock conditions and color tickets

**Files:**
- Modify: `pet/pet-aggregator.mjs`

- [ ] **Step 1: Add pants to `UNLOCK_CONDITIONS`**

After `starGlasses` entry:

```javascript
const UNLOCK_CONDITIONS = {
  cap:          { type: 'totalSessions', threshold: 10 },
  partyHat:     { type: 'totalTimeMinutes', threshold: 300 },
  santaHat:     { type: 'totalTokens', threshold: 500000 },
  silkHat:      { type: 'totalAgentRuns', threshold: 50 },
  cowboyHat:    { type: 'totalTimeMinutes', threshold: 1800 },
  hornRimmed:   { type: 'maxConcurrentSessions', threshold: 3 },
  sunglasses:   { type: 'rateLimitHits', threshold: 10 },
  roundGlasses: { type: 'longSessions', threshold: 20 },
  starGlasses:  { type: 'opusTimeMinutes', threshold: 600 },
  // Pants
  jeans:        { type: 'totalTimeMinutes', threshold: 900 },
  shorts:       { type: 'totalSessions', threshold: 100 },
  slacks:       { type: 'totalTokens', threshold: 1000000 },
  joggers:      { type: 'totalAgentRuns', threshold: 100 },
  cargo:        { type: 'totalTimeMinutes', threshold: 3000 },
};
```

- [ ] **Step 2: Add `defaultProgress` fields for pants**

Update `defaultProgress()` to include new fields:

```javascript
function defaultProgress() {
  return {
    version: 2,
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
    unlockedAccessories: [],
    selectedHat: null,
    selectedGlasses: null,
    selectedPants: null,
    pantsColor: 'blue',
    colorChangeTickets: 0,
    lastColorTicketMinutes: 0,
    unlockedAt: {},
  };
}
```

- [ ] **Step 3: Add color ticket accumulation logic**

Add a new function after `checkRateLimitHit`:

```javascript
function checkColorTicket(progress) {
  const totalMinutes = progress.stats.totalTimeMinutes;
  const lastTicket = progress.lastColorTicketMinutes || 0;
  const ticketInterval = 480; // 8 hours

  if (totalMinutes - lastTicket >= ticketInterval) {
    const newTickets = Math.floor((totalMinutes - lastTicket) / ticketInterval);
    progress.colorChangeTickets = (progress.colorChangeTickets || 0) + newTickets;
    progress.lastColorTicketMinutes = lastTicket + (newTickets * ticketInterval);
    process.stderr.write(`[oh-my-clawd] awarded ${newTickets} color ticket(s)\n`);
  }
}
```

- [ ] **Step 4: Call `checkColorTicket` in the tick function**

In the `tick()` function, after `checkUnlocks(progress);`, add:

```javascript
    checkColorTicket(progress);
```

- [ ] **Step 5: Ensure existing progress data gets new fields on load**

In `loadProgress()`, after the migration block, add defaults for missing fields:

```javascript
  // Ensure new fields exist (forward-compatible)
  if (data.selectedPants === undefined) data.selectedPants = null;
  if (data.pantsColor === undefined) data.pantsColor = 'blue';
  if (data.colorChangeTickets === undefined) data.colorChangeTickets = 0;
  if (data.lastColorTicketMinutes === undefined) data.lastColorTicketMinutes = 0;

  return data;
```

- [ ] **Step 6: Commit**

```bash
git add pet/pet-aggregator.mjs
git commit -m "feat: add pants unlock conditions and color ticket accumulation to aggregator"
```

---

### Task 9: Create `InteractionSprites.swift` — click jump+wave animation

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/InteractionSprites.swift`

Character layout reference: head rows 7-14, body rows 15-18, lower rows 19-22, legs rows 23-26. Arms extend from rows 15-18 on sides (cols 0-3 left, 28-31 right).

The jump+wave animation is 6 frames:
- Frame 0-1: Crouch (body down 1px)
- Frame 2-3: Jump (body up 2px, right arm raised)
- Frame 4-5: Land + wave (normal height, right arm waving)

- [ ] **Step 1: Create interaction sprites file**

Create `pet/ClaudePet/Sources/Sprites/InteractionSprites.swift`:

```swift
import Foundation

// Uses same color aliases as ClaudeSprites
private let M = UInt32(0xFFD97757)   // Main body
private let S = UInt32(0xFFBF6347)   // Shadow
private let H = UInt32(0xFFE89070)   // Highlight
private let W = UInt32(0xFFFFFFFF)   // White
private let B = UInt32(0xFF2D2D2D)   // Black (eyes)
private let P = UInt32(0xFFF5A0B8)   // Blush
private let T: UInt32? = nil         // Transparent

struct InteractionSprites {
    static let frameInterval: TimeInterval = 0.15
    static let frameCount: Int = 6

    static func frames() -> [[[UInt32?]]] {
        return interactionFrames
    }
}

// 6 frames: crouch → crouch → jump+armUp → jump+armUp → land+wave1 → land+wave2
private let interactionFrames: [[[UInt32?]]] = [
    // Frame 0: Crouch - body shifted down 1px, legs compressed
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: Same crouch (held)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Jump! Body up 3px, right arm raised high
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3: Peak jump, right arm waving (same position, arm to the right)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4: Landing, right arm wave position 1 (arm out to right)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 5: Wave position 2 (arm raised up-right)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]
```

**Note:** These sprite frames are initial placeholders. The actual pixel art should be refined during implementation to look good at 2x scale in the menu bar. The key structure is correct — 6 frames at 0.15s showing crouch → jump → wave.

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/InteractionSprites.swift
git commit -m "feat: add click interaction sprites (jump + wave, 6 frames)"
```

---

### Task 10: Create `IdleMotionSprites.swift` — random idle motion frames

**Files:**
- Create: `pet/ClaudePet/Sources/Sprites/IdleMotionSprites.swift`

- [ ] **Step 1: Create idle motion sprites file**

Create `pet/ClaudePet/Sources/Sprites/IdleMotionSprites.swift`. This file contains 4 short animation sequences that overlay on top of the base character. Rather than full 32x32 character sprites, these are **overlay grids** that only modify the pixels that change (eyes for blink, arms for wave, head for tilt).

```swift
import Foundation

private let M = UInt32(0xFFD97757)   // Main body
private let S = UInt32(0xFFBF6347)   // Shadow
private let H = UInt32(0xFFE89070)   // Highlight
private let B = UInt32(0xFF2D2D2D)   // Black (eyes)
private let T: UInt32? = nil         // Transparent

enum IdleMotionType: CaseIterable {
    case wave
    case blink
    case tilt
    case stretch

    var frameCount: Int {
        switch self {
        case .wave:    return 4  // arm up, wave1, wave2, arm down
        case .blink:   return 3  // close, closed, open
        case .tilt:    return 4  // tilt right, hold, tilt back, normal
        case .stretch: return 4  // arms up, stretch, hold, arms down
        }
    }

    var frameInterval: TimeInterval {
        switch self {
        case .wave:    return 0.2
        case .blink:   return 0.12
        case .tilt:    return 0.25
        case .stretch: return 0.25
        }
    }

    /// Which PetStates allow this motion to trigger
    var allowedStates: [PetState] {
        switch self {
        case .wave:    return [.normal, .idle, .tired]
        case .blink:   return [.normal, .idle, .tired, .collab]
        case .tilt:    return [.normal, .idle]
        case .stretch: return [.normal, .tired]
        }
    }
}

struct IdleMotionSprites {
    /// Get the full character frames for an idle motion.
    /// These are complete 32x32 grids (not overlays) since the character pose changes.
    static func frames(motion: IdleMotionType) -> [[[UInt32?]]] {
        switch motion {
        case .wave:    return waveFrames
        case .blink:   return blinkFrames
        case .tilt:    return tiltFrames
        case .stretch: return stretchFrames
        }
    }
}

// ============================================================================
// MARK: - Blink: Eyes close briefly (3 frames)
// Only rows 11-14 change (eye area), rest matches normal frame 0
// ============================================================================
private let blinkFrames: [[[UInt32?]]] = [
    // Frame 0: Eyes closing (horizontal line instead of square eyes)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: Eyes fully closed (line)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,S,S,M,M,M,M,M,M,M,M,M,M,M,M,S,S,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Eyes open again (same as normal frame 0)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// Wave, tilt, and stretch use the same InteractionSprites wave frames (frames 4-5) as a starting point.
// Reuse the normal frame 0 base and modify arm positions.
// These are placeholder arrays — the implementer should refine pixel art for each motion.
private let waveFrames: [[[UInt32?]]] = InteractionSprites.frames().suffix(2) + InteractionSprites.frames().suffix(2)
private let tiltFrames: [[[UInt32?]]] = [blinkFrames[2], blinkFrames[2], blinkFrames[2], blinkFrames[2]]
private let stretchFrames: [[[UInt32?]]] = InteractionSprites.frames().suffix(2) + InteractionSprites.frames().suffix(2)
```

**Note:** The wave, tilt, and stretch frames reuse existing frames as placeholders. The actual pixel art refinement (distinct arm poses for wave, head offset for tilt, both-arms-up for stretch) should be done during implementation when the implementer can visually verify at 2x scale. The blink animation is fully specified since it only changes the eye pixels.

- [ ] **Step 2: Commit**

```bash
git add pet/ClaudePet/Sources/Sprites/IdleMotionSprites.swift
git commit -m "feat: add idle motion sprites (blink, wave, tilt, stretch)"
```

---

### Task 11: Wire click interaction and idle motions into `AppDelegate.swift`

**Files:**
- Modify: `pet/ClaudePet/Sources/AppDelegate.swift`

- [ ] **Step 1: Add interaction and idle motion state variables**

Add to instance variables:

```swift
    private var isPlayingInteraction: Bool = false
    private var interactionTimer: Timer?
    private var interactionFrameIndex: Int = 0
    private var interactionFrames: [NSImage] = []

    private var isPlayingIdleMotion: Bool = false
    private var idleMotionTimer: Timer?
    private var idleMotionFrameIndex: Int = 0
    private var idleMotionFrames: [NSImage] = []
    private var idleMotionFrameInterval: TimeInterval = 0.2
    private var randomIdleTimer: Timer?
```

- [ ] **Step 2: Start the random idle timer in `applicationDidFinishLaunching`**

After `reloadFramesAndAnimate()`:

```swift
        scheduleRandomIdleMotion()
```

- [ ] **Step 3: Implement `togglePopover()` with interaction animation**

Replace the existing `togglePopover()`:

```swift
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        // Play interaction animation
        playInteraction()
        // Open popover simultaneously
        menuController.togglePopover(relativeTo: button)
    }
```

- [ ] **Step 4: Implement `playInteraction()`**

```swift
    private func playInteraction() {
        // Cancel any ongoing idle motion
        stopIdleMotion()

        isPlayingInteraction = true
        interactionFrameIndex = 0

        // Render interaction frames with current accessories
        let sprites = InteractionSprites.frames()
        interactionFrames = sprites.enumerated().map { (i, baseFrame) in
            var overlays: [[[UInt32?]]?] = []
            if let glasses = currentGlasses {
                overlays.append(AccessorySprites.overlay(
                    accessory: glasses, state: .normal, frameIndex: 0))
            }
            if let pants = currentPants {
                overlays.append(AccessorySprites.overlay(
                    accessory: pants, state: .normal, frameIndex: 0,
                    pantsColor: currentPantsColor))
            }
            if let hat = currentHat {
                overlays.append(AccessorySprites.overlay(
                    accessory: hat, state: .normal, frameIndex: 0))
            }
            let effect = ClaudeEffects.effectOverlay(
                activity: currentActivity, frameIndex: 0)
            return PixelArtRenderer.renderComposited(
                base: baseFrame, overlays: overlays, effect: effect)
        }

        // Stop normal animation
        frameTimer?.invalidate()

        // Show first frame
        if let first = interactionFrames.first {
            statusItem.button?.image = first
        }

        // Start interaction timer
        interactionTimer?.invalidate()
        interactionTimer = Timer.scheduledTimer(
            timeInterval: InteractionSprites.frameInterval,
            target: self,
            selector: #selector(nextInteractionFrame),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(interactionTimer!, forMode: .common)
    }

    @objc private func nextInteractionFrame() {
        interactionFrameIndex += 1
        if interactionFrameIndex >= interactionFrames.count {
            // Done — restore normal animation
            interactionTimer?.invalidate()
            interactionTimer = nil
            isPlayingInteraction = false
            reloadFramesAndAnimate()
            scheduleRandomIdleMotion()
            return
        }
        statusItem.button?.image = interactionFrames[interactionFrameIndex]
    }
```

- [ ] **Step 5: Implement idle motion system**

```swift
    private func scheduleRandomIdleMotion() {
        randomIdleTimer?.invalidate()
        let delay = TimeInterval.random(in: 15...30)
        randomIdleTimer = Timer.scheduledTimer(
            withTimeInterval: delay, repeats: false
        ) { [weak self] _ in
            self?.triggerRandomIdleMotion()
        }
    }

    private func triggerRandomIdleMotion() {
        guard !isPlayingInteraction && !isPlayingIdleMotion && !isWakingUp else {
            scheduleRandomIdleMotion()
            return
        }

        // Filter motions by current state
        let allowed = IdleMotionType.allCases.filter { $0.allowedStates.contains(currentState) }
        guard let motion = allowed.randomElement() else {
            scheduleRandomIdleMotion()
            return
        }

        playIdleMotion(motion)
    }

    private func playIdleMotion(_ motion: IdleMotionType) {
        isPlayingIdleMotion = true
        idleMotionFrameIndex = 0
        idleMotionFrameInterval = motion.frameInterval

        // Render idle motion frames with current accessories
        let sprites = IdleMotionSprites.frames(motion: motion)
        idleMotionFrames = sprites.map { baseFrame in
            var overlays: [[[UInt32?]]?] = []
            if let glasses = currentGlasses {
                overlays.append(AccessorySprites.overlay(
                    accessory: glasses, state: currentState, frameIndex: 0))
            }
            if let pants = currentPants {
                overlays.append(AccessorySprites.overlay(
                    accessory: pants, state: currentState, frameIndex: 0,
                    pantsColor: currentPantsColor))
            }
            if let hat = currentHat {
                overlays.append(AccessorySprites.overlay(
                    accessory: hat, state: currentState, frameIndex: 0))
            }
            let effect = ClaudeEffects.effectOverlay(
                activity: currentActivity, frameIndex: 0)
            return PixelArtRenderer.renderComposited(
                base: baseFrame, overlays: overlays, effect: effect)
        }

        // Pause normal animation
        frameTimer?.invalidate()

        if let first = idleMotionFrames.first {
            statusItem.button?.image = first
        }

        idleMotionTimer?.invalidate()
        idleMotionTimer = Timer.scheduledTimer(
            timeInterval: idleMotionFrameInterval,
            target: self,
            selector: #selector(nextIdleMotionFrame),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(idleMotionTimer!, forMode: .common)
    }

    @objc private func nextIdleMotionFrame() {
        idleMotionFrameIndex += 1
        if idleMotionFrameIndex >= idleMotionFrames.count {
            stopIdleMotion()
            reloadFramesAndAnimate()
            scheduleRandomIdleMotion()
            return
        }
        statusItem.button?.image = idleMotionFrames[idleMotionFrameIndex]
    }

    private func stopIdleMotion() {
        idleMotionTimer?.invalidate()
        idleMotionTimer = nil
        isPlayingIdleMotion = false
    }
```

- [ ] **Step 6: Update `onSleep` and `onWake` to handle new timers**

```swift
    @objc private func onSleep() {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
        wakeUpTimer?.invalidate()
        interactionTimer?.invalidate()
        idleMotionTimer?.invalidate()
        randomIdleTimer?.invalidate()
    }

    @objc private func onWake() {
        startStatePolling()
        reloadFramesAndAnimate()
        scheduleRandomIdleMotion()
    }
```

- [ ] **Step 7: Commit**

```bash
git add pet/ClaudePet/Sources/AppDelegate.swift
git commit -m "feat: add click interaction animation and random idle motions to AppDelegate"
```

---

### Task 12: Update `install.sh` build command

**Files:**
- Modify: `pet/install.sh:43-63`

- [ ] **Step 1: Add new Swift files to swiftc command**

Add 4 new source files to the `swiftc` command:

```bash
swiftc -o "build/$APP_NAME" \
  -target arm64-apple-macos13.0 \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/AccessoryType.swift \
  Sources/ProgressTracker.swift \
  Sources/PantsColorPalette.swift \
  Sources/NotificationManager.swift \
  Sources/PixelArtRenderer.swift \
  Sources/CollectionView.swift \
  Sources/StatusMenuController.swift \
  Sources/UpdateChecker.swift \
  Sources/Sprites/ClaudeSprites.swift \
  Sources/Sprites/ClaudeEffects.swift \
  Sources/Sprites/AccessorySprites.swift \
  Sources/Sprites/PantsSprites.swift \
  Sources/Sprites/InteractionSprites.swift \
  Sources/Sprites/IdleMotionSprites.swift \
  -framework Cocoa \
  -framework ServiceManagement \
  -framework SwiftUI \
  -framework UserNotifications \
  -O 2>&1 || { echo -e "${RED}Build failed${NC}"; exit 1; }
```

- [ ] **Step 2: Commit**

```bash
git add pet/install.sh
git commit -m "feat: add new sprite and color palette files to build command"
```

---

### Task 13: Build and verify

- [ ] **Step 1: Build the Swift app**

Run:
```bash
cd /Users/hoyana/Desktop/01_sideproject/claude-hud/pet/ClaudePet && mkdir -p build && swiftc -o build/OhMyClawd \
  -target arm64-apple-macos13.0 \
  Sources/main.swift \
  Sources/AppDelegate.swift \
  Sources/PetStateReader.swift \
  Sources/PetStateMachine.swift \
  Sources/AccessoryType.swift \
  Sources/ProgressTracker.swift \
  Sources/PantsColorPalette.swift \
  Sources/NotificationManager.swift \
  Sources/PixelArtRenderer.swift \
  Sources/CollectionView.swift \
  Sources/StatusMenuController.swift \
  Sources/UpdateChecker.swift \
  Sources/Sprites/ClaudeSprites.swift \
  Sources/Sprites/ClaudeEffects.swift \
  Sources/Sprites/AccessorySprites.swift \
  Sources/Sprites/PantsSprites.swift \
  Sources/Sprites/InteractionSprites.swift \
  Sources/Sprites/IdleMotionSprites.swift \
  -framework Cocoa \
  -framework ServiceManagement \
  -framework SwiftUI \
  -framework UserNotifications \
  -O
```

Expected: Build succeeds with no errors.

- [ ] **Step 2: Fix any compilation errors**

If there are errors, fix them and rebuild.

- [ ] **Step 3: Manual test checklist**

1. Run the app, verify it starts with the pet in menu bar
2. Click the pet — verify jump+wave animation plays while popover opens
3. Check popover — verify "Pants" section appears between Glasses and Progress
4. Wait 15-30 seconds — verify a random idle motion (blink/wave/tilt/stretch) plays
5. If you have test data: manually set `colorChangeTickets: 1` in `~/.claude/pet/progress.json`, verify the color change button appears and works
6. Verify hat + glasses + pants all render together without overlap issues

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete pants accessory, color gacha, click interaction, and idle motions"
```
