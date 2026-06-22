import Foundation

// Calibration is a sub-phase of `active` (engine.calibrationProgress < 1), not its own state.
enum SessionState: String {
    case idle
    case active
    case paused
}
