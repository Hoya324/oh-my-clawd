import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

// MARK: - GIF Generation for Clawd character states

@main
struct GenerateClawdGIFs {
    static let gifSize = 64
    static let spriteSize = 32
    static let frameDelay = 0.2

    static func createCGImage(pixels: [[UInt32?]]) -> CGImage? {
        let scale = gifSize / spriteSize
        var pixelData = [UInt8](repeating: 0, count: gifSize * gifSize * 4)

        for y in 0..<spriteSize {
            guard y < pixels.count else { continue }
            let row = pixels[y]
            for x in 0..<spriteSize {
                guard x < row.count else { continue }
                guard let color = row[x] else { continue }
                let r = UInt8((color >> 16) & 0xFF)
                let g = UInt8((color >> 8) & 0xFF)
                let b = UInt8(color & 0xFF)
                let a = UInt8((color >> 24) & 0xFF)
                for dy in 0..<scale {
                    for dx in 0..<scale {
                        let px = x * scale + dx
                        let py = y * scale + dy
                        let offset = (py * gifSize + px) * 4
                        pixelData[offset]     = r
                        pixelData[offset + 1] = g
                        pixelData[offset + 2] = b
                        pixelData[offset + 3] = a
                    }
                }
            }
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let provider = CGDataProvider(data: Data(pixelData) as CFData) else { return nil }
        return CGImage(
            width: gifSize,
            height: gifSize,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: gifSize * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    static func createAnimatedGIF(frames: [CGImage], path: String) {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let dest = CGImageDestinationCreateWithURL(
            url,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            print("  ERROR: Could not create GIF destination at \(path)")
            return
        }

        let gifProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ] as CFDictionary
        CGImageDestinationSetProperties(dest, gifProperties)

        let frameProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay
            ]
        ] as CFDictionary
        for frame in frames {
            CGImageDestinationAddImage(dest, frame, frameProperties)
        }

        if CGImageDestinationFinalize(dest) {
            print("  OK: \(path)")
        } else {
            print("  ERROR: Failed to finalize GIF at \(path)")
        }
    }

    /// Composite accessory overlay on top of a character frame.
    /// Non-nil pixels in the overlay replace character pixels.
    static func composite(base: [[UInt32?]], overlay: [[UInt32?]]) -> [[UInt32?]] {
        var result = base
        for y in 0..<min(base.count, overlay.count) {
            for x in 0..<min(base[y].count, overlay[y].count) {
                if let px = overlay[y][x] {
                    result[y][x] = px
                }
            }
        }
        return result
    }

    static func main() throws {
        let projectRoot: String
        if CommandLine.arguments.count > 1 {
            projectRoot = CommandLine.arguments[1]
        } else {
            projectRoot = FileManager.default.currentDirectoryPath
        }

        let outputDir = projectRoot + "/docs/assets/clawd"
        let fashionDir = outputDir + "/fashion"
        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            atPath: fashionDir,
            withIntermediateDirectories: true
        )

        print("Generating Clawd GIFs in \(outputDir)...")

        // ── 1. Base state GIFs ──
        let states: [(PetState, String)] = [
            (.idle, "idle"),
            (.wakeUp, "wakeup"),
            (.normal, "normal"),
            (.busy, "busy"),
            (.bloated, "bloated"),
            (.stressed, "stressed"),
            (.tired, "tired"),
            (.collab, "collab"),
        ]

        for (state, name) in states {
            let pixelFrames = ClaudeSprites.frames(state: state)

            var cgImages: [CGImage] = []
            for frame in pixelFrames {
                if let img = createCGImage(pixels: frame) {
                    cgImages.append(img)
                }
            }

            guard !cgImages.isEmpty else {
                print("  SKIP: \(name) -- no frames")
                continue
            }

            let path = "\(outputDir)/\(name).gif"
            createAnimatedGIF(frames: cgImages, path: path)
        }

        print("Generated \(states.count) state GIFs.")

        // ── 2. Individual accessory GIFs (normal walking state) ──
        let accessories: [(AccessoryType, String)] = [
            (.cap, "acc-cap"),
            (.partyHat, "acc-partyhat"),
            (.santaHat, "acc-santahat"),
            (.silkHat, "acc-silkhat"),
            (.cowboyHat, "acc-cowboyhat"),
            (.hornRimmed, "acc-hornrimmed"),
            (.sunglasses, "acc-sunglasses"),
            (.roundGlasses, "acc-roundglasses"),
            (.starGlasses, "acc-starglasses"),
            (.jeans, "acc-jeans"),
            (.shorts, "acc-shorts"),
            (.slacks, "acc-slacks"),
            (.joggers, "acc-joggers"),
            (.cargo, "acc-cargo"),
        ]

        for (accessory, filename) in accessories {
            let baseFrames = ClaudeSprites.frames(state: .normal)
            var cgImages: [CGImage] = []
            for (i, frame) in baseFrames.enumerated() {
                if let overlay = AccessorySprites.overlay(accessory: accessory, state: .normal, frameIndex: i) {
                    let composited = composite(base: frame, overlay: overlay)
                    if let img = createCGImage(pixels: composited) {
                        cgImages.append(img)
                    }
                } else {
                    if let img = createCGImage(pixels: frame) {
                        cgImages.append(img)
                    }
                }
            }
            guard !cgImages.isEmpty else { continue }
            createAnimatedGIF(frames: cgImages, path: "\(outputDir)/\(filename).gif")
        }

        print("Generated \(accessories.count) accessory GIFs.")

        // ── 3. Fashion combination GIFs ──
        struct FashionCombo {
            let name: String
            let hat: AccessoryType?
            let glasses: AccessoryType?
            let pants: AccessoryType?
        }

        let fashionCombos: [FashionCombo] = [
            FashionCombo(name: "casual",      hat: .cap,       glasses: .sunglasses,   pants: .jeans),
            FashionCombo(name: "gentleman",    hat: .silkHat,   glasses: .roundGlasses, pants: .slacks),
            FashionCombo(name: "cowboy",       hat: .cowboyHat, glasses: .starGlasses,  pants: .cargo),
            FashionCombo(name: "party",        hat: .partyHat,  glasses: .hornRimmed,   pants: .shorts),
            FashionCombo(name: "santa",        hat: .santaHat,  glasses: nil,           pants: .joggers),
            FashionCombo(name: "nerd",         hat: nil,        glasses: .roundGlasses, pants: .slacks),
            FashionCombo(name: "sporty",       hat: .cap,       glasses: nil,           pants: .joggers),
        ]

        for combo in fashionCombos {
            let baseFrames = ClaudeSprites.frames(state: .normal)
            var cgImages: [CGImage] = []
            for (i, frame) in baseFrames.enumerated() {
                var result = frame
                // Layer order: pants first, then glasses, then hat (top)
                if let pants = combo.pants,
                   let overlay = AccessorySprites.overlay(accessory: pants, state: .normal, frameIndex: i) {
                    result = composite(base: result, overlay: overlay)
                }
                if let glasses = combo.glasses,
                   let overlay = AccessorySprites.overlay(accessory: glasses, state: .normal, frameIndex: i) {
                    result = composite(base: result, overlay: overlay)
                }
                if let hat = combo.hat,
                   let overlay = AccessorySprites.overlay(accessory: hat, state: .normal, frameIndex: i) {
                    result = composite(base: result, overlay: overlay)
                }
                if let img = createCGImage(pixels: result) {
                    cgImages.append(img)
                }
            }
            guard !cgImages.isEmpty else { continue }
            createAnimatedGIF(frames: cgImages, path: "\(fashionDir)/\(combo.name).gif")
        }

        print("Generated \(fashionCombos.count) fashion combo GIFs.")
        print("Done!")
    }
}
