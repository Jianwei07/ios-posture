import SwiftUI
#if os(macOS)
import AppKit
#endif

// Replaces the active screen whenever the IMU stream drops (BT off / AirPods out
// / non-Pro buds). Auto-dismisses on reconnect. Never shows stale posture.
struct DisconnectedView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color(hex: 0xFBF1EC).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Theme.Palette.drift)
                Text("AirPods not connected")
                    .font(Theme.Font.hero(22)).foregroundStyle(Color(hex: 0xB0703F))
                    .padding(.top, 22)
                Text("Turn on Bluetooth and wear compatible AirPods to start tracking.")
                    .font(Theme.Font.body(14)).multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: 0xA8896F))
                    .padding(.top, 10).padding(.horizontal, 36)

                Button { openSettings() } label: {
                    Text("Open Bluetooth settings")
                        .font(Theme.Font.body(15).weight(.semibold)).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Theme.Palette.ink, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                }
                .pressable().padding(.top, 28).padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Circle().fill(Theme.Palette.inkFaint).frame(width: 8, height: 8)
                        .opacity(pulse ? 0.3 : 1)
                    Text("waiting for AirPods…")
                        .font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkFaint)
                }
                .padding(.top, 16)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}
