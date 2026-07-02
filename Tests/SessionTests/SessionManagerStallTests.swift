import Dispatch
import Testing
@testable import Synthesis

private final class FakeMotionSource: MotionSource {
    var isAvailable: Bool = true
    var isConnected: Bool = true
    var onAvailabilityChanged: ((Bool) -> Void)?
    private var handler: ((Double) -> Void)?
    private(set) var startCount = 0

    func startMonitoring() {}
    func start(onSample: @escaping (Double) -> Void) {
        startCount += 1
        handler = onSample
    }
    func stop() { handler = nil }
    func emit(_ pitch: Double) { handler?(pitch) }
}

// Same trick as PostureEngineCalibrationTests: PostureEngine.process(pitch:)
// hops through DispatchQueue.main.async before mutating state, so a sample
// emitted synchronously needs one more main-queue round trip to land.
private func drainMain() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}

// Regression coverage for the PR review finding: a connected-but-stalled
// AirPods stream (isConnected stays true, samples just stop) must not let
// SessionManager loop paused->active and count stale posture data during
// isReceiving()'s post-start() spin-up grace.
@Suite("SessionManager — connected but stalled")
struct SessionManagerStallTests {
    @Test func resumingWithoutARealSampleDoesNotCountATick() async {
        let source = FakeMotionSource()
        source.isAvailable = true
        source.isConnected = true
        let engine = PostureEngine(source: source)
        engine.seedBaseline(-10.0)  // calibrated — tickActive()'s other guard is satisfied
        let session = SessionManager(engine: engine, scheduler: ReminderScheduler(settings: UserSettings()))

        session.begin()
        // Drives evaluate() the same way the CMHeadphoneMotionManager delegate
        // would — .idle -> startSession() -> .active. No sample emitted yet.
        source.onAvailabilityChanged?(true)
        #expect(session.state == .active)
        #expect(session.activeSessionSeconds == 0)

        // Next heartbeat: isReceiving() reports true purely off the spin-up
        // grace (lastSampleAt is still nil). Before the fix, tickActive() ran
        // anyway and counted a second of stale currentPitch/postureState.
        source.onAvailabilityChanged?(true)
        #expect(session.state == .active)
        #expect(session.activeSessionSeconds == 0)

        // Once a genuine sample lands, ticking resumes normally.
        source.emit(-10.0)
        await drainMain()
        source.onAvailabilityChanged?(true)
        #expect(session.activeSessionSeconds == 1)
    }
}
