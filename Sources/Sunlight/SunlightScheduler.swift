import Foundation
import UserNotifications

// Schedules local notifications at optimal sunlight times (mid-morning + mid-afternoon).
// Recomputes daily. Respects UserSettings.sunlightEnabled.
@Observable
final class SunlightScheduler {
    private let notifications = NotificationModule.shared
    private let calculator = SolarCalculator()
    private let settings: UserSettings

    var nextNudge: Date?

    init(settings: UserSettings) {
        self.settings = settings
    }

    func scheduleForToday() async {
        guard settings.sunlightEnabled else { return }
        let windows = await calculator.compute()
        nextNudge = windows.morningNudge
        scheduleIfFuture(windows.morningNudge, id: "sunlight.morning")
        scheduleIfFuture(windows.afternoonNudge, id: "sunlight.afternoon")
    }

    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["sunlight.morning", "sunlight.afternoon"])
    }

    private func scheduleIfFuture(_ date: Date, id: String) {
        let interval = date.timeIntervalSinceNow
        guard interval > 60 else { return }  // skip if already past or <1min away

        let content = UNMutableNotificationContent()
        content.title = ReminderType.sunlight.title
        content.body = ReminderType.sunlight.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
