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

    init(settings: UserSettings) {
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
        let mgr = SessionManager(engine: eng, scheduler: sched, stepReader: reader)

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
        session.begin()
        Task {
            await NotificationModule.shared.requestPermission()
            await stepReader.requestPermission()
            stepReader.refresh()
            await sunlightScheduler.scheduleForToday()
        }
    }

    // Push the latest settings into the live engine/scheduler.
    func applySettings(_ settings: UserSettings) {
        engine.classifier.threshold = settings.sensitivity.degrees
    }

    // True when AirPods Pro motion is available (drives the Disconnected gate).
    var isConnected: Bool { engine.isHeadphoneMotionAvailable }

    // Live bend for the Home spine mirror.
    var liveBend: Double {
        guard engine.neutralPitch != nil else { return 0 }
        let span = (engine.classifier.threshold + engine.classifier.slouchGap) + 4
        return max(0, min(1, engine.forwardAngle / span))
    }
}
