import Foundation

// MARK: - Color Aliases (same as ClaudeSprites.swift)
private let M = UInt32(0xFFD97757)   // Main body (terracotta)
private let S = UInt32(0xFFBF6347)   // Shadow
private let H = UInt32(0xFFE89070)   // Highlight
private let W = UInt32(0xFFFFFFFF)   // White
private let B = UInt32(0xFF2D2D2D)   // Black (eyes)
private let P = UInt32(0xFFF5A0B8)   // Blush
private let T: UInt32? = nil         // Transparent

// MARK: - InteractionSprites

struct InteractionSprites {
    static let frameInterval: TimeInterval = 0.15
    static let frameCount: Int = 6
    static func frames() -> [[[UInt32?]]] { return interactionFrames }
}

// 6 frames: crouch → crouch → jump (arm up) → jump (arm wave) → land (wave 1) → land (wave 2)
private let interactionFrames: [[[UInt32?]]] = [
    // Frame 0: Crouch — body shifted DOWN 1 row, compressed legs (2 rows)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 0
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 1
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 2
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 3
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 4
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 5
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 6
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 7
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 8  (head top, shifted down 1)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 9
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 10
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 11
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 12 (eyes)
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 13
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 14
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 15
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 16 (body)
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 17
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 18
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 19
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 20 (lower body)
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 21
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 22
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 23
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 24 (legs, compressed 2 rows)
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 25
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 26
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 27
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 28
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 29
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 30
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 31
    ],
    // Frame 1: Crouch hold — same as frame 0
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 0
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 1
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 2
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 3
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 4
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 5
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 6
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 7
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 8
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 9
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 10
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 11
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 12
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 13
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 14
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 15
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 16
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 17
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 18
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 19
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 20
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 21
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 22
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 23
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 24
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 25
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 26
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 27
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 28
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 29
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 30
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 31
    ],
    // Frame 2: Jump — body shifted UP 3 rows (head at row 4), right arm raised, no legs
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 0
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 1
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,M,M],  // row 2 (right arm raised)
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,M,M],  // row 3 (right arm)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,M,M],  // row 4 (head top + arm)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 5
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 6
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 7
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 8 (eyes)
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 9
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 10
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 11
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 12 (body)
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 13
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 14
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 15
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 16 (lower body)
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 17
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 18
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 19
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 20 (no legs — floating)
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 21
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 22
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 23
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 24
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 25
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 26
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 27
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 28
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 29
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 30
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 31
    ],
    // Frame 3: Jump wave — arm shifted slightly (wave motion), arm at cols 28-31 rows 2-3
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 0
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,M,M],  // row 1 (arm higher)
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,M,M],  // row 2
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 3 (gap for wave effect)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 4 (head top)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 5
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 6
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 7
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 8 (eyes)
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 9
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 10
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 11
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 12 (body)
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 13
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 14
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 15
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 16 (lower body)
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 17
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 18
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 19
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 20 (no legs)
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 21
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 22
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 23
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 24
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 25
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 26
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 27
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 28
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 29
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 30
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 31
    ],
    // Frame 4: Land + wave — normal position, right arm straight out to the side
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 0
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 1
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 2
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 3
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 4
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 5
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 6
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 7 (head top, normal position)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 8
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 9
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 10
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 11 (eyes)
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 12
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 13
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 14
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 15 (body, right arm extends out)
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 16
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 17
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 18
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 19 (lower body)
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 20
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 21
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 22
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 23 (legs)
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 24
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 25
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 26
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 27
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 28
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 29
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 30
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 31
    ],
    // Frame 5: Land + wave 2 — arm angled up (rows 5-7 cols 28-31)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 0
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 1
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 2
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 3
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 4
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,M,M],  // row 5 (arm angled up)
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M,M,M],  // row 6
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,M,M],  // row 7 (head top + arm)
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],  // row 8
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 9
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],  // row 10
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 11 (eyes)
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 12
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 13
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],  // row 14
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 15 (body)
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 16
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 17
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],  // row 18
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 19 (lower body)
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 20
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 21
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],  // row 22
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 23 (legs)
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 24
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 25
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],  // row 26
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 27
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 28
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 29
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 30
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],  // row 31
    ],
]
