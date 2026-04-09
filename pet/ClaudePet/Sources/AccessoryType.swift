import Foundation

enum AccessoryCategory: String, CaseIterable, Codable {
    case hat
    case glasses
    case pants
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
    // Pants (5)
    case jeans
    case shorts
    case slacks
    case joggers
    case cargo

    var category: AccessoryCategory {
        switch self {
        case .cap, .partyHat, .santaHat, .silkHat, .cowboyHat:
            return .hat
        case .hornRimmed, .sunglasses, .roundGlasses, .starGlasses:
            return .glasses
        case .jeans, .shorts, .slacks, .joggers, .cargo:
            return .pants
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
        case .jeans:        return "Jeans"
        case .shorts:       return "Shorts"
        case .slacks:       return "Slacks"
        case .joggers:      return "Joggers"
        case .cargo:        return "Cargo Pants"
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
        case .jeans:        return "청바지"
        case .shorts:       return "반바지"
        case .slacks:       return "정장바지"
        case .joggers:      return "운동바지"
        case .cargo:        return "카고바지"
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
        case .jeans:        return "15 hours total usage"
        case .shorts:       return "Total 100 sessions"
        case .slacks:       return "1M tokens used"
        case .joggers:      return "100 agent runs"
        case .cargo:        return "50 hours total usage"
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
        case .jeans:        return "총 15시간 사용"
        case .shorts:       return "총 100회 세션"
        case .slacks:       return "100만 토큰 사용"
        case .joggers:      return "에이전트 100회 실행"
        case .cargo:        return "총 50시간 사용"
        }
    }

    static var hats: [AccessoryType] {
        allCases.filter { $0.category == .hat }
    }

    static var glasses: [AccessoryType] {
        allCases.filter { $0.category == .glasses }
    }

    static var pants: [AccessoryType] {
        allCases.filter { $0.category == .pants }
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
