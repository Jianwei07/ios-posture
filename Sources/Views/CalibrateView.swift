import SwiftUI

// Calibrate baseline — a 5-second still hold captures the upright baseline.
// Shared by onboarding (step 03) and Settings → Recalibrate. See design.md.
struct CalibrateView: View {
    enum Mode { case onboarding, recalibrate }

    let engine: PostureEngine
    var mode: Mode = .onboarding
    var onDone: (Double?) -> Void

    @State private var capturing = false
    @State private var failed = false
    @State private var failReason: String?
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

                if failed {
                    Text(failReason ?? "Couldn't get a steady baseline.")
                        .font(Theme.Font.body(14))
                        .foregroundStyle(Theme.Palette.slouch)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Button { tryAgain() } label: {
                        Text("Try again")
                            .font(Theme.Font.body(15).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                    }
                    .pressable()
                    .padding(.horizontal, 24).padding(.top, 12)
                    Button { cancel() } label: {
                        Text(mode == .onboarding ? "Skip — I'll set this later" : "Cancel")
                            .font(Theme.Font.body(13).weight(.semibold))
                            .foregroundStyle(Theme.Palette.inkFaint)
                    }
                    .padding(.top, 10).padding(.bottom, 24)
                } else {
                    Button { capturing ? () : start() } label: {
                        Text(capturing ? "Hold still…" : "Set baseline")
                            .font(Theme.Font.body(15).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Theme.Palette.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                    }
                    .pressable().disabled(capturing)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .onChange(of: progress) { _, p in
            if capturing && p >= 1 { finish() }
        }
        .onDisappear {
            if capturing { engine.cancelCalibration() }
            cleanup()
        }
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
        failed = false
        failReason = nil
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            DispatchQueue.main.async {
                guard capturing else { return }
                finish()
            }
        }
    }

    private func finish() {
        cleanup()
        capturing = false
        if let baseline = engine.neutralPitch {
            onDone(baseline)
        } else {
            let spread = engine.calibrationSpread
            engine.cancelCalibration()
            failed = true
            failReason = spread > 4
                ? "Too much movement. Sit upright, keep your head still, and try again."
                : "Couldn't get a steady baseline. Check your AirPods are in and try again."
        }
    }

    private func tryAgain() {
        failed = false
        failReason = nil
        start()
    }

    private func cancel() {
        cleanup()
        capturing = false
        onDone(nil)
    }

    private func cleanup() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
