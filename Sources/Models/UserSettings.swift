import Foundation
import SwiftData

// Minimal user settings — only the two reminder intervals. Posture thresholds
// are constants in PostureClassifier; alert timing is constant in ReminderScheduler.
@Model
final class UserSettings {
    var baseWaterIntervalMin: Double
    var baseWalkIntervalMin: Double

    init() {
        baseWaterIntervalMin = 30.0
        baseWalkIntervalMin = 45.0
    }

    func reset() {
        baseWaterIntervalMin = 30.0
        baseWalkIntervalMin = 45.0
    }
}
