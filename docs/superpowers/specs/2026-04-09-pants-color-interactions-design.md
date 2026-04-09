# Pants Accessory, Color Gacha, Click Interaction & Dynamic Idle Motions

**Date**: 2026-04-09

## Context

Clawd currently has 9 accessories (5 hats + 4 glasses) across 2 categories, all with deterministic frame-based animations. The user wants to:
1. Add a "pants" accessory category with 4-5 types and unlock conditions
2. Add a color randomization system (gacha) — every 8 hours of usage, earn a color-change ticket; use it in the popover UI to randomize pants color
3. Click on the pet to trigger jump + hand wave animation (while popover opens simultaneously)
4. Add probabilistic idle behaviors (hand wave, blink, head tilt, stretch) for a more lively pet

## 1. Pants Accessory Category

### Data Model Changes

**`AccessoryType.swift`**: Add `pants` to `AccessoryCategory` and 5 new cases:

```
AccessoryCategory: hat | glasses | pants

New AccessoryType cases:
  jeans       — category: pants — "청바지"
  shorts      — category: pants — "반바지"
  slacks      — category: pants — "정장바지"
  joggers     — category: pants — "운동바지"
  cargo       — category: pants — "카고바지"
```

### Unlock Conditions

| Accessory | Condition | Threshold |
|-----------|-----------|-----------|
| jeans | totalTimeMinutes | 900 (15 hours) |
| shorts | totalSessions | 100 |
| slacks | totalTokens | 1,000,000 |
| joggers | totalAgentRuns | 100 |
| cargo | totalTimeMinutes | 3000 (50 hours) |

### Sprite Rendering

- 32x32 overlay grid positioned on lower body (rows ~20-28)
- Compositing order: base character → glasses → pants → hat → effect
- Pants overlay needs `verticalOffset()` logic matching existing bounce patterns
- Each pants type has distinct silhouette (shorts = shorter, slacks = sharp creases, etc.)

### Files to Modify

- `AccessoryType.swift` — add `pants` category and 5 cases
- `AccessorySprites.swift` — add 5 pants overlay grids + `verticalOffset` for pants
- `PixelArtRenderer.swift` — add `pants` parameter to `renderFrame()`, insert pants overlay between glasses and hat
- `ProgressTracker.swift` — add `selectedPants`, `selectPants()`, `unlockProgress()` for pants
- `CollectionView.swift` — add pants grid section, `selectPants()` in ViewModel
- `AppDelegate.swift` — track `currentPants`, pass to renderer
- `pet-aggregator.mjs` — add pants unlock conditions to `UNLOCK_CONDITIONS`
- `progress.json` schema — add `selectedPants` field

## 2. Color System (Gacha)

### Mechanism

- Every 8 cumulative hours of usage (480 minutes), user earns 1 "color change ticket"
- Tickets accumulate (no limit)
- In the popover UI, a "Color Change" button appears when `colorChangeTickets > 0`
- Clicking the button consumes 1 ticket and randomly assigns a new pants color
- The selected color persists until the next change

### Color Palette (~10 colors)

| Name | Main Color | Dark Variant | Display Name |
|------|-----------|-------------|-------------|
| blue | 0xFF2196F3 | 0xFF1565C0 | 파란색 |
| red | 0xFFE53935 | 0xFFC62828 | 빨간색 |
| green | 0xFF4CAF50 | 0xFF2E7D32 | 초록색 |
| purple | 0xFF7C3AED | 0xFF5B21B6 | 보라색 |
| brown | 0xFF8B5E3C | 0xFF6B4226 | 갈색 |
| black | 0xFF333333 | 0xFF1A1A1A | 검정색 |
| white | 0xFFEEEEEE | 0xFFCCCCCC | 흰색 |
| yellow | 0xFFFFD93D | 0xFFF59E0B | 노란색 |
| pink | 0xFFF5A0B8 | 0xFFE91E8D | 핑크색 |
| khaki | 0xFFBDB76B | 0xFF8B8000 | 카키색 |

### Data Model

`progress.json` additions:
```json
{
  "pantsColor": "blue",
  "colorChangeTickets": 2,
  "lastColorTicketMinutes": 960
}
```

- `pantsColor`: current color name string (default: "blue")
- `colorChangeTickets`: accumulated tickets
- `lastColorTicketMinutes`: the `totalTimeMinutes` value at which last ticket was awarded (avoids re-awarding on restart)

### Sprite Color Application

`AccessorySprites` pants overlays use placeholder color variables (e.g., `PC` for main, `PD` for dark). At render time, `PixelArtRenderer` replaces these with the actual color pair from the selected palette entry.

Implementation approach: pants sprite grids use a template with sentinel colors. `AccessorySprites.overlay()` takes an optional `pantsColor` parameter and swaps sentinel pixels with the active color pair.

### Files to Modify

- `AccessorySprites.swift` — pants sprites use color template, `overlay()` accepts color param
- `PixelArtRenderer.swift` — pass `pantsColor` through to accessory overlay
- `ProgressTracker.swift` — add `pantsColor()`, `colorChangeTickets()`, `consumeColorTicket()` methods
- `CollectionView.swift` — add color change button UI in pants section
- `ClawdViewModel` — add `pantsColor`, `colorChangeTickets` published properties
- `pet-aggregator.mjs` — add ticket accumulation logic (every 480 min increment)
- `AppDelegate.swift` — read and pass `pantsColor`

## 3. Click Interaction (Jump + Wave)

### Animation Sequence

1. User clicks status bar icon
2. **Simultaneously**: popover opens AND jump animation starts
3. Jump animation: 6 frames total at 0.15s interval (~0.9s)
   - Frame 0-1: Crouch (character shifts down 1px)
   - Frame 2-3: Jump (character shifts up 2-3px, arms raised)
   - Frame 4-5: Land + wave (back to normal height, one arm waving)
4. After animation completes, return to normal state animation

### Implementation

- New `InteractionSprites.swift` — 6 frames of jump+wave animation (32x32 grids)
- `AppDelegate.togglePopover()`:
  1. Store current state animation
  2. Load interaction frames (with current hat/glasses/pants overlays)
  3. Start fast timer (0.15s interval)
  4. After 6 frames complete, restore original animation via `reloadFramesAndAnimate()`
  5. Call `menuController.togglePopover()` immediately (no delay)

### Files to Modify

- New file: `Sprites/InteractionSprites.swift` — jump+wave frame data
- `AppDelegate.swift` — `togglePopover()` triggers interaction animation + popover simultaneously
- `PixelArtRenderer.swift` — add `renderInteractionFrame()` or reuse existing `renderFrame()` with offset parameter

## 4. Random Idle Motions

### System Design

A timer-based system that randomly inserts brief animation sequences into the normal animation loop.

### Timer

- `idleActionTimer`: fires every 15-30 seconds (random interval, re-randomized after each fire)
- Only triggers when pet is in "calm" states: `idle`, `normal`, `tired`
- Does NOT trigger during `busy`, `stressed`, `bloated`, `wakeUp`, or interaction animations

### Motion Types

| Motion | Frames | Duration | Description |
|--------|--------|----------|-------------|
| wave | 3 | 0.2s/frame | One arm lifts up, waves, lowers |
| blink | 2 | 0.15s/frame | Eyes close briefly, reopen |
| tilt | 2 | 0.25s/frame | Head tilts slightly to one side |
| stretch | 3 | 0.3s/frame | Both arms rise up, lower back |

### Implementation

- New file: `Sprites/IdleMotionSprites.swift` — sprite data for each motion
- `AppDelegate`:
  - Add `idleMotionTimer` (NSTimer, random 15-30s interval)
  - On fire: pick random motion, temporarily replace frames, play, then restore
  - Use `isPlayingIdleMotion` flag to prevent overlap with click interactions
  - Re-randomize timer interval after each motion completes
- Motions are rendered with current accessories (hat/glasses/pants) overlaid

### Interaction Priority

```
Click interaction > Idle motion > Normal animation
```

If a click occurs during idle motion, the idle motion is immediately interrupted and replaced by the click animation.

### Files to Modify

- New file: `Sprites/IdleMotionSprites.swift` — 4 motion sprite sets
- `AppDelegate.swift` — idle motion timer, playback logic, priority handling

## Files Summary

### New Files
- `pet/ClaudePet/Sources/Sprites/InteractionSprites.swift` — click interaction frames
- `pet/ClaudePet/Sources/Sprites/IdleMotionSprites.swift` — random idle motion frames

### Modified Files
- `pet/ClaudePet/Sources/AccessoryType.swift` — pants category + 5 types
- `pet/ClaudePet/Sources/Sprites/AccessorySprites.swift` — 5 pants overlays with color template
- `pet/ClaudePet/Sources/PixelArtRenderer.swift` — pants + pantsColor params
- `pet/ClaudePet/Sources/ProgressTracker.swift` — pants selection, color tickets
- `pet/ClaudePet/Sources/CollectionView.swift` — pants grid, color change UI
- `pet/ClaudePet/Sources/AppDelegate.swift` — pants tracking, interaction anim, idle motions
- `pet/pet-aggregator.mjs` — pants unlock conditions, color ticket accumulation

## Verification

1. **Build**: `cd pet && swift build` — must compile without errors
2. **Pants rendering**: equip each pants type, verify correct overlay position across all 8 states
3. **Color change**: accumulate tickets (or manually set in progress.json), use gacha button, verify color changes
4. **Click interaction**: click pet → verify jump+wave plays while popover opens
5. **Idle motions**: wait 15-30s in normal/idle state → verify random motion plays
6. **Priority**: click during idle motion → verify click animation takes over
7. **Accessories stacking**: verify hat + glasses + pants all render correctly together
