import Foundation

enum PetType: String, CaseIterable, Codable {
    case cat, hamster, chick, penguin, fox, rabbit
    case goose, capybara, sloth, owl, dragon, unicorn

    var displayName: String {
        switch self {
        case .cat:      return "Cat"
        case .hamster:  return "Hamster"
        case .chick:    return "Chick"
        case .penguin:  return "Penguin"
        case .fox:      return "Fox"
        case .rabbit:   return "Rabbit"
        case .goose:    return "Goose"
        case .capybara: return "Capybara"
        case .sloth:    return "Sloth"
        case .owl:      return "Owl"
        case .dragon:   return "Dragon"
        case .unicorn:  return "Unicorn"
        }
    }

    var unlockDescription: String {
        switch self {
        case .cat:      return "Default pet"
        case .hamster:  return "Total 10 sessions"
        case .chick:    return "5 hours total usage"
        case .penguin:  return "500K tokens used"
        case .fox:      return "50 agent runs"
        case .rabbit:   return "3+ concurrent sessions"
        case .goose:    return "30 hours total usage"
        case .capybara: return "10 rate limit hits"
        case .sloth:    return "20 long sessions (45m+)"
        case .owl:      return "10 hours on Opus"
        case .dragon:   return "5+ concurrent agents"
        case .unicorn:  return "Unlock all pets"
        }
    }
}

enum MuscleStage: Int, CaseIterable {
    case normal = 0
    case buff = 1
    case macho = 2

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .buff:   return "Buff"
        case .macho:  return "Macho!"
        }
    }

    static func resolve(agentCount: Int) -> MuscleStage {
        if agentCount >= 4 { return .macho }
        if agentCount >= 2 { return .buff }
        return .normal
    }
}
