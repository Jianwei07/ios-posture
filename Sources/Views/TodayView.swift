import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [UserSettings]
    @Query(sort: \WaterEntry.timestamp, order: .reverse) private var waterEntries: [WaterEntry]

    @State private var engine: PostureEngine?
    @State private var sessionManager: SessionManager?
    @State private var scheduler: ReminderScheduler?
    @State private var simSource: SimulatedMotionSource?

    @State private var overlayMessage: String?
    @State private var showOverlay = false

    private var settings: UserSettings { settingsArray.first ?? UserSettings() }

    private var todayWater: Int {
        let start = Calendar.current.startOfDay(for: .now)
        return waterEntries.filter { $0.timestamp >= start }.count
    }

    private var state: SessionState { sessionManager?.state ?? .idle }
    private var isActive: Bool { state == .active }

    private var liveSlouch: Double {
        guard let eng = engine, isActive else { return StickmanPose.napping.slouch }
        return StickmanMapping.slouch(pitch: eng.currentPitch, neutral: eng.neutralPitch)
    }

    var body: some View {
        ZStack {
            Theme.Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    hero
                    statusLine
                    habitRow
                    sessionControl
                    if let sim = simSource {
                        DebugMotionPanel(source: sim)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .top) {
            if showOverlay, let msg = overlayMessage { banner(msg) }
        }
        .task { await setup() }
        .onReceive(NotificationCenter.default.publisher(for: NotificationModule.overlayNotification)) { note in
            if let type = note.object as? ReminderType { showBanner(type.title) }
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(Theme.Font.hero(34))
                .foregroundStyle(Theme.Palette.ink)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                .font(Theme.Font.body())
                .foregroundStyle(Theme.Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hero: some View {
        ZStack {
            // soft status tint behind the figure
            RoundedRectangle(cornerRadius: 36)
                .fill((isActive ? engine?.postureState.warmColor : Theme.Palette.inkSoft)?
                    .opacity(0.10) ?? .clear)
                .animation(Theme.Motion.fade, value: engine?.postureState)

            StickmanView(slouch: liveSlouch, resting: !isActive)
                .frame(height: 260)
                .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusLine: some View {
        Text(statusCopy)
            .font(Theme.Font.title())
            .foregroundStyle(isActive ? (engine?.postureState.warmColor ?? Theme.Palette.ink) : Theme.Palette.inkSoft)
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(Theme.Motion.fade, value: statusCopy)
    }

    private var habitRow: some View {
        HStack(spacing: 12) {
            HabitCard(
                title: "POSTURE",
                value: sessionManager.map { formatTime($0.activeSessionSeconds) } ?? "0:00",
                caption: isActive ? (engine?.postureState.kindCopy ?? "") : "tap AirPods in",
                progress: postureProgress,
                color: isActive ? (engine?.postureState.warmColor ?? Theme.Palette.good) : Theme.Palette.good
            )
            HabitCard(
                title: "WATER",
                value: "\(todayWater)/\(WaterGoal.dailyTarget)",
                caption: "tap to log a glass",
                progress: Double(todayWater) / Double(WaterGoal.dailyTarget),
                color: Theme.Palette.honey,
                action: logWater
            )
            HabitCard(
                title: "WALK",
                value: "\(Int(settings.baseWalkIntervalMin))m",
                caption: "stand & stretch",
                progress: walkProgress,
                color: Theme.Palette.good
            )
        }
    }

    private var sessionControl: some View {
        Group {
            if state == .active || state == .paused {
                Button {
                    sessionManager?.endSession()
                } label: {
                    Text("End session")
                        .font(Theme.Font.title(16))
                        .foregroundStyle(Theme.Palette.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Palette.ink, in: Capsule())
                }
                .pressable()
            }
        }
    }

    private func banner(_ message: String) -> some View {
        Text(message)
            .font(Theme.Font.title(15))
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Theme.Palette.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.Palette.honey.opacity(0.5)))
            .shadow(color: Theme.Palette.ink.opacity(0.12), radius: 12, y: 4)
            .padding(.top, 10)
            .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Derived copy

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Working late"
        }
    }

    private var statusCopy: String {
        switch state {
        case .active:
            if (engine?.calibrationProgress ?? 1) < 1 { return "Getting your baseline…" }
            return engine?.postureState.kindCopy ?? ""
        case .paused: return "Paused — pop AirPods back in"
        case .idle:   return "Pop your AirPods in to begin"
        }
    }

    private var postureProgress: Double {
        guard isActive, let st = engine?.postureState else { return 0 }
        switch st {
        case .good: return 1.0
        case .warning: return 0.6
        case .poor: return 0.3
        }
    }

    private var walkProgress: Double {
        guard isActive else { return 0 }
        let interval = settings.baseWalkIntervalMin * 60
        guard interval > 0 else { return 0 }
        let secs = sessionManager?.activeSessionSeconds ?? 0
        return secs.truncatingRemainder(dividingBy: interval) / interval
    }

    // MARK: Actions

    private func logWater() {
        modelContext.insert(WaterEntry())
        try? modelContext.save()
    }

    private func formatTime(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }

    private func showBanner(_ message: String) {
        overlayMessage = message
        withAnimation(Theme.Motion.ui) { showOverlay = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(Theme.Motion.fade) { showOverlay = false }
        }
    }

    // MARK: Engine wiring

    private func setup() async {
        if settingsArray.isEmpty {
            modelContext.insert(UserSettings())
            try? modelContext.save()
        }

        let source: MotionSource
        #if targetEnvironment(simulator)
        let sim = SimulatedMotionSource()
        simSource = sim
        source = sim
        #else
        source = HeadphoneMotionSource()
        #endif

        let eng = PostureEngine(source: source)
        let sched = ReminderScheduler(settings: settings)
        let mgr = SessionManager(engine: eng, scheduler: sched)
        mgr.configure(modelContext: modelContext)

        engine = eng
        scheduler = sched
        sessionManager = mgr

        mgr.begin()  // single heartbeat drives connect/pause/clock/reminders

        #if !targetEnvironment(simulator)
        await NotificationModule.shared.requestPermission()
        #endif
    }
}

// Simulator-only: drive fake head pitch to exercise the whole app without a device.
struct DebugMotionPanel: View {
    @Bindable var source: SimulatedMotionSource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SIMULATOR DEBUG — fake AirPods")
                .font(Theme.Font.caption(11))
                .foregroundStyle(Theme.Palette.inkSoft)
            HStack {
                Text(String(format: "Pitch %.0f°", source.simulatedPitch))
                    .font(Theme.Font.caption())
                    .frame(width: 70, alignment: .leading)
                Slider(value: $source.simulatedPitch, in: -45 ... 45)
                    .tint(Theme.Palette.honey)
            }
            Toggle("AirPods connected", isOn: $source.available)
                .font(Theme.Font.caption())
                .tint(Theme.Palette.honey)
        }
        .padding(16)
        .background(Theme.Palette.honey.opacity(0.10), in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(Theme.Palette.honey.opacity(0.35)))
    }
}
