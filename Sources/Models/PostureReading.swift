import Foundation
import SwiftData

@Model
final class PostureReading {
    var timestamp: Date
    var pitch: Double
    var classification: String  // "good" | "warning" | "poor"

    init(timestamp: Date = .now, pitch: Double, classification: PostureState) {
        self.timestamp = timestamp
        self.pitch = pitch
        self.classification = classification.rawValue
    }
}
