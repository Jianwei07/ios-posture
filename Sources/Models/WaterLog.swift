import Foundation
import SwiftData

// One logged glass of water. Today's count = entries since start of today.
@Model
final class WaterEntry {
    var timestamp: Date

    init(timestamp: Date = .now) {
        self.timestamp = timestamp
    }
}

enum WaterGoal {
    static let dailyTarget = 8  // glasses
}
