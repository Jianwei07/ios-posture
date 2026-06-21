import Foundation

// Low-pass filter to smooth AirPods IMU noise.
// filtered(t) = α * raw(t) + (1-α) * filtered(t-1)
struct MotionFilter {
    var alpha: Double
    private var previous: Double?

    init(alpha: Double = 0.15) {
        self.alpha = alpha
    }

    mutating func filter(_ value: Double) -> Double {
        let result = alpha * value + (1 - alpha) * (previous ?? value)
        previous = result
        return result
    }

    mutating func reset() {
        previous = nil
    }
}
