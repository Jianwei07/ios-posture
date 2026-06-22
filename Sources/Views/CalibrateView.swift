import SwiftUI

// Calibrate baseline — a 5-second still hold captures the upright baseline.
// Shared by onboarding (step 03) and Settings → Recalibrate. See design.md.
struct CalibrateView: View {
    enum Mode { case onboarding, recalibrate }

    let engine: PostureEngine
    var mode: Mode = .onboarding
    var onDone: (Double?) -> Void

    @State private var capturing = false
    @State private var timeoutFired = false
    @State private var timeoutTimer: Timer?

    private var progress: Double { engine.calibrationProgress }
    private var countdown: Int { max(1, Int(ceil((1 - progress) * 5))) }

    var body: some View {
        ZStack {
            Theme.Palette.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 30)
                Text("Sit how you want\nto hold yourself")
                    .font(Theme.Font.hero(26)).multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Hold still 5 seconds — your upright becomes the baseline.")
                    .font(Theme.Font.body(14)).multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.inkSoft)
                    .padding(.top, 8).padding(.horizontal, 30)

                ring.padding(.top, 40)

                Spacer()

                Button { capturing ? () : start() } label: {
                    Text(capturing ? "Hold still…" : "Set baseline")
                        .font(Theme.Font.body(15).weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                }
                .pressable().disabled(capturing)
                .padding(.horizontal, 24)

                Button { skip() } label: {
                    Text("Skip for now")
                        .font(Theme.Font.body(13).weight(.semibold))
                        .foregroundStyle(Theme.Palette.inkFaint)
                }
                .padding(.top, 12).padding(.bottom, 24)
            }
        }
        .onChange(of: progress) { _, p in
            if capturing && p >= 1 { finish() }
        }
        .onDisappear { cleanup() }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(Theme.Palette.aligned.opacity(0.18), lineWidth: 8)
            Circle().trim(from: 0, to: max(0.001, capturing ? progress : 0))
                .stroke(Theme.Palette.aligned, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: progress)
            VStack(spacing: 6) {
                PlantMascot(kind: .sunflower, bend: 0, color: Theme.Palette.aligned)
                    .frame(height: 70)
                if capturing {
                    Text("\(countdown)").font(Theme.Font.number(22)).foregroundStyle(Theme.Palette.aligned)
                }
            }
        }
        .frame(width: 168, height: 168)
    }

    private func start() {
        engine.recalibrate()
        engine.start()
        capturing = true
        timeoutFired = false
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            DispatchQueue.main.async {
                guard capturing, !timeoutFired else { return }
                timeoutFired = true
                finish()
            }
        }
    }

    private func finish() {
        cleanup()
        capturing = false
        let baseline = engine.neutralPitch ?? engine.currentPitch
        onDone(baseline)
    }

    private func skip() {
        cleanup()
        capturing = false
        onDone(engine.currentPitch == 0 ? 0 : engine.currentPitch)
    }

    private func cleanup() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
