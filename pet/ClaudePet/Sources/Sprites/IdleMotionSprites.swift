import Foundation

// MARK: - Color Aliases (same as ClaudeSprites.swift)
private let M = UInt32(0xFFD97757)   // Main body (terracotta)
private let S = UInt32(0xFFBF6347)   // Shadow
private let H = UInt32(0xFFE89070)   // Highlight
private let W = UInt32(0xFFFFFFFF)   // White
private let B = UInt32(0xFF2D2D2D)   // Black (eyes)
private let P = UInt32(0xFFF5A0B8)   // Blush
private let T: UInt32? = nil         // Transparent

// MARK: - IdleMotionType

enum IdleMotionType: CaseIterable {
    case wave
    case blink
    case tilt
    case stretch

    var frameCount: Int {
        switch self {
        case .wave:    return 4
        case .blink:   return 3
        case .tilt:    return 4
        case .stretch: return 4
        }
    }

    var frameInterval: TimeInterval {
        switch self {
        case .wave:    return 0.2
        case .blink:   return 0.12
        case .tilt:    return 0.25
        case .stretch: return 0.25
        }
    }

    var allowedStates: [PetState] {
        switch self {
        case .wave:    return [.normal, .idle, .tired]
        case .blink:   return [.normal, .idle, .tired, .collab]
        case .tilt:    return [.normal, .idle]
        case .stretch: return [.normal, .tired]
        }
    }
}

// MARK: - IdleMotionSprites

struct IdleMotionSprites {
    static func frames(motion: IdleMotionType) -> [[[UInt32?]]] {
        switch motion {
        case .wave:    return waveFrames
        case .blink:   return blinkFrames
        case .tilt:    return tiltFrames
        case .stretch: return stretchFrames
        }
    }
}

// ============================================================================
// MARK: - Blink: Eyes close briefly (3 frames)
// Frame 0: Eyes half-closed (1 row of B at row 12)
// Frame 1: Eyes fully closed (S line at row 12)
// Frame 2: Eyes open (normal)
// ============================================================================
private let blinkFrames: [[[UInt32?]]] = [
    // Frame 0: Eyes half-closed
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: Eyes fully closed (S shadow lines)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,S,S,M,M,M,M,M,M,M,M,M,M,M,M,S,S,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Eyes open again (same as normal frame 0)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// ============================================================================
// MARK: - Wave: Right arm waves (4 frames)
// Frame 0: arm extends right, Frame 1: arm raised up, Frame 2: arm right, Frame 3: normal
// ============================================================================
private let waveFrames: [[[UInt32?]]] = [
    // Frame 0: Right arm extends to the right (cols 28-31, rows 15-16)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 1: Right arm raised up (cols 28-31, rows 5-7)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Same as frame 0 (arm right)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 3: Back to normal (same as blink frame 2)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
]

// ============================================================================
// MARK: - Tilt: Head tilts right (4 frames)
// Reuses normal body, shifts head cols 5-28 instead of 4-27 on frames 1-2
// ============================================================================
private let tiltFrames: [[[UInt32?]]] = [
    blinkFrames[2], // Frame 0: Normal
    // Frame 1: Head shifted right 1 col
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T],
        [T,T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T],
        [T,T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Same tilt (hold)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T],
        [T,T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T],
        [T,T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [T,T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    blinkFrames[2], // Frame 3: Back to normal
]

// ============================================================================
// MARK: - Stretch: Both arms up (4 frames)
// Frame 0: Normal, Frame 1-2: Both arms up (cols 0-3 and 28-31 at rows 5-7), Frame 3: Normal
// ============================================================================
private let stretchFrames: [[[UInt32?]]] = [
    blinkFrames[2], // Frame 0: Normal
    // Frame 1: Both arms raised
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [M,M,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [M,M,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,M,M,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    // Frame 2: Hold stretch (same as frame 1)
    [
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [M,M,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [M,M,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,M,M],
        [T,T,M,M,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,M,M,T,T],
        [T,T,T,T,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,H,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,B,B,M,M,M,M,M,M,M,M,M,M,M,M,B,B,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [T,T,T,T,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,T,T,T,T],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M,M],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T,T,T,S,S,T,T,S,S,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
        [T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T],
    ],
    blinkFrames[2], // Frame 3: Back to normal
]
