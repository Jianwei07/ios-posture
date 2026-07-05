import Foundation
import SwiftData

@Model
final class PostureSession {
    var startTime: Date
    var endTime: Date?
    var avgPitch: Double
    var poorPosturePct: Double  // 0.0–1.0
    var score: Int              // 0–100
    @Relationship(deleteRule: .cascade) var readings: [PostureReading]

    init(startTime: Date = .now) {
        self.startTime = startTime
        self.avgPitch = 0
        self.poorPosturePct = 0
        self.score = 100
        self.readings = []
    }

    var durationSeconds: TimeInterval {
        (endTime ?? .now).timeIntervalSince(startTime)
    }
}
