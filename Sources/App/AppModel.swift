import SwiftData
import SwiftUI

// Owns the posture stack (engine + session heartbeat + scheduler) and shares it
// across onboarding and all three tabs. Built once, when settings are available.
@Observable
final class AppModel {
    let engine: PostureEngine
    let session: SessionManager
    let scheduler: ReminderScheduler
    let stepReader: StepReader
    let sunlightScheduler: SunlightScheduler
    #if targetEnvironment(simulator)
    @ObservationIgnored var simSource: SimulatedMotionSource?
    #endif

    private var started = false
    private let settings: UserSettings

    private(set) var menuBarState: MenuBarState = .idle
    private var menuBarReducer = MenuBarReducer()

    // Was a computed pass-through to `engine.isHeadphoneMotionConnected`
    // (a plain, non-observable Bool) — the connection chip only looked live
    // because the old per-sample engine writes constantly re-rendered it.
    // Now a transition-gated stored property, updated on the 1Hz heartbeat.
    private(set) var isConnected: Bool = false

    init(settings: UserSettings) {
        self.settings = settings
        let source: MotionSource
        #if targetEnvironment(simulator)
        let sim = SimulatedMotionSource()
        source = sim
        #else
        source = HeadphoneMotionSource()
        #endif

        let eng = PostureEngine(source: source)
        eng.classifier.threshold = settings.sensitivity.degrees
        eng.seedBaseline(settings.baselinePitch)

        let sched = ReminderScheduler(settings: settings)
        let reader = StepReader()
        let sunScheduler = SunlightScheduler(settings: settings)
        let mgr = SessionManager(engine: eng, scheduler: sched)

        self.engine = eng
        self.scheduler = sched
        self.session = mgr
        self.stepReader = reader
        self.sunlightScheduler = sunScheduler
        #if targetEnvironment(simulator)
        self.simSource = sim
        #endif
        self.isConnected = eng.isHeadphoneMotionConnected
    }

    // Begin the single 1Hz heartbeat (connect/pause/clock/record/remind).
    func start(modelContext: ModelContext) {
        guard !started else { return }
        started = true
        session.configure(modelContext: modelContext)
        session.onHeartbeat = { [weak self] sessionState, postureState in
            self?.updateMenuBarState(sessionState: sessionState, postureState: postureState)
        }
        session.begin()
        wireWaterSeams(modelContext: modelContext)
        Task {
            await NotificationModule.shared.requestPermission()
            await stepReader.requestPermission()
            stepReader.refresh()
            await sunlightScheduler.scheduleForToday()
        }
    }

    // Lets the water reminder skip when recently logged / target already met.
    // Reads straight from SwiftData so a log via chip tap, notification
    // action, or any future path is picked up the same way.
    private func wireWaterSeams(modelContext: ModelContext) {
        scheduler.lastWaterLogAt = {
            let descriptor = FetchDescriptor<WaterEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            return (try? modelContext.fetch(descriptor))?.first?.timestamp
        }
        scheduler.waterProgress = { [weak self] in
            guard let self else { return (0, 0) }
            let start = Calendar.current.startOfDay(for: .now)
            let descriptor = FetchDescriptor<WaterEntry>()
            let entries = (try? modelContext.fetch(descriptor)) ?? []
            let todayMl = entries.filter { $0.timestamp >= start }.reduce(0) { $0 + $1.volumeMl }
            return (todayMl, self.settings.dailyWaterTargetMl)
        }
    }

    // Push the latest settings into the live engine/scheduler.
    func applySettings(_ settings: UserSettings) {
        engine.classifier.threshold = settings.sensitivity.degrees
    }

    // Runs on every heartbeat (1Hz timer + immediate on connect/disconnect
    // push, since `SessionManager.begin()` wires `onAvailabilityChanged` to
    // call `evaluate()` too) — but only assigns `menuBarState`/`isConnected`
    // on a real transition, so @Observable only re-renders their readers
    // when something actually changed.
    private func updateMenuBarState(sessionState: SessionState, postureState: PostureState) {
        let newState = menuBarReducer.reduce(sessionState: sessionState, postureState: postureState, now: .now)
        if newState != menuBarState { menuBarState = newState }

        let connected = engine.isHeadphoneMotionConnected
        if connected != isConnected { isConnected = connected }

        // Popover hero stat ("−11° · 2 min"): how long the current
        // forward-leaning stretch has lasted. Stored only on the transition
        // edge so @Observable readers don't re-render every heartbeat.
        if sessionState == .active && postureState != .aligned {
            if nonAlignedSince == nil { nonAlignedSince = .now }
        } else if nonAlignedSince != nil {
            nonAlignedSince = nil
        }
    }

    // Start of the current drift/slouch stretch (nil while aligned or idle).
    private(set) var nonAlignedSince: Date?

    var nonAlignedMinutes: Int {
        guard let since = nonAlignedSince else { return 0 }
        return Int(Date.now.timeIntervalSince(since) / 60)
    }

    // Live bend for the Home plant mascot.
    var liveBend: Double {
        guard engine.neutralPitch != nil else { return 0 }
        let span = (engine.classifier.threshold + engine.classifier.slouchGap) + 4
        return max(0, min(1, engine.forwardAngle / span))
    }
}
