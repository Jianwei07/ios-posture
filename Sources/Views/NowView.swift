import SwiftUI
import SwiftData

// Home · Now — the live hero. Spine mirrors posture; word + colour + angle move
// together. Water/walk are secondary chips. See design.md.
struct NowView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]
    @Query(sort: \WaterEntry.timestamp, order: .reverse) private var waterEntries: [WaterEntry]

    @State private var overlayMessage: String?
    @State private var showOverlay = false
    @State private var showCalibrate = false
    @State private var dismissTask: Task<Void, Never>?

    private var settings: UserSettings { settingsArray.first ?? UserSettings() }
    private var engine: PostureEngine { app.engine }
    private var isActive: Bool { app.session.state == .active }
    private var calibrating: Bool { isActive && engine.calibrationProgress < 1 && engine.calibrationProgress > 0 }
    private var needsBaseline: Bool { settings.baselinePitch == nil }
    private var state: PostureState { engine.postureState }

    private var todayWaterMl: Double {
        let start = Calendar.current.startOfDay(for: .now)
        return waterEntries.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.volumeMl }
    }

    private var waterProgress: Double {
        let target = settings.dailyWaterTargetMl
        guard target > 0 else { return 0 }
        return min(1, todayWaterMl / target)
    }

    private var waterDisplay: String {
        String(format: "%.1fL / %.1fL", todayWaterMl / 1000, settings.dailyWaterTargetMl / 1000)
    }

    var body: some View {
        ZStack {
            Theme.Palette.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                connectionChip
                    .padding(.top, 8)
                Spacer(minLength: 12)
                PlantMascot(kind: settings.selectedPlant,
                            bend: isActive ? app.liveBend : 0,
                            color: isActive ? state.color : Theme.Palette.inkFaint)
                    .frame(height: 200)
                    .opacity(isActive ? 1 : 0.55)
                stateBlock
                    .padding(.top, 18)
                Spacer(minLength: 12)
                habitChips
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .overlay(alignment: .top) { if showOverlay, let m = overlayMessage { nudgeBanner(m) } }
        .sheet(isPresented: $showCalibrate, onDismiss: {
            if app.engine.neutralPitch == nil, settings.baselinePitch != nil {
                app.engine.seedBaseline(settings.baselinePitch)
            }
        }) {
            CalibrateView(engine: app.engine, mode: .recalibrate) { baseline in
                if let b = baseline { settings.baselinePitch = b; save() }
                else { app.engine.seedBaseline(settings.baselinePitch) }
                showCalibrate = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationModule.overlayNotification)) { note in
            if let type = note.object as? ReminderType { flash(type.title + " — " + type.body) }
        }
    }

    // MARK: Pieces

    private var connectionChip: some View {
        let connected = app.isConnected
        return HStack(spacing: 7) {
            Circle().fill(connected ? Theme.Palette.accent : Theme.Palette.inkFaint)
                .frame(width: 6, height: 6)
            Text(connected ? "AirPods connected" : "AirPods not connected")
                .font(Theme.Font.caption())
                .foregroundStyle(connected ? Theme.Palette.accent : Theme.Palette.inkFaint)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .overlay(Capsule().stroke(Theme.Palette.inkFaint.opacity(0.4)))
    }

    private var stateBlock: some View {
        VStack(spacing: 4) {
            Text(needsBaseline
                ? "Set your baseline"
                : (calibrating ? "Getting your baseline…" : (isActive ? state.word : "Pop your AirPods in")))
                .font(Theme.Font.hero(30))
                .foregroundStyle(isActive && !calibrating && !needsBaseline ? state.color : Theme.Palette.inkSoft)
                .animation(Theme.Motion.fade, value: state)
            Text(subline)
                .font(Theme.Font.body(14))
                .foregroundStyle(Theme.Palette.inkSoft)
            if needsBaseline {
                Button { showCalibrate = true } label: {
                    Text("Set baseline")
                        .font(Theme.Font.body(15).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 12)
                        .background(Theme.Palette.accent, in: Capsule())
                }
                .pressable()
                .padding(.top, 10)
            } else if isActive && !calibrating {
                Text("\(uprightMinutes) min upright")
                    .font(Theme.Font.caption(13).weight(.bold))
                    .foregroundStyle(Theme.Palette.inkFaint)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var subline: String {
        if needsBaseline { return "calibrate to start tracking" }
        guard isActive, !calibrating else { return "to begin" }
        switch state {
        case .aligned: return state.subcopy
        default:       return "−\(Int(engine.forwardAngle))° · \(state.subcopy)"
        }
    }

    private var habitChips: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HabitChip(label: "water", value: waterDisplay,
                          progress: waterProgress,
                          tint: Theme.Palette.accent, action: logWater)
                HabitChip(label: "walk", value: walkDisplay,
                          progress: walkProgress,
                          tint: Theme.Palette.drift, action: nil)
            }
            SunlightChip(value: sunlightDisplay, nextNudge: app.sunlightScheduler.nextNudge)
        }
    }

    private var sunlightDisplay: String {
        guard let next = app.sunlightScheduler.nextNudge else { return "—" }
        if next < .now { return "done today" }
        return next.formatted(.dateTime.hour().minute())
    }

    private var walkDisplay: String {
        let steps = app.stepReader.todaySteps
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        }
        return "\(steps)"
    }

    private var walkProgress: Double {
        let target = settings.dailyStepTarget
        guard target > 0 else { return 0 }
        return min(1, Double(app.stepReader.todaySteps) / Double(target))
    }

    private func nudgeBanner(_ message: String) -> some View {
        Text(message)
            .font(Theme.Font.body(14))
            .foregroundStyle(Theme.Palette.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip).stroke(Theme.Palette.drift.opacity(0.5)))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
            .padding(.top, 10).padding(.horizontal, 22)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var uprightMinutes: Int { Int((app.session.activeSessionSeconds) / 60) }

    private func logWater() {
        modelContext.insert(WaterEntry())
        try? modelContext.save()
    }

    private func save() { try? modelContext.save() }

    private func flash(_ message: String) {
        dismissTask?.cancel()
        overlayMessage = message
        withAnimation(Theme.Motion.ui) { showOverlay = true }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Motion.fade) { showOverlay = false }
        }
    }
}

// Secondary habit chip: label · value with a thin progress bar.
private struct HabitChip: View {
    var label: String
    var value: String
    var progress: Double
    var tint: Color
    var action: (() -> Void)?

    var body: some View {
        Button { action?() } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label).font(Theme.Font.caption()).foregroundStyle(Theme.Palette.inkFaint)
                    Spacer()
                    Text(value).font(Theme.Font.number(15)).foregroundStyle(Theme.Palette.ink)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.Palette.inkFaint.opacity(0.18))
                        Capsule().fill(tint)
                            .frame(width: geo.size.width * max(0, min(1, progress)))
                    }
                }
                .frame(height: 5)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .card()
        }
        .pressable()
        .disabled(action == nil)
    }
}

// Sunlight chip — no progress bar, just a label + next nudge time.
private struct SunlightChip: View {
    var value: String
    var nextNudge: Date?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sun.max")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Palette.aligned)
            Text("sunlight")
                .font(Theme.Font.caption())
                .foregroundStyle(Theme.Palette.inkFaint)
            Spacer()
            Text(value)
                .font(Theme.Font.body(13).weight(.semibold))
                .foregroundStyle(Theme.Palette.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .card()
    }
}
