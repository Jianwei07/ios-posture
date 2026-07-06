import Foundation
import Testing
@testable import Synthesis

// Drives ReminderScheduler through its injected fire/now seams — no real
// UNUserNotificationCenter, no real 6-minute waits.
private final class FakeClock {
    // Local noon: keeps interval tests clear of the default 22:00–08:00
    // quiet-hours window regardless of the machine's timezone.
    var current = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0,
                                        of: Date(timeIntervalSince1970: 1_000_000))!
    func now() -> Date { current }
    func advance(_ seconds: TimeInterval) { current = current.addingTimeInterval(seconds) }
    func setLocalTime(hour: Int, minute: Int = 0) {
        current = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: current)!
    }
}

private final class FiredLog {
    private(set) var events: [(ReminderType, String?)] = []
    func record(_ type: ReminderType, _ detail: String?) { events.append((type, detail)) }
    func count(_ type: ReminderType) -> Int { events.filter { $0.0 == type }.count }
    func clear() { events.removeAll() }
}

private final class ChimeLog {
    private(set) var count = 0
    func record() { count += 1 }
}

private func makeScheduler(settings: UserSettings = UserSettings(),
                            clock: FakeClock = FakeClock(),
                            log: FiredLog = FiredLog(),
                            chimes: ChimeLog = ChimeLog()) -> ReminderScheduler {
    ReminderScheduler(settings: settings,
                      fire: { log.record($0, $1) },
                      cancelAll: {},
                      now: clock.now,
                      playChime: { chimes.record() })
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

@Suite("ReminderScheduler — soft chime")
struct ReminderSchedulerChimeTests {
    private func quietSeams(_ scheduler: ReminderScheduler) {
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }
    }

    @Test func firesAfterSustainedDrift() {
        let clock = FakeClock()
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(121)  // > 2 min default
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 1)
    }

    @Test func noFireBeforeSustainedThreshold() {
        let clock = FakeClock()
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(60)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 0)
    }

    @Test func sittingUpResetsSustainClock() {
        let clock = FakeClock()
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(90)
        scheduler.tick(postureState: .aligned, sessionSeconds: 2)  // recovers
        clock.advance(90)
        scheduler.tick(postureState: .drift, sessionSeconds: 3)  // fresh stretch

        #expect(chimes.count == 0)
    }

    @Test func cooldownSuppressesRepeatChime() {
        let clock = FakeClock()
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(121)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)
        #expect(chimes.count == 1)

        // Sustained again past the nudge threshold, but inside the 5-minute
        // cooldown — must stay silent.
        clock.advance(121)
        scheduler.tick(postureState: .drift, sessionSeconds: 3)
        #expect(chimes.count == 1)
    }

    @Test func masterToggleOffSilences() {
        let clock = FakeClock()
        let chimes = ChimeLog()
        let settings = UserSettings()
        settings.softAlertsEnabled = false
        let scheduler = makeScheduler(settings: settings, clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(1000)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 0)
    }

    @Test func chimeToggleOffSilences() {
        let clock = FakeClock()
        let chimes = ChimeLog()
        let settings = UserSettings()
        settings.chimeOnSustainedDrift = false
        let scheduler = makeScheduler(settings: settings, clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(1000)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 0)
    }

    @Test func masterToggleOffAlsoSuppressesBanner() {
        let clock = FakeClock()
        let log = FiredLog()
        let settings = UserSettings()
        settings.softAlertsEnabled = false  // escalateLongSlouches stays true
        let scheduler = makeScheduler(settings: settings, clock: clock, log: log)
        quietSeams(scheduler)

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(400)
        scheduler.tick(postureState: .slouch, sessionSeconds: 2)

        #expect(log.count(.posture) == 0)
    }
}

@Suite("ReminderScheduler — quiet hours")
struct ReminderSchedulerQuietHoursTests {
    private func quietSeams(_ scheduler: ReminderScheduler) {
        scheduler.lastWaterLogAt = { nil }
        scheduler.waterProgress = { (0, 0) }
    }

    @Test func nightSuppressesChimeAndBanner() {
        let clock = FakeClock()
        clock.setLocalTime(hour: 23)  // inside default 22:00–08:00 window
        let log = FiredLog()
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, log: log, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .slouch, sessionSeconds: 1)
        clock.advance(400)  // past both chime (120s) and banner (360s) sustains
        scheduler.tick(postureState: .slouch, sessionSeconds: 2)

        #expect(chimes.count == 0)
        #expect(log.count(.posture) == 0)
    }

    @Test func overnightWrapCoversEarlyMorning() {
        let clock = FakeClock()
        clock.setLocalTime(hour: 7)  // before the 08:00 end, wrapped side
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(121)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 0)
    }

    @Test func daytimeIsNotQuiet() {
        let clock = FakeClock()
        clock.setLocalTime(hour: 9)  // just past the window's end
        let chimes = ChimeLog()
        let scheduler = makeScheduler(clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(121)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 1)
    }

    @Test func disabledQuietHoursLetNightAlertsThrough() {
        let clock = FakeClock()
        clock.setLocalTime(hour: 23)
        let settings = UserSettings()
        settings.quietHoursEnabled = false
        let chimes = ChimeLog()
        let scheduler = makeScheduler(settings: settings, clock: clock, chimes: chimes)
        quietSeams(scheduler)

        scheduler.tick(postureState: .drift, sessionSeconds: 1)
        clock.advance(121)
        scheduler.tick(postureState: .drift, sessionSeconds: 2)

        #expect(chimes.count == 1)
    }

    @Test func nightSuppressesWaterAndWalk() {
        let clock = FakeClock()
        clock.setLocalTime(hour: 23)
        let log = FiredLog()
        let settings = UserSettings()
        let scheduler = makeScheduler(settings: settings, clock: clock, log: log)
        quietSeams(scheduler)

        scheduler.tick(postureState: .aligned,
                       sessionSeconds: max(settings.baseWaterIntervalMin, settings.baseWalkIntervalMin) * 60)

        #expect(log.count(.water) == 0)
        #expect(log.count(.walk) == 0)
    }
}
