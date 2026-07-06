import SwiftUI

// Plant mascot system — each plant maps `bend` (0=aligned, 1=slouch) to its own visual.
// Add a new plant: conform to Plant, add to PlantKind enum, register in the switch below.
// See design.md — a plant mirrors live posture instead of an abstract icon.

enum PlantKind: String, CaseIterable, Identifiable {
    case sunflower, monstera
    case vandaOrchid, hibiscus, melatiJasmine, sampaguita, lotus
    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunflower:     return "Sunflower"
        case .monstera:      return "Monstera"
        case .vandaOrchid:   return "Vanda orchid"
        case .hibiscus:      return "Hibiscus"
        case .melatiJasmine: return "Melati jasmine"
        case .sampaguita:    return "Sampaguita"
        case .lotus:         return "Lotus"
        }
    }

    // Picker caption (design board: national-flower roster).
    var region: String? {
        switch self {
        case .sunflower:     return nil  // "Your default" handled by picker
        case .monstera:      return "Cosmetic"
        case .vandaOrchid:   return "Singapore"
        case .hibiscus:      return "Malaysia"
        case .melatiJasmine: return "Indonesia"
        case .sampaguita:    return "Philippines"
        case .lotus:         return "Vietnam"
        }
    }
}

protocol Plant: View, Animatable {
    var bend: Double { get set }  // 0 = upright/happy, 1 = slouched/drooped
    var color: Color { get }      // state color (aligned/drift/slouch)
}

// Canvas has no animatable properties of its own — without this, pose changes
// snap instead of tweening. Interpolating `bend` re-renders each frame.
extension Plant {
    var animatableData: Double {
        get { bend }
        set { bend = newValue }
    }
}

// Wrapper view so call sites don't need to know the concrete plant type.
struct PlantMascot: View {
    let kind: PlantKind
    let bend: Double
    let color: Color

    var body: some View {
        Group {
            switch kind {
            case .sunflower:     Sunflower(bend: bend, color: color)
            case .monstera:      Monstera(bend: bend, color: color)
            case .vandaOrchid:   VandaOrchid(bend: bend, color: color)
            case .hibiscus:      Hibiscus(bend: bend, color: color)
            case .melatiJasmine: MelatiJasmine(bend: bend, color: color)
            case .sampaguita:    Sampaguita(bend: bend, color: color)
            case .lotus:         Lotus(bend: bend, color: color)
            }
        }
        .animation(Theme.Motion.pose, value: bend)
        .animation(Theme.Motion.fade, value: color)
    }
}
