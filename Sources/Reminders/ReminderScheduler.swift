import Foundation
import Observation

// Reminder scheduler.
// - Posture alert: event-driven (sustained poor posture)
// - Water: interval reminders, settings-driven
// - Walk: fires at interval if step count is behind pace target
@Observable
final class ReminderScheduler {
    private let notifications = NotificationModule.shared
    private let settings: UserSettings

    // Escalation timing: only after ~6 min sustained slouch, then cool down.
    private let alertSustainedSeconds: Double = 360
    private let alertCooldownMin: Double = 5

    private var poorPostureStartTime: Date?
    private var lastPostureAlertTime: Date?

    private var lastWaterReminderAt: Double = 0
    private var lastWalkReminderAt: Double = 0

    // Injected step count for pace check. 0 on Simulator (falls back to interval mode).
    var currentStepCount: Int = 0

    init(settings: UserSettings) {
        self.settings = settings
    }

    func tick(postureState: PostureState, sessionSeconds: Double) {
        checkPostureAlert(postureState)
        checkInterval(&lastWaterReminderAt, intervalMin: settings.baseWaterIntervalMin,
                      sessionSeconds: sessionSeconds, type: .water)
        checkWalk(sessionSeconds: sessionSeconds)
    }

    func reset() {
        poorPostureStartTime = nil
        lastWaterReminderAt = 0
        lastWalkReminderAt = 0
        notifications.cancelAll()
    }

    // MARK: Private

    private func checkPostureAlert(_ state: PostureState) {
        let now = Date()
        if state == .slouch {
            if poorPostureStartTime == nil { poorPostureStartTime = now }
        } else {
            poorPostureStartTime = nil
        }

        // Loud banner only when the user opted in to escalation.
        guard settings.escalateLongSlouches else { return }

        guard let start = poorPostureStartTime,
              now.timeIntervalSince(start) >= alertSustainedSeconds else { return }

        if let last = lastPostureAlertTime,
           now.timeIntervalSince(last) < alertCooldownMin * 60 { return }

        lastPostureAlertTime = now
        poorPostureStartTime = nil
        notifications.fire(.posture)
    }

    private func checkInterval(_ lastAt: inout Double, intervalMin: Double,
                               sessionSeconds: Double, type: ReminderType) {
        if sessionSeconds - lastAt >= intervalMin * 60 {
            lastAt = sessionSeconds
            notifications.fire(type)
        }
    }

    // Walk nudge: fire at interval boundary. On Simulator (steps=0), always fire.
    // On device, skip if already past the pace target for this time of day.
    private func checkWalk(sessionSeconds: Double) {
        guard sessionSeconds - lastWalkReminderAt >= settings.baseWalkIntervalMin * 60 else { return }
        lastWalkReminderAt = sessionSeconds

        if currentStepCount == 0 { notifications.fire(.walk); return }

        // ponytail: simple pace check — proportional to hours elapsed. Good enough for a nudge.
        let hoursElapsed = max(1, Calendar.current.component(.hour, from: .now))
        let paceTarget = settings.dailyStepTarget * hoursElapsed / 16  // 16 active hours
        if currentStepCount < paceTarget { notifications.fire(.walk) }
    }
}
