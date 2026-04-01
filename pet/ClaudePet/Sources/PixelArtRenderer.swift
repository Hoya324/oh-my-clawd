import Cocoa

// MARK: - Color Palette
// Tamagotchi-style cute cat with cyan/white/pink theme
private let C = UInt32(0xFF06B6D4)  // Body cyan
private let D = UInt32(0xFF059BB0)  // Body dark cyan (shading)
private let W = UInt32(0xFFFFFFFF)  // White
private let B = UInt32(0xFF2D2D2D)  // Black (eyes, outline)
private let P = UInt32(0xFFF5A0B8)  // Pink (nose, mouth)
private let K = UInt32(0xFFFFB8C8)  // Cheek blush
private let O = UInt32(0xFF4A6670)  // Outline dark teal
private let Y = UInt32(0xFFF59E0B)  // Gold (crown/star for opus)
private let G = UInt32(0xFF7C3AED)  // Purple (opus accent)
private let S = UInt32(0xFF87CEEB)  // Light blue (sweat)
private let R = UInt32(0xFFFF4444)  // Red (stress !)
private let Z = UInt32(0xFFAAAAAA)  // Gray (Zzz)
private let T: UInt32? = nil        // Transparent

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

    // MARK: - Generate all frames for all states
    static func allFrames() -> [PetState: [NSImage]] {
        var result: [PetState: [NSImage]] = [:]
        for state in PetState.allCases {
            let pixelFrames = spriteFrames(for: state)
            result[state] = pixelFrames.map { render(pixels: $0) }
        }
        return result
    }

    // MARK: - Sprite Definitions (7 states x 5 frames)
    static func spriteFrames(for state: PetState) -> [[[UInt32?]]] {
        switch state {
        case .idle:     return idleFrames
        case .normal:   return normalFrames
        case .busy:     return busyFrames
        case .bloated:  return bloatedFrames
        case .stressed: return stressedFrames
        case .tired:    return tiredFrames
        case .collab:   return collabFrames
        }
    }
}

// MARK: - IDLE: Sleeping cat, curled up, Zzz
private let idleFrames: [[[UInt32?]]] = [
    // Frame 0: curled sleeping cat
    [
        [T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,Z,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,O,O,C,C,O,O,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,P,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,O,O,O,O,O,O,O,O,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: breathing in (slightly bigger body)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,O,O,C,C,O,O,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,P,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [O,D,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,O,O,O,O,O,O,O,O,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Zzz shifted
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,O,O,C,C,O,O,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,P,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,O,O,O,O,O,O,O,O,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3: breathing out (back to normal)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,Z,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,O,O,C,C,O,O,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,P,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,O,O,O,O,O,O,O,O,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4: same as 0 (loop)
    [
        [T,T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,Z,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,Z,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,O,O,C,C,O,O,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,P,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,O,O,O,O,O,O,O,O,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// MARK: - NORMAL: Walking happy cat (^.^)
private let normalFrames: [[[UInt32?]]] = [
    // Frame 0: stand, left foot forward
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,T,O,O,T,T,T,T,T],
        [T,T,T,O,O,T,T,T,T,T,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: walk, right foot forward
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,O,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,T,O,O,T,O,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,O,O,O,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: stand center
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,O,O,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3: walk left foot back
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,T,O,O,T,T,O,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,T,T,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4: stand center (same as 2)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,O,O,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// MARK: - BUSY: Running fast with sweat
private let busyFrames: [[[UInt32?]]] = [
    // Frame 0: stretched run right
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,S,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,O,O,T,T,T,T],
        [T,O,T,O,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,O,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,O,O,T,T,T,T,T,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: mid-stride
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,S,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,O,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,O,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,O,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: airborne
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,S,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,O,T,O,D,D,D,D,D,D,O,O,T,T,T,T],
        [T,T,O,O,D,D,D,D,D,D,D,T,O,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,T,O,O,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,T,T,T,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3: landing
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,S,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,O,T,O,D,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,O,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,T,O,O,T,O,O,T,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4: stretch
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,S,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,C,B,W,C,C,C,B,W,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,O,T,T,T,T],
        [T,O,T,T,O,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,O,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,O,O,T,T,T,T,T,O,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// MARK: - BLOATED: Full context, puffy body, big eyes
private let bloatedFrames: [[[UInt32?]]] = [
    // Frame 0: round puffy cat
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,W,B,C,C,C,W,B,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,T,O,O,O,T,T,T,T,T,O,O,O,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: slight bounce up
    [
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,W,B,C,C,C,W,B,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,T,O,O,O,T,T,T,T,T,O,O,O,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: same as 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,W,B,C,C,C,W,B,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,T,O,O,O,T,T,T,T,T,O,O,O,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3: waddle right
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,T,T,O,T,T,T,T],
        [T,T,T,T,O,C,O,T,T,T,O,C,O,T,T,T],
        [T,T,T,O,C,C,C,O,O,O,C,C,C,O,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,C,C,O,T,T],
        [T,T,T,O,C,W,B,C,C,C,W,B,C,O,T,T],
        [T,T,T,O,C,B,B,C,C,C,B,B,C,O,T,T],
        [T,T,T,O,K,C,C,P,P,C,C,K,C,O,T,T],
        [T,T,T,T,O,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,D,O,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,D,D,D,O,T],
        [T,T,O,D,D,D,D,D,D,D,D,D,D,D,O,T],
        [T,T,T,O,O,O,T,T,T,T,T,O,O,O,T,T],
        [T,T,T,T,T,O,T,T,T,T,T,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4: same as 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,W,B,C,C,C,W,B,C,O,T,T,T],
        [T,T,O,C,B,B,C,C,C,B,B,C,O,T,T,T],
        [T,T,O,K,C,C,P,P,C,C,K,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,O,D,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,D,D,D,O,T,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,O,D,D,D,D,D,D,D,D,D,D,D,O,T,T],
        [T,T,O,O,O,T,T,T,T,T,O,O,O,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// MARK: - STRESSED: Shaking with ! above head
private let stressedFrames: [[[UInt32?]]] = [
    // Frame 0: shake left + !
    [
        [T,T,T,T,T,T,T,R,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,R,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,B,W,C,C,B,W,C,O,T,T,T,T,T],
        [T,O,C,B,B,C,C,B,B,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,T,O,O,T,T,O,O,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
    ],
    // Frame 1: shake right + !
    [
        [T,T,T,T,T,T,T,T,R,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,R,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,T,O,C,O,T,T,O,C,O,T,T,T,T],
        [T,T,T,O,C,C,C,O,O,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,B,W,C,C,B,W,C,O,T,T,T],
        [T,T,T,O,C,B,B,C,C,B,B,C,O,T,T,T],
        [T,T,T,O,C,C,C,P,C,C,C,C,O,T,T,T],
        [T,T,T,T,O,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,T,T,T,O,O,T,T,O,O,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,T,O,T,T,T,T,T],
    ],
    // Frame 2: same as 0
    [
        [T,T,T,T,T,T,T,R,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,R,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,B,W,C,C,B,W,C,O,T,T,T,T,T],
        [T,O,C,B,B,C,C,B,B,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,T,O,O,T,T,O,O,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
    ],
    // Frame 3: same as 1
    [
        [T,T,T,T,T,T,T,T,R,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,R,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,T,O,C,O,T,T,O,C,O,T,T,T,T],
        [T,T,T,O,C,C,C,O,O,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,B,W,C,C,B,W,C,O,T,T,T],
        [T,T,T,O,C,B,B,C,C,B,B,C,O,T,T,T],
        [T,T,T,O,C,C,C,P,C,C,C,C,O,T,T,T],
        [T,T,T,T,O,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,D,O,T,T,T,T],
        [T,T,T,T,T,O,O,T,T,O,O,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,T,O,T,T,T,T,T],
    ],
    // Frame 4: same as 0
    [
        [T,T,T,T,T,T,R,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,R,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
        [T,T,O,C,O,T,T,O,C,O,T,T,T,T,T,T],
        [T,O,C,C,C,O,O,C,C,C,O,T,T,T,T,T],
        [T,O,C,C,C,C,C,C,C,C,O,T,T,T,T,T],
        [T,O,C,B,W,C,C,B,W,C,O,T,T,T,T,T],
        [T,O,C,B,B,C,C,B,B,C,O,T,T,T,T,T],
        [T,O,C,C,C,P,C,C,C,C,O,T,T,T,T,T],
        [T,T,O,C,C,C,C,C,C,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,O,D,D,D,D,D,D,O,T,T,T,T,T,T],
        [T,T,T,O,O,T,T,O,O,T,T,T,T,T,T,T],
        [T,T,T,O,T,T,T,T,O,T,T,T,T,T,T,T],
    ],
]

// MARK: - TIRED: Slouched, half-closed eyes
private let tiredFrames: [[[UInt32?]]] = [
    // Frame 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,O,O,C,C,C,O,O,C,O,T,T,T],
        [T,T,O,C,C,B,C,C,C,C,B,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,O,O,T,T,T,T,T,T],
        [T,T,T,O,O,T,T,T,T,O,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: shuffle
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,O,O,C,C,C,O,O,C,O,T,T,T],
        [T,T,O,C,C,B,C,C,C,C,B,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,T,O,O,T,O,O,T,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: same as 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,O,O,C,C,C,O,O,C,O,T,T,T],
        [T,T,O,C,C,B,C,C,C,C,B,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,O,O,T,T,T,T,T,T],
        [T,T,T,O,O,T,T,T,T,O,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,O,O,C,C,C,O,O,C,O,T,T,T],
        [T,T,O,C,C,B,C,C,C,C,B,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,T,O,O,T,O,O,T,T,T,T,T,T],
        [T,T,T,T,T,O,T,T,T,O,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,O,T,T,T,T,T,O,T,T,T,T,T],
        [T,T,T,O,C,O,T,T,T,O,C,O,T,T,T,T],
        [T,T,O,C,C,C,O,O,O,C,C,C,O,T,T,T],
        [T,T,O,C,C,C,C,C,C,C,C,C,O,T,T,T],
        [T,T,O,C,O,O,C,C,C,O,O,C,O,T,T,T],
        [T,T,O,C,C,B,C,C,C,C,B,C,O,T,T,T],
        [T,T,O,C,C,C,P,C,C,C,C,C,O,T,T,T],
        [T,T,T,O,C,C,C,C,C,C,C,O,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,D,D,D,D,D,O,T,T,T,T,T],
        [T,T,T,T,O,O,T,T,O,O,T,T,T,T,T,T],
        [T,T,T,O,O,T,T,T,T,O,O,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// MARK: - COLLAB: Two small cats walking together
private let collabFrames: [[[UInt32?]]] = [
    // Frame 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,C,O,C,O,T,T,T,O,C,O,C,O,T,T,T],
        [O,C,C,C,O,T,T,T,O,C,C,C,O,T,T,T],
        [O,B,C,B,O,T,T,T,O,B,C,B,O,T,T,T],
        [O,C,P,C,O,T,T,T,O,C,P,C,O,T,T,T],
        [T,O,C,O,T,T,T,T,T,O,C,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,T,T,T,O,T,T,T,O,T,T,T,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: offset walk
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,C,O,C,O,T,T,T,O,C,O,C,O,T,T,T],
        [O,C,C,C,O,T,T,T,O,C,C,C,O,T,T,T],
        [O,B,C,B,O,T,T,T,O,B,C,B,O,T,T,T],
        [O,C,P,C,O,T,T,T,O,C,P,C,O,T,T,T],
        [T,O,C,O,T,T,T,T,T,O,C,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,T,O,T,O,T,T,T,T,T,O,T,O,T,T,T],
        [T,T,T,O,T,T,T,T,T,T,T,O,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: same as 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,C,O,C,O,T,T,T,O,C,O,C,O,T,T,T],
        [O,C,C,C,O,T,T,T,O,C,C,C,O,T,T,T],
        [O,B,C,B,O,T,T,T,O,B,C,B,O,T,T,T],
        [O,C,P,C,O,T,T,T,O,C,P,C,O,T,T,T],
        [T,O,C,O,T,T,T,T,T,O,C,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,T,T,T,O,T,T,T,O,T,T,T,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,C,O,C,O,T,T,T,O,C,O,C,O,T,T,T],
        [O,C,C,C,O,T,T,T,O,C,C,C,O,T,T,T],
        [O,B,C,B,O,T,T,T,O,B,C,B,O,T,T,T],
        [O,C,P,C,O,T,T,T,O,C,P,C,O,T,T,T],
        [T,O,C,O,T,T,T,T,T,O,C,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [O,T,T,T,O,T,T,T,O,T,T,T,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 4: same as 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,C,O,C,O,T,T,T,O,C,O,C,O,T,T,T],
        [O,C,C,C,O,T,T,T,O,C,C,C,O,T,T,T],
        [O,B,C,B,O,T,T,T,O,B,C,B,O,T,T,T],
        [O,C,P,C,O,T,T,T,O,C,P,C,O,T,T,T],
        [T,O,C,O,T,T,T,T,T,O,C,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,D,O,T,T,T,T,T,O,D,O,T,T,T,T],
        [T,O,T,O,T,T,T,T,T,O,T,O,T,T,T,T],
        [O,T,T,T,O,T,T,T,O,T,T,T,O,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]
