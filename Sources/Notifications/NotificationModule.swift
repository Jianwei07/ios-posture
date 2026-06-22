import UserNotifications
import Foundation

enum ReminderType {
    case posture, water, walk, sunlight

    var title: String {
        switch self {
        case .posture:  return "Heads up"
        case .water:    return "Time to hydrate"
        case .walk:     return "Time to move"
        case .sunlight: return "Catch some sunlight"
        }
    }

    var body: String {
        switch self {
        case .posture: return "Leaning forward a while now. Sit tall?"
        case .water:   return "Stay hydrated — grab a glass of water."
        case .walk:    return "Stand up, stretch, take a short walk."
        case .sunlight: return "Catch some sunlight — step near a window for a few minutes."
        }
    }

    var identifier: String { "posture.\(self)" }
}

final class NotificationModule {
    static let shared = NotificationModule()
    static let overlayNotification = Notification.Name("posture.overlay")

    private init() {}

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
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
