import Foundation
import Testing
@testable import Synthesis

// Drives ReminderScheduler through its injected fire/now seams — no real
// UNUserNotificationCenter, no real 6-minute waits.
private final class FakeClock {
    var current = Date(timeIntervalSince1970: 1_000_000)
    func now() -> Date { current }
    func advance(_ seconds: TimeInterval) { current = current.addingTimeInterval(seconds) }
}

private final class FiredLog {
    private(set) var events: [(ReminderType, String?)] = []
    func record(_ type: ReminderType, _ detail: String?) { events.append((type, detail)) }
    func count(_ type: ReminderType) -> Int { events.filter { $0.0 == type }.count }
    func clear() { events.removeAll() }
}

private func makeScheduler(settings: UserSettings = UserSettings(),
                            clock: FakeClock = FakeClock(),
                            log: FiredLog = FiredLog()) -> ReminderScheduler {
    ReminderScheduler(settings: settings, fire: { log.record($0, $1) }, cancelAll: {}, now: clock.now)
}

@Suite("ReminderScheduler — water")
struct ReminderSchedulerWaterTests {
    @Test func firesAtIntervalWithNoRecentLog() {
        let log = FiredLog()
        let scheduler = makeScheduler(log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 2000) }

        scheduler.tick(postureState: .aligned, sessionSeconds: 30 * 60)

        #expect(log.count(.water) == 1)
    }

    @Test func defersWhenRecentlyLogged() {
        let clock = FakeClock()
        let log = FiredLog()
        let scheduler = makeScheduler(clock: clock, log: log)
        scheduler.lastWaterLogAt = { clock.now() }  // just logged
        scheduler.waterProgress = { (250, 2000) }

        scheduler.tick(postureState: .aligned, sessionSeconds: 30 * 60)

        #expect(log.count(.water) == 0)
    }

    @Test func firesNextIntervalAfterDeferring() {
        let clock = FakeClock()
        let log = FiredLog()
        let settings = UserSettings()
        let scheduler = makeScheduler(settings: settings, clock: clock, log: log)
        let loggedAt = clock.now()  // fixed log timestamp, not a live re-read
        scheduler.lastWaterLogAt = { loggedAt }
        scheduler.waterProgress = { (250, 2000) }

        // First boundary: deferred (just logged).
        scheduler.tick(postureState: .aligned, sessionSeconds: 30 * 60)
        #expect(log.count(.water) == 0)

        // Time passes well beyond the water interval — the logged timestamp
        // is now stale, so the next boundary should fire.
        clock.advance(settings.baseWaterIntervalMin * 60 + 60)
        scheduler.tick(postureState: .aligned, sessionSeconds: 60 * 60)

        #expect(log.count(.water) == 1)
    }

    @Test func suppressedWhenTargetMet() {
        let log = FiredLog()
        let scheduler = makeScheduler(log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (2000, 2000) }

        scheduler.tick(postureState: .aligned, sessionSeconds: 30 * 60)

        #expect(log.count(.water) == 0)
    }
}

@Suite("ReminderScheduler — walk")
struct ReminderSchedulerWalkTests {
    @Test func firesAtInterval() {
        let log = FiredLog()
        let settings = UserSettings()
        let scheduler = makeScheduler(settings: settings, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        scheduler.tick(postureState: .aligned, sessionSeconds: settings.baseWalkIntervalMin * 60)

        #expect(log.count(.walk) == 1)
    }

    @Test func noteBreakTakenResetsTheInterval() {
        let log = FiredLog()
        let settings = UserSettings()
        let scheduler = makeScheduler(settings: settings, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        let intervalSec = settings.baseWalkIntervalMin * 60

        // A presence break at session-second 1000 pushes the next walk fire
        // out to 1000 + interval — the original (unreset) boundary at
        // `intervalSec` should now be a no-op.
        scheduler.noteBreakTaken(sessionSeconds: 1000)
        scheduler.tick(postureState: .aligned, sessionSeconds: intervalSec)
        #expect(log.count(.walk) == 0)

        scheduler.tick(postureState: .aligned, sessionSeconds: 1000 + intervalSec)
        #expect(log.count(.walk) == 1)
    }
}

@Suite("ReminderScheduler — posture escalation")
struct ReminderSchedulerPostureTests {
    @Test func noFireBeforeSustainedThreshold() {
        let clock = FakeClock()
        let log = FiredLog()
        let scheduler = makeScheduler(clock: clock, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(300)  // < 360s sustained
        scheduler.tick(postureState: .slouch, sessionSeconds: 2)

        #expect(log.count(.posture) == 0)
    }

    @Test func firesAfterSustainedThreshold() {
        let clock = FakeClock()
        let log = FiredLog()
        let scheduler = makeScheduler(clock: clock, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(361)
        scheduler.tick(postureState: .slouch, sessionSeconds: 2)

        #expect(log.count(.posture) == 1)
    }

    @Test func cooldownSuppressesRepeatFire() {
        let clock = FakeClock()
        let log = FiredLog()
        let scheduler = makeScheduler(clock: clock, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(361)
        scheduler.tick(postureState: .slouch, sessionSeconds: 2)
        #expect(log.count(.posture) == 1)

        // Still slouching, well past the sustain threshold again, but within
        // the 5-minute cooldown — must not fire a second time.
        clock.advance(361)
        scheduler.tick(postureState: .slouch, sessionSeconds: 3)
        #expect(log.count(.posture) == 1)
    }

    @Test func interruptionResetsSustainClock() {
        let clock = FakeClock()
        let log = FiredLog()
        let scheduler = makeScheduler(clock: clock, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(300)
        scheduler.tick(postureState: .aligned, sessionSeconds: 2)  // interrupts the slouch
        clock.advance(300)
        scheduler.tick(postureState: .slouch, sessionSeconds: 3)  // starts a fresh sustain window

        #expect(log.count(.posture) == 0)
    }

    @Test func escalationDisabledSuppressesEntirely() {
        let clock = FakeClock()
        let log = FiredLog()
        let settings = UserSettings()
        settings.escalateLongSlouches = false
        let scheduler = makeScheduler(settings: settings, clock: clock, log: log)
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(1000)
        scheduler.tick(postureState: .slouch, sessionSeconds: 2)

        #expect(log.count(.posture) == 0)
    }
}
