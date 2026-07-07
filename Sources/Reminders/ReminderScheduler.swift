import Foundation
import Observation

// Reminder scheduler.
// - Posture alert: event-driven (sustained poor posture), priority tier.
// - Soft chime: quiet Level-2 alert after sustained drift-or-worse.
// - Water: interval reminders, deferred if recently logged or target already met.
// - Walk: fires at interval; reset by a presence break (AirPods out ≥5min).
// Quiet hours hold everything (chime + all notifications) until morning.
@Observable
final class ReminderScheduler {
    private let settings: UserSettings
    private let fire: (ReminderType, String?) -> Void
    private let cancelAll: () -> Void
    private let now: () -> Date
    private let playChime: (Double) -> Void

    // Escalation timing: only after ~6 min sustained slouch, then cool down.
    private let alertSustainedSeconds: Double = 360
    private let alertCooldownMin: Double = 5

    private var poorPostureStartTime: Date?
    private var lastPostureAlertTime: Date?

    private var driftStartTime: Date?
    private var didChimeForCurrentDrift = false

    private var lastWaterReminderAt: Double = 0
    private var lastWalkReminderAt: Double = 0

    // Injected by AppModel: newest logged WaterEntry timestamp, and today's
    // water progress (for softened, target-aware reminder copy). Wall-clock
    // based — logging during a paused/AirPods-out break still counts.
    var lastWaterLogAt: (() -> Date?)?
    var waterProgress: (() -> (todayMl: Double, targetMl: Double))?

    init(settings: UserSettings,
         fire: @escaping (ReminderType, String?) -> Void = { NotificationModule.shared.fire($0, detail: $1) },
         cancelAll: @escaping () -> Void = { NotificationModule.shared.cancelAll() },
         now: @escaping () -> Date = Date.init,
         playChime: @escaping (Double) -> Void = { NotificationModule.shared.playChime(volume: $0) }) {
        self.settings = settings
        self.fire = fire
        self.cancelAll = cancelAll
        self.now = now
        self.playChime = playChime
    }

    func tick(postureState: PostureState, sessionSeconds: Double) {
        checkPostureAlert(postureState)
        checkChime(postureState)
        checkWater(sessionSeconds: sessionSeconds)
        checkWalk(sessionSeconds: sessionSeconds)
    }

    // Menu-bar popover walk card: minutes until the next walk nudge.
    func minutesUntilWalk(sessionSeconds: Double) -> Int {
        let remaining = settings.baseWalkIntervalMin * 60 - (sessionSeconds - lastWalkReminderAt)
        return max(0, Int((remaining / 60).rounded(.up)))
    }

    // Called when the session resumes after an AirPods-out break of ≥5min —
    // treated as "the user got up and walked", resetting the walk interval.
    func noteBreakTaken(sessionSeconds: Double) {
        lastWalkReminderAt = sessionSeconds
    }

    func reset() {
        poorPostureStartTime = nil
        driftStartTime = nil
        didChimeForCurrentDrift = false
        lastWaterReminderAt = 0
        lastWalkReminderAt = 0
        cancelAll()
    }

    // MARK: Private

    private func checkPostureAlert(_ state: PostureState) {
        let currentTime = now()
        if state == .slouch {
            if poorPostureStartTime == nil { poorPostureStartTime = currentTime }
        } else {
            poorPostureStartTime = nil
        }

        // Loud banner only when soft alerts are on AND the user opted in to
        // escalation (Level 3 of the alert ladder).
        guard settings.softAlertsEnabled, settings.escalateLongSlouches else { return }

        guard let start = poorPostureStartTime,
              currentTime.timeIntervalSince(start) >= alertSustainedSeconds else { return }

        if let last = lastPostureAlertTime,
           currentTime.timeIntervalSince(last) < alertCooldownMin * 60 { return }

        guard !isQuietNow() else { return }

        lastPostureAlertTime = currentTime
        poorPostureStartTime = nil
        fire(.posture, nil)
    }

    // Level-2 soft alert: one quiet chime after a sustained forward lean
    // (drift or slouch), re-armed by sitting up. Dismissable by posture alone.
    private func checkChime(_ state: PostureState) {
        let currentTime = now()
        guard state != .aligned else {
            driftStartTime = nil
            didChimeForCurrentDrift = false
            return
        }
        if driftStartTime == nil { driftStartTime = currentTime }

        guard settings.softAlertsEnabled, settings.chimeOnSustainedDrift else { return }
        guard !didChimeForCurrentDrift else { return }

        guard let start = driftStartTime,
              currentTime.timeIntervalSince(start) >= settings.nudgeAfterDriftSeconds else { return }

        guard !isQuietNow() else { return }

        didChimeForCurrentDrift = true
        playChime(settings.chimeVolume)
    }

    // Quiet hours: minutes-of-day window in local time, wrapping overnight
    // (default 22:00 → 08:00). All chimes and notifications hold.
    private func isQuietNow() -> Bool {
        guard settings.quietHoursEnabled else { return false }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now())
        let minute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let start = settings.quietHoursStartMinutes
        let end = settings.quietHoursEndMinutes
        guard start != end else { return false }
        return start < end
            ? (minute >= start && minute < end)
            : (minute >= start || minute < end)
    }

    private func checkWater(sessionSeconds: Double) {
        let intervalSec = settings.baseWaterIntervalMin * 60
        guard sessionSeconds - lastWaterReminderAt >= intervalSec else { return }
        lastWaterReminderAt = sessionSeconds

        // Recently logged (wall clock — a glass during a break still counts)?
        if let lastLog = lastWaterLogAt?(), now().timeIntervalSince(lastLog) < intervalSec {
            return
        }

        if let progress = waterProgress?(), progress.targetMl > 0, progress.todayMl >= progress.targetMl {
            return
        }

        guard !isQuietNow() else { return }

        var detail: String?
        if let progress = waterProgress?(), progress.targetMl > 0 {
            let today = String(format: "%.1fL", progress.todayMl / 1000)
            let target = String(format: "%.1fL", progress.targetMl / 1000)
            detail = "\(today) of \(target) today"
        }
        fire(.water, detail)
    }

    // Walk nudge: fire at interval boundary. noteBreakTaken() resets the
    // interval when a real break (AirPods-out ≥5min) is detected.
    private func checkWalk(sessionSeconds: Double) {
        guard sessionSeconds - lastWalkReminderAt >= settings.baseWalkIntervalMin * 60 else { return }
        lastWalkReminderAt = sessionSeconds
        guard !isQuietNow() else { return }
        fire(.walk, nil)
    }
}
