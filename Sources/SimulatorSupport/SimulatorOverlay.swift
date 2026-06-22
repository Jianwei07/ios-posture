import SwiftUI

#if targetEnvironment(simulator)

// Floating simulator harness — a collapsed SIM chip that expands into controls.
// Sits at the root of ContentView so it overlays ALL screens (onboarding, disconnected,
// Now, Trends, Settings) without shifting app layout. Delete this folder to ship.
struct SimulatorOverlay: View {
    @Bindable var source: SimulatedMotionSource
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            chip
            if expanded {
                panel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.trailing, 16)
        .padding(.top, 8)
        .allowsHitTesting(true)
    }

    private var chip: some View {
        Button { withAnimation(Theme.Motion.ui) { expanded.toggle() } } label: {
            Text(expanded ? "SIM ×" : "SIM")
                .font(Theme.Font.caption(11).weight(.bold))
                .foregroundStyle(Theme.Palette.accent)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Theme.Palette.accent.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Theme.Palette.accent.opacity(0.4)))
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIMULATOR — fake AirPods")
                .font(Theme.Font.caption(10))
                .foregroundStyle(Theme.Palette.inkFaint)

            HStack(spacing: 6) {
                presetBtn("Aligned", pitch: 0)
                presetBtn("Drift", pitch: -16)
                presetBtn("Slouch", pitch: -22)
            }

            HStack {
                Text(String(format: "Pitch %.0f°", source.simulatedPitch))
                    .font(Theme.Font.caption())
                    .frame(width: 72, alignment: .leading)
                Slider(value: $source.simulatedPitch, in: -45 ... 45)
                    .tint(Theme.Palette.accent)
            }

            Toggle("Connected", isOn: $source.available)
                .font(Theme.Font.caption())
                .tint(Theme.Palette.accent)
        }
        .padding(14)
        .frame(width: 260)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.accent.opacity(0.3)))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private func presetBtn(_ title: String, pitch: Double) -> some View {
        Button {
            source.simulatedPitch = pitch
        } label: {
            Text(title)
                .font(Theme.Font.caption(11).weight(.semibold))
                .foregroundStyle(Theme.Palette.ink)
                .frame(maxWidth: .infinity).padding(.vertical, 7)
                .background(Theme.Palette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

#endif
