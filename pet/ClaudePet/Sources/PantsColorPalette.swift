import Foundation

// ============================================================================
// MARK: - Pants Sentinel Colors (used in pants sprite templates)
// ============================================================================
let PANTS_MAIN_SENTINEL   = UInt32(0xFFFE0001)
let PANTS_DARK_SENTINEL   = UInt32(0xFFFE0002)
let PANTS_DETAIL_SENTINEL = UInt32(0xFFFE0003)

// ============================================================================
// MARK: - Pants Color (separate from body color)
// ============================================================================

struct PantsColor {
    let main: UInt32
    let dark: UInt32
    let detail: UInt32
}

struct PantsColorPalette {
    // Fixed pants color: blue denim
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
                default:                   return px
                }
            }
        }
    }
}

// ============================================================================
// MARK: - Body Color (character main/shadow/highlight recoloring via gacha)
// ============================================================================

let BODY_DEFAULT_MAIN      = UInt32(0xFFD97757)
let BODY_DEFAULT_SHADOW    = UInt32(0xFFBF6347)
let BODY_DEFAULT_HIGHLIGHT = UInt32(0xFFE89070)

struct BodyColor: Codable, Equatable {
    let name: String
    let displayName: String
    let displayNameKO: String
    let main: UInt32
    let dark: UInt32
    let detail: UInt32

    enum CodingKeys: String, CodingKey {
        case name, displayName, displayNameKO, main, dark, detail
    }

    init(name: String, displayName: String, displayNameKO: String,
         main: UInt32, dark: UInt32, detail: UInt32) {
        self.name = name; self.displayName = displayName; self.displayNameKO = displayNameKO
        self.main = main; self.dark = dark; self.detail = detail
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name          = try c.decode(String.self, forKey: .name)
        displayName   = try c.decode(String.self, forKey: .displayName)
        displayNameKO = try c.decode(String.self, forKey: .displayNameKO)
        main          = UInt32(bitPattern: try c.decode(Int32.self, forKey: .main))
        dark          = UInt32(bitPattern: try c.decode(Int32.self, forKey: .dark))
        detail        = UInt32(bitPattern: try c.decode(Int32.self, forKey: .detail))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(displayNameKO, forKey: .displayNameKO)
        try c.encode(Int32(bitPattern: main), forKey: .main)
        try c.encode(Int32(bitPattern: dark), forKey: .dark)
        try c.encode(Int32(bitPattern: detail), forKey: .detail)
    }

    /// NSColor from the main body color (for UI preview)
    var nsColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        let r = CGFloat((main >> 16) & 0xFF) / 255.0
        let g = CGFloat((main >> 8) & 0xFF) / 255.0
        let b = CGFloat(main & 0xFF) / 255.0
        return (r, g, b)
    }
}

struct BodyColorPalette {
    static let defaultColor = BodyColor(
        name: "terracotta", displayName: "Terracotta", displayNameKO: "테라코타",
        main: BODY_DEFAULT_MAIN, dark: BODY_DEFAULT_SHADOW, detail: BODY_DEFAULT_HIGHLIGHT
    )

    static let colors: [BodyColor] = [
        defaultColor,
        BodyColor(name: "blue",    displayName: "Blue",    displayNameKO: "파란색",
                  main: 0xFF4A90D9, dark: 0xFF2E6CB8, detail: 0xFF7AB5F0),
        BodyColor(name: "red",     displayName: "Red",     displayNameKO: "빨간색",
                  main: 0xFFE05555, dark: 0xFFC03030, detail: 0xFFFF8888),
        BodyColor(name: "green",   displayName: "Green",   displayNameKO: "초록색",
                  main: 0xFF5DAF5D, dark: 0xFF3D8F3D, detail: 0xFF88D088),
        BodyColor(name: "purple",  displayName: "Purple",  displayNameKO: "보라색",
                  main: 0xFF9B6DC8, dark: 0xFF7B4DA8, detail: 0xFFBB90E0),
        BodyColor(name: "gold",    displayName: "Gold",    displayNameKO: "골드",
                  main: 0xFFD4A843, dark: 0xFFB88A28, detail: 0xFFEEC870),
        BodyColor(name: "pink",    displayName: "Pink",    displayNameKO: "분홍색",
                  main: 0xFFE88CA0, dark: 0xFFD06880, detail: 0xFFFBB0C0),
        BodyColor(name: "navy",    displayName: "Navy",    displayNameKO: "네이비",
                  main: 0xFF4A5A8A, dark: 0xFF2E3A6A, detail: 0xFF7080B0),
        BodyColor(name: "mint",    displayName: "Mint",    displayNameKO: "민트",
                  main: 0xFF5DC0B0, dark: 0xFF3AA090, detail: 0xFF88E0D0),
        BodyColor(name: "coral",   displayName: "Coral",   displayNameKO: "코랄",
                  main: 0xFFE07050, dark: 0xFFC05030, detail: 0xFFFF9878),
    ]

    static func color(named name: String) -> BodyColor {
        colors.first { $0.name == name } ?? defaultColor
    }

    static func randomColor() -> BodyColor {
        colors.randomElement() ?? defaultColor
    }

    /// Replace default body colors in a sprite grid with the chosen body color.
    static func applyColor(_ color: BodyColor, to grid: [[UInt32?]]) -> [[UInt32?]] {
        if color.name == "terracotta" { return grid }
        return grid.map { row in
            row.map { pixel in
                guard let px = pixel else { return nil }
                switch px {
                case BODY_DEFAULT_MAIN:      return color.main
                case BODY_DEFAULT_SHADOW:    return color.dark
                case BODY_DEFAULT_HIGHLIGHT: return color.detail
                default:                     return px
                }
            }
        }
    }
}
