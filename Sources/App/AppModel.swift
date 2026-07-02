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

    // Only assigns on a real transition — the reducer runs every heartbeat
    // second, but @Observable should only re-render the menu bar label when
    // the glyph actually needs to change.
    private func updateMenuBarState(sessionState: SessionState, postureState: PostureState) {
        let newState = menuBarReducer.reduce(sessionState: sessionState, postureState: postureState, now: .now)
        if newState != menuBarState { menuBarState = newState }
    }

    // Short status line for the MenuBarExtra dropdown.
    var menuBarStatusLine: String {
        switch menuBarState {
        case .idle:    return isConnected ? "Not tracking" : "AirPods not connected"
        case .aligned: return "Aligned · \(Int(session.activeSessionSeconds / 60)) min upright"
        case .drift:   return "Drifting — sit tall"
        case .wilt:    return "Slouching a while now"
        }
    }

    // True when compatible AirPods motion is connected/streaming (drives the Disconnected gate).
    var isConnected: Bool { engine.isHeadphoneMotionConnected }

    // Live bend for the Home spine mirror.
    var liveBend: Double {
        guard engine.neutralPitch != nil else { return 0 }
        let span = (engine.classifier.threshold + engine.classifier.slouchGap) + 4
        return max(0, min(1, engine.forwardAngle / span))
    }
}
