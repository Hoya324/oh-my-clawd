import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

// MARK: - GIF Generation for all 12 Claude Pets

@main
struct GeneratePetGIFs {
    static let gifSize = 64
    static let spriteSize = 16
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

    static func main() throws {
        let projectRoot: String
        if CommandLine.arguments.count > 1 {
            projectRoot = CommandLine.arguments[1]
        } else {
            projectRoot = FileManager.default.currentDirectoryPath
        }

        let outputDir = projectRoot + "/docs/assets/pets"
        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true
        )

        print("Generating pet GIFs in \(outputDir)...")

        for pet in PetType.allCases {
            let provider = PixelArtRenderer.spriteProvider(for: pet)
            let pixelFrames = provider.frames(state: .normal, muscle: .normal)

            var cgImages: [CGImage] = []
            for frame in pixelFrames {
                if let img = createCGImage(pixels: frame) {
                    cgImages.append(img)
                }
            }

            guard !cgImages.isEmpty else {
                print("  SKIP: \(pet.rawValue) -- no frames")
                continue
            }

            let path = "\(outputDir)/\(pet.rawValue).gif"
            createAnimatedGIF(frames: cgImages, path: path)
        }

        print("Done. Generated \(PetType.allCases.count) GIFs.")
    }
}
