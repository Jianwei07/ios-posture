import Foundation
import Observation

// Reminder scheduler.
// - Posture alert: event-driven (sustained poor posture)
// - Water: interval-based, settings-driven (Phase 1: no adaptation, no HealthKit)
@Observable
final class ReminderScheduler {
    private let notifications = NotificationModule.shared
    private let settings: UserSettings

    // Posture alert state
    private var poorPostureStartTime: Date?
    private var lastPostureAlertTime: Date?

    // Session elapsed seconds (from SessionManager.activeSessionSeconds)
    private var lastWaterReminderAt: Double = 0

    init(settings: UserSettings) {
        self.settings = settings
    }

    // Called every second by SessionManager when state == .active
    func tick(postureState: PostureState, sessionSeconds: Double) {
        checkPostureAlert(postureState)
        checkWaterReminder(sessionSeconds: sessionSeconds)
    }

    func reset() {
        poorPostureStartTime = nil
        lastWaterReminderAt = 0
        notifications.cancelAll()
    }

    // MARK: Private

    private func checkPostureAlert(_ state: PostureState) {
        let now = Date()

        if state == .poor {
            if poorPostureStartTime == nil {
                poorPostureStartTime = now
            }
        } else {
            poorPostureStartTime = nil
        }

        guard let alertStart = poorPostureStartTime else { return }
        let sustained = now.timeIntervalSince(alertStart)

        guard sustained >= settings.postureAlertSustainedSeconds else { return }

        // Cooldown check
        if let last = lastPostureAlertTime,
           now.timeIntervalSince(last) < settings.postureAlertCooldownMin * 60 { return }

        lastPostureAlertTime = now
        poorPostureStartTime = nil
        notifications.fire(.posture)
    }

    private func checkWaterReminder(sessionSeconds: Double) {
        let interval = settings.baseWaterIntervalMin * 60  // pure interval

        if sessionSeconds - lastWaterReminderAt >= interval {
            lastWaterReminderAt = sessionSeconds
            notifications.fire(.water)
        }
    }
}
