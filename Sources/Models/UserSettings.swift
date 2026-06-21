import Foundation
import SwiftData

@Model
final class UserSettings {
    // Posture thresholds (degrees)
    var poorPitchThreshold: Double      // head-down degrees triggering poor
    var warningPitchThreshold: Double
    var forwardHeadThreshold: Double    // forward deviation from neutral

    // Water reminder interval (minutes)
    var baseWaterIntervalMin: Double

    // Posture alert
    var postureAlertSustainedSeconds: Double
    var postureAlertCooldownMin: Double

    init() {
        poorPitchThreshold = -20.0
        warningPitchThreshold = -10.0
        forwardHeadThreshold = 15.0
        baseWaterIntervalMin = 30.0
        postureAlertSustainedSeconds = 30.0
        postureAlertCooldownMin = 5.0
    }

    func reset() {
        poorPitchThreshold = -20.0
        warningPitchThreshold = -10.0
        forwardHeadThreshold = 15.0
        baseWaterIntervalMin = 30.0
        postureAlertSustainedSeconds = 30.0
        postureAlertCooldownMin = 5.0
    }
}
