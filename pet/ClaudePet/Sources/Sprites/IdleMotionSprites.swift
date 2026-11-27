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
    // Hand-drawn
    case wave
    case blink
    case tilt
    case stretch
    // Procedural (Sprites/ProceduralMotions.swift)
    case hop
    case dance
    case lookAround
    case heart
    case shiver
    case nod
    case sigh
    case sparkle
    case snuggle
    case surprised
    /// Not in the random pool: played on unlocks and usage resets.
    case celebrate

    var frameInterval: TimeInterval {
        switch self {
        case .wave:       return 0.2
        case .blink:      return 0.12
        case .tilt:       return 0.25
        case .stretch:    return 0.25
        case .hop:        return 0.09
        case .dance:      return 0.14
        case .lookAround: return 0.22
        case .heart:      return 0.16
        case .shiver:     return 0.06
        case .nod:        return 0.15
        case .sigh:       return 0.25
        case .sparkle:    return 0.15
        case .snuggle:    return 0.4
        case .surprised:  return 0.12
        case .celebrate:  return 0.09
        }
    }

    /// States in which the motion may play at random.
    var allowedStates: [PetState] {
        switch self {
        case .wave:       return [.normal, .idle, .tired, .chatting]
        case .blink:      return [.normal, .idle, .tired, .collab, .chatting]
        case .tilt:       return [.normal, .idle, .chatting]
        case .stretch:    return [.normal, .tired]
        case .hop:        return [.normal, .collab]
        case .dance:      return [.normal, .collab]
        case .lookAround: return [.normal, .busy, .chatting]
        case .heart:      return [.normal, .chatting, .collab]
        case .shiver:     return [.stressed]
        case .nod:        return [.busy]
        case .sigh:       return [.bloated, .tired]
        case .sparkle:    return [.collab, .busy]
        case .snuggle:    return [.idle]
        case .surprised:  return [.stressed, .bloated]
        case .celebrate:  return []
        }
    }

    /// Relative weight in the random pool.
    var weight: Int {
        switch self {
        case .wave:  return 3
        case .blink: return 1
        default:     return 2
        }
    }

    /// Whether the hand-drawn frames replace the whole character (and must
    /// not be combined with the state's own base sprite).
    var isHandDrawn: Bool {
        switch self {
        case .wave, .blink, .tilt, .stretch: return true
        default: return false
        }
    }

    /// Motions suitable as a click reaction.
    static let clickReactions: [IdleMotionType] = [.hop, .heart, .lookAround, .dance]
}

// MARK: - IdleMotionSprites

struct IdleMotionSprites {
    /// Frames for any motion. Procedural motions are built from `base`
    /// (the current state's first frame) so they keep that state's face.
    static func motionFrames(motion: IdleMotionType, base: PixelGrid) -> [MotionFrame] {
        switch motion {
        case .wave:       return waveFrames.map { MotionFrame(body: $0) }
        case .blink:      return blinkFrames.map { MotionFrame(body: $0) }
        case .tilt:       return tiltFrames.map { MotionFrame(body: $0) }
        case .stretch:    return stretchFrames.map { MotionFrame(body: $0) }
        case .hop:        return ProceduralMotions.hop(base: base)
        case .dance:      return ProceduralMotions.dance(base: base)
        case .lookAround: return ProceduralMotions.lookAround(base: base)
        case .heart:      return ProceduralMotions.heart(base: base)
        case .shiver:     return ProceduralMotions.shiver(base: base)
        case .nod:        return ProceduralMotions.nod(base: base)
        case .sigh:       return ProceduralMotions.sigh(base: base)
        case .sparkle:    return ProceduralMotions.sparkle(base: base)
        case .snuggle:    return ProceduralMotions.snuggle(base: base)
        case .surprised:  return ProceduralMotions.surprised(base: base)
        case .celebrate:  return ProceduralMotions.celebrate(base: base)
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
