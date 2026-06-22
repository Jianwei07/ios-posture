import SwiftUI

// First-run onboarding: Connect → Permissions → Calibrate, each step gating the
// next. Lands on Home when the baseline is captured. See design.md.
struct OnboardingFlow: View {
    let settings: UserSettings
    var onFinish: () -> Void
    var onSkip: () -> Void

    @Environment(AppModel.self) private var app
    @State private var step = 0

    var body: some View {
        ZStack {
            Theme.Palette.bg.ignoresSafeArea()
            switch step {
            case 0: ConnectStep(connected: app.isConnected, onNext: { step = 1 }, onSkip: onSkip)
            case 1: PermissionsStep(onNext: { step = 2 })
            default:
                CalibrateView(engine: app.engine, mode: .onboarding) { baseline in
                    settings.baselinePitch = baseline
                    onFinish()
                }
            }
        }
        .animation(Theme.Motion.ui, value: step)
    }
}

// MARK: - 01 Connect

private struct ConnectStep: View {
    var connected: Bool
    var onNext: () -> Void
    var onSkip: () -> Void

    @State private var detected = false
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(Theme.Palette.inkFaint.opacity(0.6))
                .background(Theme.Palette.surface.opacity(0.5))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "airpodspro")
                        .font(.system(size: 44))
                        .foregroundStyle(detected ? Theme.Palette.accent : Theme.Palette.inkFaint)
                        .scaleEffect(pulse ? 1.08 : 1.0)
                )
            Text(detected ? "AirPods detected" : "Use the AirPods\nalready in your ears")
                .font(Theme.Font.hero(26)).multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.ink).padding(.top, 28)
            Text("Reads tiny head movements from the AirPods Pro sensor. Nothing leaves your phone.")
                .font(Theme.Font.body(14)).multilineTextAlignment(.center)
                .foregroundStyle(Theme.Palette.inkSoft).padding(.top, 10).padding(.horizontal, 36)
            Spacer()
            if detected {
                Text("Connecting…")
                    .font(Theme.Font.caption()).foregroundStyle(Theme.Palette.accent)
                    .padding(.bottom, 10)
            }
            primaryButton("Connect AirPods", enabled: connected, action: onNext)
                .padding(.horizontal, 24)
            Button { onSkip() } label: {
                Text("Skip to dashboard")
                    .font(Theme.Font.body(13)).foregroundStyle(Theme.Palette.inkFaint)
            }
            .padding(.top, 12).padding(.bottom, 24)
        }
        .onAppear { startPulse() }
        .onChange(of: connected) { _, isConn in
            if isConn && !detected {
                detected = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onNext() }
            }
        }
        .onAppear {
            if connected && !detected {
                detected = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onNext() }
            }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { pulse = true }
    }
}

// MARK: - 02 Permissions

private struct PermissionsStep: View {
    var onNext: () -> Void
    @Environment(AppModel.self) private var app
    @State private var healthGranted: Bool? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 30)
            Text("A couple of permissions").font(Theme.Font.hero(24)).foregroundStyle(Theme.Palette.ink)
            Text("Everything stays on your device.")
                .font(Theme.Font.body(14)).foregroundStyle(Theme.Palette.inkSoft).padding(.top, 4)

            VStack(spacing: 11) {
                permRow("Motion & Fitness", "required — head motion", granted: true)
                permRow("Notifications", "for gentle nudges", granted: true)
                Button {
                    Task {
                        await app.stepReader.requestPermission()
                        app.stepReader.refresh()
                        healthGranted = true
                    }
                } label: {
                    permRow("Apple Health", "optional — tap to allow steps", granted: healthGranted == true)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 22)

            Spacer()
            primaryButton("Continue", enabled: true) {
                Task {
                    await NotificationModule.shared.requestPermission()
                    onNext()
                }
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private func permRow(_ title: String, _ sub: String, granted: Bool) -> some View {
        HStack(spacing: 10) {
            Circle().stroke(granted ? Theme.Palette.aligned : Theme.Palette.inkFaint, lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay(granted ? Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.Palette.aligned) : nil)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.Font.body(14).weight(.semibold)).foregroundStyle(Theme.Palette.ink)
                Text(sub).font(Theme.Font.caption(11)).foregroundStyle(Theme.Palette.inkFaint)
            }
            Spacer()
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.ink.opacity(0.12)))
    }
}

// MARK: - shared

private func primaryButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
            .font(Theme.Font.body(15).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(enabled ? Theme.Palette.ink : Theme.Palette.inkFaint,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
    }
    .pressable().disabled(!enabled)
}
