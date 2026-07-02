import Foundation
import Testing
@testable import Synthesis

@Suite("MenuBarReducer")
struct MenuBarReducerTests {
    @Test func slouchUnderThresholdStaysDrift() {
        var reducer = MenuBarReducer()
        let base = Date(timeIntervalSince1970: 0)

        let first = reducer.reduce(sessionState: .active, postureState: .slouch, now: base)
        #expect(first == .drift)

        let stillUnder = reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(29))
        #expect(stillUnder == .drift)
    }

    @Test func sustainedSlouchBecomesWilt() {
        var reducer = MenuBarReducer()
        let base = Date(timeIntervalSince1970: 0)

        _ = reducer.reduce(sessionState: .active, postureState: .slouch, now: base)
        let sustained = reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(30))

        #expect(sustained == .wilt)
    }

    @Test func recoveryIsImmediate() {
        var reducer = MenuBarReducer()
        let base = Date(timeIntervalSince1970: 0)

        _ = reducer.reduce(sessionState: .active, postureState: .slouch, now: base)
        _ = reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(31))
        #expect(reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(31)) == .wilt)

        let recovered = reducer.reduce(sessionState: .active, postureState: .aligned, now: base.addingTimeInterval(32))
        #expect(recovered == .aligned)
    }

    @Test func pausedSessionForcesIdle() {
        var reducer = MenuBarReducer()
        let base = Date(timeIntervalSince1970: 0)

        _ = reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(31))
        let paused = reducer.reduce(sessionState: .paused, postureState: .slouch, now: base.addingTimeInterval(32))

        #expect(paused == .idle)
    }

    @Test func slouchClockResetsAfterInterruption() {
        var reducer = MenuBarReducer()
        let base = Date(timeIntervalSince1970: 0)

        _ = reducer.reduce(sessionState: .active, postureState: .slouch, now: base)
        _ = reducer.reduce(sessionState: .active, postureState: .aligned, now: base.addingTimeInterval(15))  // interrupts
        // A fresh slouch 20s later is only 20s into its own window — should
        // NOT have carried over the earlier partial sustain.
        let after = reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(35))
        #expect(after == .drift)
    }

    @Test func noRedundantTransitionsOverSustainedSlouch() {
        var reducer = MenuBarReducer()
        let base = Date(timeIntervalSince1970: 0)
        var changeCount = 0
        var last: MenuBarState?

        for i in 0..<40 {
            let state = reducer.reduce(sessionState: .active, postureState: .slouch, now: base.addingTimeInterval(Double(i)))
            if state != last { changeCount += 1; last = state }
        }

        // drift (t=0) → wilt (t=30): exactly two distinct states across 40 ticks.
        #expect(changeCount == 2)
    }
}
