import Cocoa

// MARK: - Shared Color Palette
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

// MARK: - Pixel Art Renderer

struct PixelArtRenderer {
    static let pixelSize = 32
    static let displayW: CGFloat = 20
    static let displayH: CGFloat = 20

    /// Render a single 2D pixel grid to an NSImage.
    static func render(pixels: [[UInt32?]]) -> NSImage {
        let scale = 2
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

    /// Render a single frame with character + accessories + effects composited.
    static func renderComposited(
        base: [[UInt32?]],
        overlays: [[[UInt32?]]?],
        effect: [[UInt32?]]?
    ) -> NSImage {
        // Start with base pixels, then layer overlays on top
        var composited = base
        for overlay in overlays {
            guard let overlay = overlay else { continue }
            for (y, row) in overlay.enumerated() {
                for (x, pixel) in row.enumerated() {
                    guard let px = pixel else { continue }
                    if y < composited.count && x < composited[y].count {
                        composited[y][x] = px
                    }
                }
            }
        }
        // Apply effect overlay
        if let effect = effect {
            for (y, row) in effect.enumerated() {
                for (x, pixel) in row.enumerated() {
                    guard let px = pixel else { continue }
                    if y < composited.count && x < composited[y].count {
                        composited[y][x] = px
                    }
                }
            }
        }
        return render(pixels: composited)
    }

    /// Convenience: render a complete frame with all layers.
    static func renderFrame(
        state: PetState,
        activity: ActivityLevel,
        hat: AccessoryType?,
        glasses: AccessoryType?,
        frameIndex: Int
    ) -> NSImage {
        let baseFrames = ClaudeSprites.frames(state: state)
        let base = baseFrames[frameIndex % max(1, baseFrames.count)]

        var overlays: [[[UInt32?]]?] = []
        // Glasses first (under hat)
        if let glasses = glasses {
            overlays.append(AccessorySprites.overlay(
                accessory: glasses, state: state, frameIndex: frameIndex))
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

    /// Get total frame count for a state.
    static func frameCount(state: PetState) -> Int {
        return ClaudeSprites.frames(state: state).count
    }
}
