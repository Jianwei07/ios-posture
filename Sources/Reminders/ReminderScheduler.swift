import Foundation
import Observation

// Reminder scheduler.
// - Posture alert: event-driven (sustained poor posture)
// - Water + Walk: simple interval reminders, settings-driven (no HealthKit)
@Observable
final class ReminderScheduler {
    private let notifications = NotificationModule.shared
    private let settings: UserSettings

    // Posture alert timing (constants — not user-configurable)
    private let alertSustainedSeconds: Double = 30
    private let alertCooldownMin: Double = 5

    private var poorPostureStartTime: Date?
    private var lastPostureAlertTime: Date?

    private var lastWaterReminderAt: Double = 0
    private var lastWalkReminderAt: Double = 0

    init(settings: UserSettings) {
        self.settings = settings
    }

    func tick(postureState: PostureState, sessionSeconds: Double) {
        checkPostureAlert(postureState)
        checkInterval(&lastWaterReminderAt, intervalMin: settings.baseWaterIntervalMin,
                      sessionSeconds: sessionSeconds, type: .water)
        checkInterval(&lastWalkReminderAt, intervalMin: settings.baseWalkIntervalMin,
                      sessionSeconds: sessionSeconds, type: .walk)
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
        if state == .poor {
            if poorPostureStartTime == nil { poorPostureStartTime = now }
        } else {
            poorPostureStartTime = nil
        }

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
}
