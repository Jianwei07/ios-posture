import Foundation

// Captures neutral head position at session start.
// Forward head = current pitch deviates > threshold above neutral.
final class CalibrationStore {
    private(set) var neutralPitch: Double?
    private var samples: [Double] = []
    private let sampleTarget = 60  // 3s @ 20Hz

    var isCalibrated: Bool { neutralPitch != nil }
    var progress: Double { min(1.0, Double(samples.count) / Double(sampleTarget)) }

    func addSample(_ pitch: Double) {
        guard neutralPitch == nil else { return }
        samples.append(pitch)
        if samples.count >= sampleTarget {
            neutralPitch = samples.reduce(0, +) / Double(samples.count)
        }
    }

    func reset() {
        neutralPitch = nil
        samples = []
    }
}
