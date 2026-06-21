import Foundation

enum PostureState: String, CaseIterable {
    case good    = "good"
    case warning = "warning"
    case poor    = "poor"

    var label: String {
        switch self {
        case .good:    return "Good"
        case .warning: return "Adjust"
        case .poor:    return "Poor"
        }
    }
}
