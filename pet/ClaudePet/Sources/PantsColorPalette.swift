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
