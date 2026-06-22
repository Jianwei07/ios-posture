import Foundation

// Pure function: classify posture from filtered pitch + neutral baseline.
// Thresholds are sensible constants (no longer user-configurable).
struct PostureClassifier {
    var poorPitchThreshold: Double = -20      // head-down degrees → poor
    var warningPitchThreshold: Double = -10
    var forwardHeadThreshold: Double = 15     // forward of neutral → poor

    func classify(filteredPitch: Double, neutralPitch: Double?) -> PostureState {
        guard let neutral = neutralPitch else { return .good }

        let delta = filteredPitch - neutral

        if delta > forwardHeadThreshold { return .poor }     // forward head
        if filteredPitch < poorPitchThreshold { return .poor }
        if filteredPitch < warningPitchThreshold { return .warning }
        return .good
    }
}
