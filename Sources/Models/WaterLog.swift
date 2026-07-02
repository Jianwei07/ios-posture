import Foundation
import SwiftData

// One logged glass of water. Default 250ml per tap. Volume stored in ml.
@Model
final class WaterEntry {
    var volumeMl: Double = 250
    var timestamp: Date = Date(timeIntervalSince1970: 0)

    init(volumeMl: Double = 250, timestamp: Date = .now) {
        self.volumeMl = volumeMl
        self.timestamp = timestamp
    }
}
