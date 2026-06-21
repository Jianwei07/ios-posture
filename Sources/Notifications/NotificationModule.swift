import UserNotifications
import Foundation

enum ReminderType {
    case posture, water

    var title: String {
        switch self {
        case .posture: return "Check your posture"
        case .water:   return "Time to hydrate"
        }
    }

    var body: String {
        switch self {
        case .posture: return "You've been slouching for a while. Sit up straight."
        case .water:   return "Stay hydrated — grab a glass of water."
        }
    }

    var identifier: String { "posture.\(self)" }
}

final class NotificationModule {
    static let shared = NotificationModule()
    static let overlayNotification = Notification.Name("posture.overlay")

    private init() {}

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func fire(_ type: ReminderType) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(type.identifier).\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil  // fire immediately
        )

        UNUserNotificationCenter.current().add(request)

        // Also post for in-app overlay
        NotificationCenter.default.post(
            name: Self.overlayNotification,
            object: type
        )
    }

    func schedule(_ type: ReminderType, inSeconds seconds: Double) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: type.identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancel(_ type: ReminderType) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [type.identifier])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
