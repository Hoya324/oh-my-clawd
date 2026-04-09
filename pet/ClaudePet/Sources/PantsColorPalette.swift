import Foundation

// MARK: - Pants Sentinel Colors (used in sprite templates)
let PANTS_MAIN_SENTINEL   = UInt32(0xFFFE0001)
let PANTS_DARK_SENTINEL   = UInt32(0xFFFE0002)
let PANTS_DETAIL_SENTINEL = UInt32(0xFFFE0003)

// MARK: - PantsColor

struct PantsColor: Codable, Equatable {
    let name: String
    let displayName: String
    let displayNameKO: String
    let main: UInt32
    let dark: UInt32
    let detail: UInt32

    // Custom Codable: encode UInt32 fields as Int for JSON compatibility
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
        name         = try c.decode(String.self, forKey: .name)
        displayName  = try c.decode(String.self, forKey: .displayName)
        displayNameKO = try c.decode(String.self, forKey: .displayNameKO)
        main         = UInt32(bitPattern: try c.decode(Int32.self, forKey: .main))
        dark         = UInt32(bitPattern: try c.decode(Int32.self, forKey: .dark))
        detail       = UInt32(bitPattern: try c.decode(Int32.self, forKey: .detail))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name,          forKey: .name)
        try c.encode(displayName,   forKey: .displayName)
        try c.encode(displayNameKO, forKey: .displayNameKO)
        try c.encode(Int32(bitPattern: main),   forKey: .main)
        try c.encode(Int32(bitPattern: dark),   forKey: .dark)
        try c.encode(Int32(bitPattern: detail), forKey: .detail)
    }
}

// MARK: - PantsColorPalette

struct PantsColorPalette {

    static let colors: [PantsColor] = [
        PantsColor(name: "blue",   displayName: "Blue",       displayNameKO: "파란색",
                   main: 0xFF2196F3, dark: 0xFF1565C0, detail: 0xFFE0E0E0),
        PantsColor(name: "red",    displayName: "Red",        displayNameKO: "빨간색",
                   main: 0xFFE53935, dark: 0xFFC62828, detail: 0xFFFFCDD2),
        PantsColor(name: "green",  displayName: "Green",      displayNameKO: "초록색",
                   main: 0xFF4CAF50, dark: 0xFF2E7D32, detail: 0xFFC8E6C9),
        PantsColor(name: "purple", displayName: "Purple",     displayNameKO: "보라색",
                   main: 0xFF7C3AED, dark: 0xFF5B21B6, detail: 0xFFE1BEE7),
        PantsColor(name: "brown",  displayName: "Brown",      displayNameKO: "갈색",
                   main: 0xFF8B5E3C, dark: 0xFF6B4226, detail: 0xFFD7CCC8),
        PantsColor(name: "black",  displayName: "Black",      displayNameKO: "검정색",
                   main: 0xFF333333, dark: 0xFF1A1A1A, detail: 0xFF555555),
        PantsColor(name: "white",  displayName: "White",      displayNameKO: "흰색",
                   main: 0xFFEEEEEE, dark: 0xFFCCCCCC, detail: 0xFFFFFFFF),
        PantsColor(name: "yellow", displayName: "Yellow",     displayNameKO: "노란색",
                   main: 0xFFFFD93D, dark: 0xFFF59E0B, detail: 0xFFFFF9C4),
        PantsColor(name: "pink",   displayName: "Pink",       displayNameKO: "분홍색",
                   main: 0xFFF5A0B8, dark: 0xFFE91E8D, detail: 0xFFFCE4EC),
        PantsColor(name: "khaki",  displayName: "Khaki",      displayNameKO: "카키색",
                   main: 0xFFBDB76B, dark: 0xFF8B8000, detail: 0xFFE8E5C0),
    ]

    static let defaultColor: PantsColor = colors[0]

    static func color(named name: String) -> PantsColor {
        colors.first { $0.name == name } ?? defaultColor
    }

    static func randomColor() -> PantsColor {
        colors.randomElement() ?? defaultColor
    }

    /// Replace sentinel pixels in a sprite grid with the actual color values.
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
