import Foundation

enum RecommendationLevel: Int, Comparable {
    case normal = 0, warning = 1, critical = 2
    static func < (lhs: RecommendationLevel, rhs: RecommendationLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct Recommendation {
    let level: RecommendationLevel
    let text: String
}

func computeRecommendation(stats: SystemStats, config: Config) -> Recommendation {
    var reasons: [String] = []
    var level: RecommendationLevel = .normal

    switch stats.pressure {
    case .critical:
        level = .critical
        reasons.append("memory critical")
    case .warning:
        level = max(level, .warning)
        reasons.append("memory low")
    case .normal:
        break
    }

    if stats.diskFreeGB < config.diskCriticalGB {
        level = .critical
        reasons.append("disk almost full")
    } else if stats.diskFreeGB < config.diskWarningGB {
        level = max(level, .warning)
        reasons.append("disk getting full")
    }

    if !stats.isOnACPower, let pct = stats.batteryPercent, pct < config.batteryWarningPercent {
        level = max(level, .warning)
        reasons.append("battery low")
    }

    switch stats.thermalState {
    case .critical:
        level = .critical
        reasons.append("thermal critical")
    case .serious:
        level = max(level, .warning)
        reasons.append("thermal throttling")
    default:
        break
    }

    switch level {
    case .critical:
        return Recommendation(level: .critical, text: "Run new sessions in cloud — " + reasons.joined(separator: ", "))
    case .warning:
        return Recommendation(level: .warning, text: "Prefer cloud for new sessions — " + reasons.joined(separator: ", "))
    case .normal:
        return Recommendation(level: .normal, text: "Plenty of headroom — local is fine")
    }
}
