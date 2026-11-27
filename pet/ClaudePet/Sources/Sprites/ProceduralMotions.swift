import Foundation

typealias PixelGrid = [[UInt32?]]

/// One frame of a motion. The body (plus accessories) is shifted by dx/dy
/// as a unit; particles are drawn last, unshifted, so effects like a heart
/// can float independently of the character.
struct MotionFrame {
    var body: PixelGrid
    var dx: Int = 0
    var dy: Int = 0
    var particles: PixelGrid? = nil
}

// MARK: - Palette

private let BODY  = UInt32(0xFFD97757)
private let SHADE = UInt32(0xFFBF6347)
private let EYE   = UInt32(0xFF2D2D2D)
private let WHITE = UInt32(0xFFFFFFFF)
private let LINE  = UInt32(0xFF4A6670)
private let HEART = UInt32(0xFFFF6B8A)
private let GOLD  = UInt32(0xFFF59E0B)
private let NOTE  = UInt32(0xFF7C3AED)
private let SWEAT = UInt32(0xFF87CEEB)
private let PUFF  = UInt32(0xFFCCCCCC)
private let ALERT = UInt32(0xFFFF4444)

// MARK: - Grid helpers

struct Particle {
    let pattern: [String]
    let colors: [Character: UInt32]
    let x: Int
    let y: Int
}

enum Pixels {
    static let size = 32

    static func empty() -> PixelGrid {
        Array(repeating: Array(repeating: nil, count: size), count: size)
    }

    /// Move every pixel by (dx, dy); pixels pushed off the edge are dropped.
    static func shift(_ g: PixelGrid, dx: Int, dy: Int) -> PixelGrid {
        if dx == 0 && dy == 0 { return g }
        var out = empty()
        for y in 0..<min(size, g.count) {
            for x in 0..<min(size, g[y].count) {
                guard let px = g[y][x] else { continue }
                let nx = x + dx, ny = y + dy
                if nx >= 0 && nx < size && ny >= 0 && ny < size { out[ny][nx] = px }
            }
        }
        return out
    }

    /// Draw `top` over `base` (non-nil pixels win).
    static func overlay(_ base: PixelGrid, _ top: PixelGrid?) -> PixelGrid {
        guard let top = top else { return base }
        var out = base
        for y in 0..<min(out.count, top.count) {
            for x in 0..<min(out[y].count, top[y].count) {
                if let px = top[y][x] { out[y][x] = px }
            }
        }
        return out
    }

    /// Stamp an ASCII pattern. Each character maps to a color; '.' is clear.
    static func stamp(_ pattern: [String], colors: [Character: UInt32],
                      x: Int, y: Int, into g: inout PixelGrid) {
        for (row, line) in pattern.enumerated() {
            for (col, ch) in line.enumerated() {
                guard let color = colors[ch] else { continue }
                let px = x + col, py = y + row
                if px >= 0 && px < size && py >= 0 && py < size { g[py][px] = color }
            }
        }
    }

    static func particles(_ items: [Particle]) -> PixelGrid {
        var g = empty()
        for item in items { stamp(item.pattern, colors: item.colors, x: item.x, y: item.y, into: &g) }
        return g
    }

    private static func eyePixels(_ g: PixelGrid) -> [(Int, Int)] {
        var pts: [(Int, Int)] = []
        for y in 8..<min(18, g.count) {
            for x in 0..<g[y].count where g[y][x] == EYE { pts.append((x, y)) }
        }
        return pts
    }

    /// Slide the eyes sideways inside the face (look left / right).
    static func moveEyes(_ g: PixelGrid, dx: Int) -> PixelGrid {
        let eyes = eyePixels(g)
        guard !eyes.isEmpty, dx != 0 else { return g }
        var out = g
        for (x, y) in eyes { out[y][x] = BODY }
        for (x, y) in eyes {
            let nx = x + dx
            if nx >= 0 && nx < size && out[y][nx] != nil { out[y][nx] = EYE }
        }
        return out
    }

    /// Replace open eyes with a closed (or happy) line.
    static func closeEyes(_ g: PixelGrid) -> PixelGrid {
        let eyes = eyePixels(g)
        guard let minY = eyes.map({ $0.1 }).min(), let maxY = eyes.map({ $0.1 }).max() else { return g }
        let lineY = (minY + maxY + 1) / 2
        var out = g
        var cols = Set<Int>()
        for (x, y) in eyes { out[y][x] = BODY; cols.insert(x) }
        for x in cols { out[lineY][x] = SHADE }
        return out
    }
}

// MARK: - Particle patterns

private enum Shape {
    static let heart = [".X.X.", "XXXXX", ".XXX.", "..X.."]
    static let smallHeart = ["X.X", "XXX", ".X."]
    static let sparkle = [".X.", "XXX", ".X."]
    static let twinkle = ["X"]
    static let note = [".XX", ".X.", ".X.", "XX.", "XX."]
    static let sweat = [".X", "XX", "XX"]
    static let puff = [".XX.", "XXXX", ".XX."]
    static let alert = ["X", "X", "X", ".", "X"]
    static let bubble = [
        ".OOOOOOO.",
        "OWWWWWWWO",
        "OWWWWWWWO",
        "OWWWWWWWO",
        ".OOOOOOO.",
        "..OO.....",
    ]
}

private func one(_ c: UInt32) -> [Character: UInt32] { ["X": c] }

/// A single-color particle at (x, y).
private func dot(_ shape: [String], _ color: UInt32, _ x: Int, _ y: Int) -> Particle {
    Particle(pattern: shape, colors: one(color), x: x, y: y)
}

// MARK: - Motions

enum ProceduralMotions {
    static func hop(base: PixelGrid) -> [MotionFrame] {
        [1, -3, -4, -2, 0].map { MotionFrame(body: base, dy: $0) }
    }

    static func dance(base: PixelGrid) -> [MotionFrame] {
        let steps: [(Int, Int)] = [(-1, 0), (0, -1), (1, 0), (0, -1), (-1, 0), (0, -1), (1, 0), (0, 0)]
        return steps.enumerated().map { (i, s) -> MotionFrame in
            let noteY = 6 - i / 2
            let p = Pixels.particles([dot(Shape.note, NOTE, i % 2 == 0 ? 27 : 28, max(0, noteY))])
            return MotionFrame(body: base, dx: s.0, dy: s.1, particles: p)
        }
    }

    static func lookAround(base: PixelGrid) -> [MotionFrame] {
        let left = Pixels.moveEyes(base, dx: -1)
        let right = Pixels.moveEyes(base, dx: 1)
        let closed = Pixels.closeEyes(base)
        return [left, left, base, right, right, base, closed, base].map { MotionFrame(body: $0) }
    }

    static func heart(base: PixelGrid) -> [MotionFrame] {
        let happy = Pixels.closeEyes(base)
        return (0..<6).map { i -> MotionFrame in
            let p = Pixels.particles([dot(Shape.heart, HEART, 13, max(0, 4 - i))])
            return MotionFrame(body: happy, dy: i % 2 == 0 ? 0 : -1, particles: p)
        }
    }

    /// Played when an accessory unlocks or usage resets.
    static func celebrate(base: PixelGrid) -> [MotionFrame] {
        let happy = Pixels.closeEyes(base)
        let jumps = [1, -3, -4, -2, 0, 1, -3, -4, -2, 0]
        let spots: [[(Int, Int)]] = [
            [(1, 2), (28, 9)], [(29, 1), (2, 10)], [(5, 0), (26, 4)], [(0, 6), (30, 6)],
        ]
        return jumps.enumerated().map { (i, dy) -> MotionFrame in
            let items = spots[i % spots.count].map { dot(Shape.sparkle, GOLD, $0.0, $0.1) }
            return MotionFrame(body: happy, dy: dy, particles: Pixels.particles(items))
        }
    }

    static func shiver(base: PixelGrid) -> [MotionFrame] {
        [-1, 1, -1, 1, -1, 1, 0].enumerated().map { (i, dx) -> MotionFrame in
            let p = Pixels.particles([dot(Shape.sweat, SWEAT, 1, 7 + min(i, 4))])
            return MotionFrame(body: base, dx: dx, particles: p)
        }
    }

    static func nod(base: PixelGrid) -> [MotionFrame] {
        [0, 1, 0, 1, 0].map { MotionFrame(body: base, dy: $0) }
    }

    static func sigh(base: PixelGrid) -> [MotionFrame] {
        let closed = Pixels.closeEyes(base)
        return (0..<5).map { i -> MotionFrame in
            let p = Pixels.particles([dot(Shape.puff, PUFF, 27 + min(i, 2), 13 - i)])
            return MotionFrame(body: i < 3 ? closed : base, dy: i < 3 ? 1 : 0, particles: i == 0 ? nil : p)
        }
    }

    static func sparkle(base: PixelGrid) -> [MotionFrame] {
        let sets: [[(Int, Int)]] = [[(2, 3)], [(2, 3), (28, 1)], [(28, 1), (29, 10)], [(29, 10)], []]
        return sets.map { pts -> MotionFrame in
            let items = pts.map { dot(Shape.sparkle, GOLD, $0.0, $0.1) }
            return MotionFrame(body: base, particles: items.isEmpty ? nil : Pixels.particles(items))
        }
    }

    static func snuggle(base: PixelGrid) -> [MotionFrame] {
        [0, 1, 1, 0, -1, 0].map { MotionFrame(body: base, dx: $0) }
    }

    static func surprised(base: PixelGrid) -> [MotionFrame] {
        let p = Pixels.particles([dot(Shape.alert, ALERT, 28, 1)])
        return [
            MotionFrame(body: base, dy: -2, particles: p),
            MotionFrame(body: base, dy: -1, particles: p),
            MotionFrame(body: base, particles: p),
            MotionFrame(body: base),
        ]
    }

    // MARK: Chatting loop (base frames for PetState.chatting)

    /// Speech bubble with typing dots, eyes glancing at the bubble.
    static func chattingLoop(base: PixelGrid) -> [PixelGrid] {
        let glance = Pixels.moveEyes(base, dx: 1)
        let bubbleColors: [Character: UInt32] = ["O": LINE, "W": WHITE]
        return (0..<4).map { i -> PixelGrid in
            var g = i >= 2 ? glance : base
            Pixels.stamp(Shape.bubble, colors: bubbleColors, x: 22, y: 0, into: &g)
            for dot in 0..<3 where dot < i {
                let x = 24 + dot * 2
                g[2][x] = EYE
            }
            return g
        }
    }
}
