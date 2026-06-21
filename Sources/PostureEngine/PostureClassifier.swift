import Foundation

// Pure function: classify posture from filtered pitch + neutral baseline.
// All thresholds come from UserSettings to stay configurable.
struct PostureClassifier {
    let poorPitchThreshold: Double      // e.g. -20°
    let warningPitchThreshold: Double   // e.g. -10°
    let forwardHeadThreshold: Double    // e.g. +15° above neutral

    func classify(filteredPitch: Double, neutralPitch: Double?) -> PostureState {
        guard let neutral = neutralPitch else { return .good }

        let delta = filteredPitch - neutral

        // Forward head: pitch rises above neutral by threshold
        if delta > forwardHeadThreshold { return .poor }

        // Head-down: pitch falls below thresholds
        if filteredPitch < poorPitchThreshold { return .poor }
        if filteredPitch < warningPitchThreshold { return .warning }

        return .good
    }
}
