import Testing
@testable import Synthesis

private final class FakeMotionSource: MotionSource {
    var isAvailable: Bool = true
    var onAvailabilityChanged: ((Bool) -> Void)?
    private var handler: ((Double) -> Void)?

    func start(onSample: @escaping (Double) -> Void) { handler = onSample }
    func stop() { handler = nil }
    func emit(_ pitch: Double) { handler?(pitch) }
}

@Suite("PostureEngine Calibration")
struct PostureEngineCalibrationTests {
    @Test func recalibrateThenStableSetsBaseline() {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.recalibrate()
        engine.start()
        for _ in 0..<100 { source.emit(-10.0) }
        #expect(engine.neutralPitch != nil)
        #expect(abs(engine.neutralPitch! - (-10.0)) < 1.0)
        #expect(engine.calibrationSpread < 1.0)
        engine.stop()
    }

    @Test func unstableCalibrationRejectsBaseline() {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.recalibrate()
        engine.start()
        for i in 0..<100 { source.emit(i / 10 % 2 == 0 ? -5.0 : -25.0) }
        #expect(engine.neutralPitch == nil)
        #expect(engine.calibrationSpread > 4.0)
        engine.stop()
    }

    @Test func startWithoutRecalibrateDoesNotCalibrate() {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.seedBaseline(nil)
        engine.start()
        for _ in 0..<200 { source.emit(-10.0) }
        #expect(engine.neutralPitch == nil)
        engine.stop()
    }

    @Test func seededBaselineSkipsCalibration() {
        let source = FakeMotionSource()
        let engine = PostureEngine(source: source)
        engine.seedBaseline(-12.0)
        engine.start()
        for _ in 0..<50 { source.emit(-30.0) }
        #expect(engine.neutralPitch == -12.0)
        engine.stop()
    }
}
