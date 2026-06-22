import Foundation

// Pure function: classify posture from filtered pitch + neutral baseline.
//
// `forwardAngle` = how far the head has dropped below the calibrated baseline,
// in degrees (positive = leaning forward / down). AirPods pitch drops as the
// head tilts down, so forwardAngle = neutral - filteredPitch.
//
//   forwardAngle <  threshold              → aligned
//   forwardAngle >= threshold              → drift
//   forwardAngle >= threshold + slouchGap  → slouch (deep)
//
// `threshold` is the user's sensitivity (Relaxed 22° / Balanced 15° / Strict 8°).
struct PostureClassifier {
    var threshold: Double = 15      // drift past this many degrees below baseline
    var slouchGap: Double = 6       // additional degrees past threshold → slouch

    func forwardAngle(filteredPitch: Double, neutralPitch: Double) -> Double {
        max(0, neutralPitch - filteredPitch)
    }

    func classify(filteredPitch: Double, neutralPitch: Double?) -> PostureState {
        guard let neutral = neutralPitch else { return .aligned }
        let angle = forwardAngle(filteredPitch: filteredPitch, neutralPitch: neutral)
        if angle >= threshold + slouchGap { return .slouch }
        if angle >= threshold { return .drift }
        return .aligned
    }
}
