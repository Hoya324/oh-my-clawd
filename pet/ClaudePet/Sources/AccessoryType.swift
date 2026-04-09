import Foundation

enum AccessoryCategory: String, CaseIterable, Codable {
    case hat
    case glasses
}

enum AccessoryType: String, CaseIterable, Codable {
    // Hats (5)
    case cap
    case partyHat
    case santaHat
    case silkHat
    case cowboyHat
    // Glasses (4)
    case hornRimmed
    case sunglasses
    case roundGlasses
    case starGlasses

    var category: AccessoryCategory {
        switch self {
        case .cap, .partyHat, .santaHat, .silkHat, .cowboyHat:
            return .hat
        case .hornRimmed, .sunglasses, .roundGlasses, .starGlasses:
            return .glasses
        }
    }

    var displayName: String {
        switch self {
        case .cap:          return "Cap"
        case .partyHat:     return "Party Hat"
        case .santaHat:     return "Santa Hat"
        case .silkHat:      return "Silk Hat"
        case .cowboyHat:    return "Cowboy Hat"
        case .hornRimmed:   return "Horn-rimmed"
        case .sunglasses:   return "Sunglasses"
        case .roundGlasses: return "Round Glasses"
        case .starGlasses:  return "Star Glasses"
        }
    }

    var displayNameKO: String {
        switch self {
        case .cap:          return "캡모자"
        case .partyHat:     return "꼬깔모자"
        case .santaHat:     return "산타모자"
        case .silkHat:      return "실크햇"
        case .cowboyHat:    return "카우보이모자"
        case .hornRimmed:   return "뿔테안경"
        case .sunglasses:   return "선글라스"
        case .roundGlasses: return "둥근안경"
        case .starGlasses:  return "별안경"
        }
    }

    var unlockDescription: String {
        switch self {
        case .cap:          return "Total 10 sessions"
        case .partyHat:     return "5 hours total usage"
        case .santaHat:     return "500K tokens used"
        case .silkHat:      return "50 agent runs"
        case .cowboyHat:    return "30 hours total usage"
        case .hornRimmed:   return "3+ concurrent sessions"
        case .sunglasses:   return "10 rate limit hits"
        case .roundGlasses: return "20 long sessions (45m+)"
        case .starGlasses:  return "10 hours on Opus"
        }
    }

    var unlockDescriptionKO: String {
        switch self {
        case .cap:          return "총 10회 세션"
        case .partyHat:     return "총 5시간 사용"
        case .santaHat:     return "50만 토큰 사용"
        case .silkHat:      return "에이전트 50회 실행"
        case .cowboyHat:    return "총 30시간 사용"
        case .hornRimmed:   return "동시 3개 이상 세션"
        case .sunglasses:   return "레이트 리밋 10회"
        case .roundGlasses: return "45분 이상 세션 20회"
        case .starGlasses:  return "Opus 모델 10시간"
        }
    }

    static var hats: [AccessoryType] {
        allCases.filter { $0.category == .hat }
    }

    static var glasses: [AccessoryType] {
        allCases.filter { $0.category == .glasses }
    }
}

enum ActivityLevel: Int, CaseIterable {
    case normal = 0
    case glowing = 1
    case supercharged = 2

    var displayName: String {
        switch self {
        case .normal:       return "Normal"
        case .glowing:      return "Glowing"
        case .supercharged: return "Supercharged!"
        }
    }

    static func resolve(agentCount: Int) -> ActivityLevel {
        if agentCount >= 4 { return .supercharged }
        if agentCount >= 2 { return .glowing }
        return .normal
    }
}
