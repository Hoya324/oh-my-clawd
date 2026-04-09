import Foundation

// MARK: - Accessory Color Aliases
private let Rd = UInt32(0xFFE53935)   // Red
private let Dr = UInt32(0xFFC62828)   // Dark red
private let Wh = UInt32(0xFFFFFFFF)   // White
private let Bk = UInt32(0xFF2D2D2D)   // Black
private let Db = UInt32(0xFF1A1A1A)   // Dark black
private let Gd = UInt32(0xFFF59E0B)   // Gold
private let Dg = UInt32(0xFFD48806)   // Dark gold
private let Br = UInt32(0xFF8B5E3C)   // Brown
private let Lb = UInt32(0xFFA0785C)   // Light brown
private let Gy = UInt32(0xFF666666)   // Gray
private let Lg = UInt32(0xFF999999)   // Light gray
private let Gn = UInt32(0xFF4CAF50)   // Green
private let Bl = UInt32(0xFF2196F3)   // Blue
private let Yl = UInt32(0xFFFFEB3B)   // Yellow
private let Pp = UInt32(0xFF9C27B0)   // Purple
private let Pk = UInt32(0xFFF5A0B8)   // Pink
private let T: UInt32? = nil          // Transparent

// MARK: - AccessorySprites

struct AccessorySprites {

    /// Get overlay for an accessory at a given state and frame
    static func overlay(accessory: AccessoryType, state: PetState, frameIndex: Int) -> [[UInt32?]]? {
        let base = baseOverlay(accessory: accessory)
        guard let base = base else { return nil }
        let yOffset = verticalOffset(state: state, frameIndex: frameIndex)
        if yOffset == 0 { return base }
        return shiftVertically(base, by: yOffset)
    }

    // MARK: - Private Helpers

    /// Shift a 32x32 grid vertically (positive = down, negative = up)
    private static func shiftVertically(_ grid: [[UInt32?]], by offset: Int) -> [[UInt32?]] {
        let size = grid.count
        let emptyRow = [UInt32?](repeating: nil, count: size > 0 ? grid[0].count : 32)
        var result = [[UInt32?]](repeating: emptyRow, count: size)
        for y in 0..<size {
            let newY = y + offset
            if newY >= 0 && newY < size {
                result[newY] = grid[y]
            }
        }
        return result
    }

    /// Vertical offset based on character bounce per state/frame
    private static func verticalOffset(state: PetState, frameIndex: Int) -> Int {
        switch state {
        case .idle:
            return 0
        case .wakeUp:
            // Frame 2 jumps up 2px, frame 3 back to 0
            return frameIndex == 2 ? -2 : 0
        case .normal:
            // Bounce: frames 1,2 up 1px
            return (frameIndex == 1 || frameIndex == 2) ? -1 : 0
        case .busy:
            return 0
        case .bloated:
            return 0
        case .stressed:
            // Trembles but doesn't move vertically
            return 0
        case .tired:
            // Head droops down
            return frameIndex == 1 ? 1 : 0
        case .collab:
            // Energetic bounce
            return (frameIndex == 1) ? -1 : 0
        }
    }

    /// Dispatch to the correct base overlay
    private static func baseOverlay(accessory: AccessoryType) -> [[UInt32?]]? {
        switch accessory {
        case .cap:          return capOverlay
        case .partyHat:     return partyHatOverlay
        case .santaHat:     return santaHatOverlay
        case .silkHat:      return silkHatOverlay
        case .cowboyHat:    return cowboyHatOverlay
        case .hornRimmed:   return hornRimmedOverlay
        case .sunglasses:   return sunglassesOverlay
        case .roundGlasses: return roundGlassesOverlay
        case .starGlasses:  return starGlassesOverlay
        case .jeans, .shorts, .slacks, .joggers, .cargo:
            return nil  // pants handled by PantsSprites
        }
    }
}

// ============================================================================
// MARK: - HAT OVERLAYS
// ============================================================================

// -----------------------------------------------------------------------------
// MARK: Cap (Baseball cap) - Red dome with dark red brim
// Character head top outline at row 6, cols 5-22
// Cap dome: rows 3-5, cols 7-21; Brim: rows 6-7, cols 5-24
// -----------------------------------------------------------------------------
private let capOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,Rd,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3: button
    [T,T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T,T,T], // row 4: dome top
    [T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T,T], // row 5: dome
    [T,T,T,T,T,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,Dr,T,T,T,T,T,T,T], // row 6: brim
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,Dr,Dr,Dr,Dr,T,T,T,T,T,T], // row 7: brim extension right
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
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Party Hat (꼬깔) - Pointed cone, alternating red/yellow stripes
// Apex at row 1 col 14, widens to row 6
// Gold pom-pom at tip (row 0-1)
// -----------------------------------------------------------------------------
private let partyHatOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,Gd,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0: pom-pom
    [T,T,T,T,T,T,T,T,T,T,T,T,T,Gd,Gd,Gd,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1: pom-pom base + apex
    [T,T,T,T,T,T,T,T,T,T,T,T,T,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2: red stripe
    [T,T,T,T,T,T,T,T,T,T,T,T,Yl,Yl,Yl,Yl,Yl,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3: yellow stripe
    [T,T,T,T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4: red stripe
    [T,T,T,T,T,T,T,T,T,T,Yl,Yl,Yl,Yl,Yl,Yl,Yl,Yl,Yl,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5: yellow stripe
    [T,T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T,T,T], // row 6: red base
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
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Santa Hat - Red dome, floppy tip drooping right, white fur trim
// Red dome rows 2-5, floppy tip rows 1-3 cols 20-24, white pom-pom, fur band row 6
// -----------------------------------------------------------------------------
private let santaHatOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,Wh,Wh,T,T,T,T,T,T,T], // row 1: pom-pom
    [T,T,T,T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Wh,Wh,Wh,T,T,T,T,T,T,T], // row 2: dome top + floppy tip
    [T,T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T], // row 3: dome
    [T,T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T,T], // row 4: dome
    [T,T,T,T,T,T,T,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,Rd,T,T,T,T,T,T,T,T,T,T], // row 5: dome bottom
    [T,T,T,T,T,T,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,Wh,T,T,T,T,T,T,T,T,T], // row 6: fur band
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
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Silk Hat (Top Hat) - Tall black crown with gray band, wide brim
// Crown rows 0-5, brim row 6, highlight band row 3
// -----------------------------------------------------------------------------
private let silkHatOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0: crown top
    [T,T,T,T,T,T,T,T,T,Db,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Db,T,T,T,T,T,T,T,T,T,T,T,T], // row 1: crown
    [T,T,T,T,T,T,T,T,T,Db,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Db,T,T,T,T,T,T,T,T,T,T,T,T], // row 2: crown
    [T,T,T,T,T,T,T,T,T,Db,Gy,Gy,Gy,Gy,Gy,Gy,Gy,Gy,Gy,Db,T,T,T,T,T,T,T,T,T,T,T,T], // row 3: band
    [T,T,T,T,T,T,T,T,T,Db,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Db,T,T,T,T,T,T,T,T,T,T,T,T], // row 4: crown
    [T,T,T,T,T,T,T,T,T,Db,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Db,T,T,T,T,T,T,T,T,T,T,T,T], // row 5: crown bottom
    [T,T,T,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,T,T,T,T,T,T,T], // row 6: brim
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
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Cowboy Hat - Wide brim, brown with gold band
// Crown rows 2-5, band row 4, wide brim rows 6-7 curving up at edges
// -----------------------------------------------------------------------------
private let cowboyHatOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,Br,Br,Br,Br,Br,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2: crown top
    [T,T,T,T,T,T,T,T,T,T,Lb,Br,Br,Br,Br,Br,Br,Br,Lb,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3: crown with highlight
    [T,T,T,T,T,T,T,T,T,T,Dg,Dg,Dg,Dg,Dg,Dg,Dg,Dg,Dg,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4: gold band
    [T,T,T,T,T,T,T,T,T,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,T,T,T,T,T,T,T,T,T,T,T,T], // row 5: crown bottom
    [T,T,T,T,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,Br,T,T,T,T,T,T,T,T], // row 6: wide brim
    [T,T,T,Br,Br,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,Br,Br,T,T,T,T,T,T], // row 7: brim edges curve up
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
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
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
// MARK: - GLASSES OVERLAYS
// ============================================================================

// -----------------------------------------------------------------------------
// MARK: Horn-rimmed (뿔테) - Thick black square frames
// Eyes at rows 11-13, left cols 8-10, right cols 18-20
// Frames: thick 2px border squares around each eye, bridge between
// Left frame: rows 9-14, cols 6-12; Right frame: rows 9-14, cols 16-22
// Bridge: rows 11-12, cols 12-16
// -----------------------------------------------------------------------------
private let hornRimmedOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 9: top frame border
    [T,T,T,T,T,T,Bk,Bk,T,T,T,Bk,Bk,T,T,T,Bk,Bk,T,T,T,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 10: left/right of lens
    [T,T,T,T,T,T,Bk,Bk,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 11: sides + bridge
    [T,T,T,T,T,T,Bk,Bk,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 12: sides + bridge
    [T,T,T,T,T,T,Bk,Bk,T,T,T,Bk,Bk,T,T,T,Bk,Bk,T,T,T,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 13: left/right of lens
    [T,T,T,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 14: bottom frame border
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Sunglasses - Dark opaque lenses, covers eyes completely
// Left lens: rows 10-13, cols 6-12; Right lens: rows 10-13, cols 16-22
// Bridge: row 11, cols 12-16; Shine highlights
// -----------------------------------------------------------------------------
private let sunglassesOverlay: [[UInt32?]] = [
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
    [T,T,T,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 10: top lens border
    [T,T,T,T,T,T,Bk,Gy,Db,Db,Db,Db,Bk,Bk,Bk,Bk,Bk,Gy,Db,Db,Db,Db,Bk,T,T,T,T,T,T,T,T,T], // row 11: lens + bridge + shine
    [T,T,T,T,T,T,Bk,Db,Db,Db,Db,Db,Bk,T,T,T,Bk,Db,Db,Db,Db,Db,Bk,T,T,T,T,T,T,T,T,T], // row 12: lens middle
    [T,T,T,T,T,T,Bk,Db,Db,Db,Db,Db,Bk,T,T,T,Bk,Db,Db,Db,Db,Db,Bk,T,T,T,T,T,T,T,T,T], // row 13: lens bottom
    [T,T,T,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,Bk,Bk,Bk,Bk,Bk,Bk,Bk,T,T,T,T,T,T,T,T,T], // row 14: bottom border
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Round Glasses - Circular gold frames, transparent lenses
// Circular frames around each eye, thin gold frame
// Left circle: center ~(9,12), Right circle: center ~(19,12)
// Bridge: row 12, cols 12-16
// -----------------------------------------------------------------------------
private let roundGlassesOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,Gd,Gd,Gd,Gd,T,T,T,T,T,T,Gd,Gd,Gd,Gd,T,T,T,T,T,T,T,T,T,T,T], // row 9: top arc
    [T,T,T,T,T,T,Gd,T,T,T,T,Gd,T,T,T,T,Gd,T,T,T,T,Gd,T,T,T,T,T,T,T,T,T,T], // row 10: sides
    [T,T,T,T,T,T,Gd,T,T,T,T,Gd,Gd,Gd,Gd,Gd,Gd,T,T,T,T,Gd,T,T,T,T,T,T,T,T,T,T], // row 11: sides + bridge
    [T,T,T,T,T,T,Gd,T,T,T,T,Gd,Dg,Dg,Dg,Dg,Gd,T,T,T,T,Gd,T,T,T,T,T,T,T,T,T,T], // row 12: sides + bridge
    [T,T,T,T,T,T,Gd,T,T,T,T,Gd,T,T,T,T,Gd,T,T,T,T,Gd,T,T,T,T,T,T,T,T,T,T], // row 13: sides
    [T,T,T,T,T,T,T,Gd,Gd,Gd,Gd,T,T,T,T,T,T,Gd,Gd,Gd,Gd,T,T,T,T,T,T,T,T,T,T,T], // row 14: bottom arc
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]

// -----------------------------------------------------------------------------
// MARK: Star Glasses - Star-shaped purple frames, transparent inside
// 5-pointed star outlines around each eye position
// Left star center ~(9, 11.5), Right star center ~(19, 11.5)
// Bridge: row 12, cols 12-16 (Pp)
// At this tiny size, stars are simplified to a recognizable cross/diamond shape
// -----------------------------------------------------------------------------
private let starGlassesOverlay: [[UInt32?]] = [
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 8
    [T,T,T,T,T,T,T,T,T,Pp,T,T,T,T,T,T,T,T,T,Pp,T,T,T,T,T,T,T,T,T,T,T,T], // row 9: top point
    [T,T,T,T,T,T,T,Pp,Pp,Pp,Pp,Pp,T,T,T,T,T,Pp,Pp,Pp,Pp,Pp,T,T,T,T,T,T,T,T,T,T], // row 10: upper arms
    [T,T,T,T,T,T,Pp,T,T,T,T,T,Pp,Pp,Pp,Pp,Pp,T,T,T,T,T,Pp,T,T,T,T,T,T,T,T,T], // row 11: left/right sides + bridge
    [T,T,T,T,T,T,T,Pp,T,T,T,Pp,Pp,Pp,Pp,Pp,Pp,Pp,T,T,T,Pp,T,T,T,T,T,T,T,T,T,T], // row 12: inner + bridge
    [T,T,T,T,T,T,Pp,T,T,T,T,T,Pp,T,T,T,Pp,T,T,T,T,T,Pp,T,T,T,T,T,T,T,T,T], // row 13: lower arms
    [T,T,T,T,T,Pp,T,Pp,T,T,T,Pp,T,T,T,T,T,Pp,T,T,T,Pp,T,Pp,T,T,T,T,T,T,T,T], // row 14: bottom points
    [T,T,T,T,T,T,Pp,T,T,T,Pp,T,T,T,T,T,T,T,Pp,T,T,T,Pp,T,T,T,T,T,T,T,T,T], // row 15: bottom tips
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 18
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 19
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 20
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 21
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 22
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // row 31
]
