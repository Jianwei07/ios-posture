import SwiftUI

// Plant mascot system — each plant maps `bend` (0=aligned, 1=slouch) to its own visual.
// Add a new plant: conform to Plant, add to PlantKind enum, register in PlantFactory.
// See design.md — the spine icon is replaced by a plant that mirrors posture.

enum PlantKind: String, CaseIterable, Identifiable {
    case sunflower, cactus, monstera
    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunflower: return "Sunflower"
        case .cactus:    return "Cactus"
        case .monstera:  return "Monstera"
        }
    }

    var emoji: String {
        switch self {
        case .sunflower: return "🌻"
        case .cactus:    return "🌵"
        case .monstera:  return "🪴"
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
            case .sunflower: Sunflower(bend: bend, color: color)
            case .cactus:    Cactus(bend: bend, color: color)
            case .monstera:  Monstera(bend: bend, color: color)
            }
        }
        .animation(Theme.Motion.pose, value: bend)
        .animation(Theme.Motion.fade, value: color)
    }
}
