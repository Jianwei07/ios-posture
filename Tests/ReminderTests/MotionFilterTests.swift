import Testing
@testable import Synthesis

@Suite("MotionFilter")
struct MotionFilterTests {
    @Test func convergesOnConstant() {
        var filter = MotionFilter(alpha: 0.15)
        var value = 0.0
        for _ in 0..<100 { value = filter.filter(-20.0) }
        #expect(abs(value - (-20.0)) < 0.01)
    }

    @Test func resetClearsState() {
        var filter = MotionFilter(alpha: 0.15)
        _ = filter.filter(-20.0)
        filter.reset()
        let first = filter.filter(0.0)
        #expect(first == 0.0)
    }

    @Test func smoothsSpike() {
        var filter = MotionFilter(alpha: 0.15)
        var stable = 0.0
        for _ in 0..<50 { stable = filter.filter(0.0) }
        let afterSpike = filter.filter(100.0)
        #expect(afterSpike < 20.0)  // spike attenuated
    }
}
