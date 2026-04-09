import Foundation

// MARK: - Pants Color Aliases (sentinel-based)
private let PC: UInt32? = PANTS_MAIN_SENTINEL    // pants main color
private let PD: UInt32? = PANTS_DARK_SENTINEL    // pants dark color
private let PX: UInt32? = PANTS_DETAIL_SENTINEL  // pants detail color
private let T:  UInt32? = nil                    // transparent

// MARK: - PantsSprites

struct PantsSprites {

    /// Returns the base 32x32 overlay grid for the given pants type.
    /// Returns nil if the accessory is not a pants type.
    /// Colors use sentinel values; call PantsColorPalette.applyColor(_:to:) before rendering.
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
// MARK: - JEANS OVERLAY
// Full coverage rows 19-26. Waistband row 19 with center seam (PD).
// Pocket stitch detail (PX) at cols 10 and 21 on row 21.
// Leg cuffs rows 25-26 in PD.
// ============================================================================
private let jeansOverlay: [[UInt32?]] = [
    // Rows 0-18: transparent (head/body, not covered by pants)
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 18
    // Row 19: waistband — all PD with center seam at col 15-16
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // 19
    // Row 20: upper thigh — solid PC
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // 20
    // Row 21: thigh with pocket stitch at cols 10 and 21
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PC,T,T,T,T], // 21
    // Row 22: lower thigh — solid PC
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // 22
    // Row 23: upper legs at cols 6-7, 10-11, 20-21, 24-25
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 23
    // Row 24: mid legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 24
    // Row 25: leg cuffs in PD
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // 25
    // Row 26: leg cuffs in PD
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // 26
    // Rows 27-31: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 31
]

// ============================================================================
// MARK: - SHORTS OVERLAY
// Coverage only rows 19-22. Hem at row 22 in PD. No leg coverage (rows 23-26 transparent).
// ============================================================================
private let shortsOverlay: [[UInt32?]] = [
    // Rows 0-18: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 18
    // Row 19: waistband in PD
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // 19
    // Row 20: upper shorts body
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // 20
    // Row 21: mid shorts body
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // 21
    // Row 22: hem in PD
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // 22
    // Rows 23-31: transparent (no leg coverage)
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 23
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 31
]

// ============================================================================
// MARK: - SLACKS OVERLAY
// Full coverage rows 19-26. Belt line row 19 all PD.
// Crease lines (PX) at cols 9 and 22 through rows 20-25.
// ============================================================================
private let slacksOverlay: [[UInt32?]] = [
    // Rows 0-18: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 18
    // Row 19: belt line all PD
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // 19
    // Row 20: with crease lines at cols 9 and 22
    [T,T,T,T,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,T,T,T,T], // 20
    // Row 21: with crease lines at cols 9 and 22
    [T,T,T,T,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,T,T,T,T], // 21
    // Row 22: with crease lines at cols 9 and 22
    [T,T,T,T,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,PC,PC,T,T,T,T], // 22
    // Row 23: legs with crease at col 9 (left pair cols 6-7, 10-11) and col 22 (right pair cols 20-21, 24-25)
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 23
    // Row 24: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 24
    // Row 25: legs with crease — left inner legs at col 7 (inner crease) and right inner at col 20
    [T,T,T,T,T,T,PC,PX,T,T,PX,PC,T,T,T,T,T,T,T,T,PC,PX,T,T,PX,PC,T,T,T,T,T,T], // 25
    // Row 26: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 26
    // Rows 27-31: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 31
]

// ============================================================================
// MARK: - JOGGERS OVERLAY
// Full coverage rows 19-26. Side stripe (PX) at cols 6 and 24 on rows 21-22.
// Elastic cuffs rows 25-26 in PD.
// ============================================================================
private let joggersOverlay: [[UInt32?]] = [
    // Rows 0-18: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 18
    // Row 19: waistband in PD
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // 19
    // Row 20: upper joggers body, no stripe yet
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // 20
    // Row 21: side stripe at cols 6 and 24
    [T,T,T,T,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,T,T,T,T], // 21
    // Row 22: side stripe at cols 6 and 24
    [T,T,T,T,PC,PC,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PC,PC,PC,T,T,T,T], // 22
    // Row 23: legs — left pair cols 6-7, 10-11; right pair cols 20-21, 24-25
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 23
    // Row 24: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 24
    // Row 25: elastic cuffs in PD
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // 25
    // Row 26: elastic cuffs in PD
    [T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T,T,T,PD,PD,T,T,PD,PD,T,T,T,T,T,T], // 26
    // Rows 27-31: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 31
]

// ============================================================================
// MARK: - CARGO OVERLAY
// Full coverage rows 19-26.
// Side pockets (PX box) at cols 4-6 and 25-27 on rows 21-22,
// with pocket flap detail (PD inside PX border).
// ============================================================================
private let cargoOverlay: [[UInt32?]] = [
    // Rows 0-18: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 2
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 3
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 4
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 5
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 6
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 7
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 8
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 9
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 10
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 11
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 12
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 13
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 14
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 15
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 16
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 17
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 18
    // Row 19: waistband in PD
    [T,T,T,T,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,PD,T,T,T,T], // 19
    // Row 20: upper cargo body
    [T,T,T,T,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,T,T,T,T], // 20
    // Row 21: pocket flap top border (PX) at cols 4-6 left and 24-26 right; PD inside
    [T,T,T,T,PX,PX,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PX,PX,T,T,T,T], // 21
    // Row 22: pocket body — PX border left col 4, PD fill cols 5, PX border col 6; right mirrored
    [T,T,T,T,PX,PD,PX,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PC,PX,PD,PX,T,T,T,T], // 22
    // Row 23: legs — left pair cols 6-7, 10-11; right pair cols 20-21, 24-25
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 23
    // Row 24: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 24
    // Row 25: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 25
    // Row 26: legs
    [T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T,T,T,PC,PC,T,T,PC,PC,T,T,T,T,T,T], // 26
    // Rows 27-31: transparent
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T], // 31
]
