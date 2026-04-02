#!/usr/bin/env swift
// generate-icon.swift — Generates AppIcon.iconset PNGs from 32x32 capybara pixel data
// Usage: swiftc -o /tmp/generate-icon scripts/generate-icon.swift -framework Cocoa && /tmp/generate-icon

import Cocoa

// --- Colors (ARGB UInt32) ---
let T: UInt32? = nil           // transparent
let K: UInt32? = 0xFF1A1A1A   // outline/eye
let B: UInt32? = 0xFFA07040   // main body
let D: UInt32? = 0xFF7A5228   // dark shading
let L: UInt32? = 0xFFBA8C54   // lighter body
let X: UInt32? = 0xFF5C3820   // darkest (legs)
let P: UInt32? = 0xFFC4986C   // pale muzzle
let E: UInt32? = 0xFF6B4E30   // ear inner
let N: UInt32? = 0xFF5C3318   // nose
let H: UInt32? = 0xFFC8A468   // forehead highlight

let pixelData: [[UInt32?]] = [
    // Row 0
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 1
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 2
    [T,T,T,T,T,T,K,K,T,T,T,K,K,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 3
    [T,T,T,T,T,K,E,E,K,T,K,E,E,K,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 4
    [T,T,T,T,K,B,B,B,B,K,B,B,B,K,K,K,K,K,K,K,K,K,K,T,T,T,T,T,T,T,T,T],
    // Row 5
    [T,T,T,K,L,L,H,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T,T,T],
    // Row 6
    [T,T,K,L,L,H,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T,T],
    // Row 7
    [T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T],
    // Row 8
    [T,T,K,B,B,K,K,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T,T],
    // Row 9
    [T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
    // Row 10
    [T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
    // Row 11
    [T,T,K,P,P,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
    // Row 12
    [T,T,K,N,P,P,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T],
    // Row 13
    [T,T,T,K,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T],
    // Row 14
    [T,T,T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T],
    // Row 15
    [T,T,T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
    // Row 16
    [T,T,T,T,K,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,K,T,T,T,T,T],
    // Row 17
    [T,T,T,T,K,B,B,D,B,B,B,B,B,B,B,B,B,B,B,B,B,B,B,D,B,K,T,T,T,T,T,T],
    // Row 18
    [T,T,T,T,T,K,D,D,D,B,B,B,B,B,B,B,B,B,B,B,B,B,D,D,K,T,T,T,T,T,T,T],
    // Row 19
    [T,T,T,T,T,K,D,D,D,B,B,B,B,B,B,B,B,B,B,B,B,D,D,D,K,T,T,T,T,T,T,T],
    // Row 20
    [T,T,T,T,T,K,K,D,K,K,B,B,B,B,B,B,B,B,B,K,K,D,K,K,T,T,T,T,T,T,T,T],
    // Row 21
    [T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T],
    // Row 22
    [T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T,K,X,X,K,T,T,T,T,T,T,T,T,T],
    // Row 23
    [T,T,T,T,T,K,K,K,K,K,K,T,T,T,T,T,T,T,K,K,K,K,K,K,T,T,T,T,T,T,T,T],
    // Row 24
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 25
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 26
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 27
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 28
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 29
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 30
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    // Row 31
    [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
]

let srcSize = 32

// Convert ARGB UInt32 to (R, G, B, A) tuple
func argbToRGBA(_ argb: UInt32) -> (UInt8, UInt8, UInt8, UInt8) {
    let a = UInt8((argb >> 24) & 0xFF)
    let r = UInt8((argb >> 16) & 0xFF)
    let g = UInt8((argb >> 8) & 0xFF)
    let b = UInt8(argb & 0xFF)
    return (r, g, b, a)
}

func renderPNG(size: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: size * 4,
        bitsPerPixel: 32
    ) else { return nil }

    guard let bitmapData = rep.bitmapData else { return nil }

    if size >= srcSize {
        // Scale up: nearest-neighbor
        let scale = size / srcSize
        for y in 0..<size {
            for x in 0..<size {
                let srcX = x / scale
                let srcY = y / scale
                let offset = (y * size + x) * 4
                if let color = pixelData[srcY][srcX] {
                    let (r, g, b, a) = argbToRGBA(color)
                    bitmapData[offset]     = r
                    bitmapData[offset + 1] = g
                    bitmapData[offset + 2] = b
                    bitmapData[offset + 3] = a
                } else {
                    bitmapData[offset]     = 0
                    bitmapData[offset + 1] = 0
                    bitmapData[offset + 2] = 0
                    bitmapData[offset + 3] = 0
                }
            }
        }
    } else {
        // Scale down: render at 32x32, then draw scaled down using NSGraphicsContext
        guard let fullRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: srcSize,
            pixelsHigh: srcSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: srcSize * 4,
            bitsPerPixel: 32
        ) else { return nil }

        guard let fullData = fullRep.bitmapData else { return nil }

        for y in 0..<srcSize {
            for x in 0..<srcSize {
                let offset = (y * srcSize + x) * 4
                if let color = pixelData[y][x] {
                    let (r, g, b, a) = argbToRGBA(color)
                    fullData[offset]     = r
                    fullData[offset + 1] = g
                    fullData[offset + 2] = b
                    fullData[offset + 3] = a
                } else {
                    fullData[offset]     = 0
                    fullData[offset + 1] = 0
                    fullData[offset + 2] = 0
                    fullData[offset + 3] = 0
                }
            }
        }

        let fullImage = NSImage(size: NSSize(width: srcSize, height: srcSize))
        fullImage.addRepresentation(fullRep)

        // Draw scaled down
        let smallImage = NSImage(size: NSSize(width: size, height: size))
        smallImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        fullImage.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
                       from: NSRect(x: 0, y: 0, width: srcSize, height: srcSize),
                       operation: .copy,
                       fraction: 1.0)
        smallImage.unlockFocus()

        guard let tiffData = smallImage.tiffRepresentation,
              let smallRep = NSBitmapImageRep(data: tiffData) else { return nil }
        return smallRep.representation(using: .png, properties: [:])
    }

    return rep.representation(using: .png, properties: [:])
}

// --- Main ---

// Determine project root from script location or current working directory
let projectRoot: String
let cwd = FileManager.default.currentDirectoryPath
if FileManager.default.fileExists(atPath: "\(cwd)/pet/ClaudePet") {
    projectRoot = cwd
} else {
    // Try to find it relative to the binary path
    let scriptPath = CommandLine.arguments[0]
    let scriptDir = (scriptPath as NSString).deletingLastPathComponent
    let candidate = (scriptDir as NSString).deletingLastPathComponent
    if FileManager.default.fileExists(atPath: "\(candidate)/pet/ClaudePet") {
        projectRoot = candidate
    } else {
        projectRoot = cwd
    }
}

let iconsetPath = "\(projectRoot)/pet/ClaudePet/AppIcon.iconset"

// Create iconset directory
try FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Required sizes: (filename, pixel size)
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    guard let pngData = renderPNG(size: size) else {
        fputs("Error: Failed to render \(name) at \(size)x\(size)\n", stderr)
        exit(1)
    }
    let filePath = "\(iconsetPath)/\(name)"
    try pngData.write(to: URL(fileURLWithPath: filePath))
    print("  Generated \(name) (\(size)x\(size))")
}

print("Iconset generated at \(iconsetPath)")
