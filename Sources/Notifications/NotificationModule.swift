import UserNotifications
import SwiftData
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

    // Posture is the only priority alert (sound + system banner even when
    // active); water/walk/sunlight are soft — silent, banner-only nudges.
    var isPriority: Bool { self == .posture }
}

final class NotificationModule: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationModule()
    static let overlayNotification = Notification.Name("posture.overlay")
    static let waterCategoryId = "synthesis.water"
    static let waterLogActionId = "synthesis.water.log"

    private var container: ModelContainer?

    private override init() { super.init() }

    // Wires the shared ModelContainer so the water "Log 250 ml" notification
    // action can write a WaterEntry, and installs this as the notification
    // center delegate. Must be called at app-launch time — if it's deferred
    // (e.g. behind a lazy .task), action taps that (re)launch the app from a
    // terminated state get dropped before the delegate is ever set.
    func configure(container: ModelContainer) {
        self.container = container
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let logAction = UNNotificationAction(identifier: Self.waterLogActionId, title: "Log 250 ml")
        let waterCategory = UNNotificationCategory(
            identifier: Self.waterCategoryId, actions: [logAction], intentIdentifiers: []
        )
        center.setNotificationCategories([waterCategory])
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func fire(_ type: ReminderType, detail: String? = nil) {
        let content = content(for: type, detail: detail)

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
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: type.identifier,
            content: content(for: type, detail: nil),
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

    // Shared content builder — tiers priority (posture: sound + active) vs
    // soft (water/walk/sunlight: silent + passive) notifications.
    func content(for type: ReminderType, detail: String?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = detail.map { "\(type.body) \($0)" } ?? type.body
        if type.isPriority {
            content.sound = .default
            content.interruptionLevel = .active
        } else {
            content.sound = nil
            content.interruptionLevel = .passive
        }
        if type == .water {
            content.categoryIdentifier = Self.waterCategoryId
        }
        return content
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let isPriority = notification.request.content.interruptionLevel == .active
        return isPriority ? [.banner, .sound] : [.banner]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == Self.waterLogActionId,
              let container else { return }
        await MainActor.run {
            let context = container.mainContext
            context.insert(WaterEntry())
            try? context.save()
        }
    }
}
