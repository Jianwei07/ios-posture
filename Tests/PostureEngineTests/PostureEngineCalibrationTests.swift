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

// PostureEngine.process(pitch:) now hops to DispatchQueue.main.async before
// mutating calibration/classification state (single-owner fix for the
// motion-queue/main-queue race). DispatchQueue.main is serial FIFO, so
// awaiting one more block enqueued after the emit loop guarantees every
// prior emit's state mutation has already landed — deterministic, no sleep.
private func drainMain() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}

@Suite("PostureEngine Calibration")
struct PostureEngineCalibrationTests {
    @Test func recalibrateThenStableSetsBaseline() async {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.recalibrate()
        engine.start()
        for _ in 0..<100 { source.emit(-10.0) }
        await drainMain()
        #expect(engine.neutralPitch != nil)
        #expect(abs(engine.neutralPitch! - (-10.0)) < 1.0)
        #expect(engine.calibrationSpread < 1.0)
        engine.stop()
    }

    @Test func unstableCalibrationRejectsBaseline() async {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.recalibrate()
        engine.start()
        for i in 0..<100 { source.emit(i / 10 % 2 == 0 ? -5.0 : -25.0) }
        await drainMain()
        #expect(engine.neutralPitch == nil)
        #expect(engine.calibrationSpread > 4.0)
        engine.stop()
    }

    @Test func startWithoutRecalibrateDoesNotCalibrate() async {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.seedBaseline(nil)
        engine.start()
        for _ in 0..<200 { source.emit(-10.0) }
        await drainMain()
        #expect(engine.neutralPitch == nil)
        engine.stop()
    }

    @Test func seededBaselineSkipsCalibration() async {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.seedBaseline(-12.0)
        engine.start()
        for _ in 0..<50 { source.emit(-30.0) }
        await drainMain()
        #expect(engine.neutralPitch == -12.0)
        engine.stop()
    }

    @Test func cancelCalibrationStopsLateSamples() async {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.recalibrate()
        engine.start()
        for _ in 0..<50 { source.emit(-10.0) }
        engine.cancelCalibration()
        for _ in 0..<100 { source.emit(-10.0) }
        await drainMain()
        #expect(engine.neutralPitch == nil)
        engine.stop()
    }

    @Test func sessionDoesNotStartFromCapabilityOnly() {
        let source = FakeMotionSource()
        source.isAvailable = true
        source.isConnected = false
        let engine = PostureEngine(source: source)
        let session = SessionManager(engine: engine, scheduler: ReminderScheduler(settings: UserSettings()))

        session.begin()
        source.onAvailabilityChanged?(true)

        #expect(session.state == .idle)
        #expect(source.startCount == 0)
    }
}
