import SwiftUI

// The three live posture states. Driven by the engine off the smoothed forward
// angle vs the calibrated baseline. See design.md.
enum PostureState: String, CaseIterable {
    case aligned = "aligned"   // within threshold
    case drift   = "drift"     // past sensitivity threshold
    case slouch  = "slouch"    // deep + sustained

    // Big state word shown on Home.
    var word: String {
        switch self {
        case .aligned: return "Aligned"
        case .drift:   return "Easing forward"
        case .slouch:  return "Slouching"
        }
    }

    // Sub-copy under the word when no angle is shown (aligned only).
    var subcopy: String {
        switch self {
        case .aligned: return "head & neck look good"
        case .drift:   return "ease back when you can"
        case .slouch:  return "sit tall — lift your head"
        }
    }

    var color: Color {
        switch self {
        case .aligned: return Theme.Palette.aligned
        case .drift:   return Theme.Palette.drift
        case .slouch:  return Theme.Palette.slouch
        }
    }
}
