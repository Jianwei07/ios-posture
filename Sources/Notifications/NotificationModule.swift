import UserNotifications
import SwiftData
import Foundation
import AVFoundation

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
    private let chimePlayer = ChimePlayer()

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

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // Level-2 soft alert: a quiet chime through the default audio output
    // (the AirPods, when worn). Deliberately not a notification — no banner,
    // no notification-center entry, dismissed by simply sitting up.
    func playChime(volume: Double = 0.5) {
        chimePlayer.play(volume: volume)
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

final class ChimePlayer {
    private lazy var chimeData = Self.makeChimeData()
    private var player: AVAudioPlayer?

    func play(volume: Double) {
        let clampedVolume = Float(min(1, max(0, volume)))
        guard clampedVolume > 0 else { return }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif

        do {
            if player == nil {
                player = try AVAudioPlayer(data: chimeData)
            }

            guard let player else { return }
            if player.isPlaying { player.stop() }
            player.currentTime = 0
            player.volume = clampedVolume
            player.prepareToPlay()
            player.play()
        } catch {
            player = nil
        }
    }

    private static func makeChimeData() -> Data {
        let sampleRate = 44_100
        let duration = 0.32
        let sampleCount = Int(Double(sampleRate) * duration)
        var sampleData = Data()
        sampleData.reserveCapacity(sampleCount * 2)

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let attack = min(1, time / 0.02)
            let decay = exp(-5.5 * time / duration)
            let envelope = attack * decay
            let tone = sin(2 * Double.pi * 880 * time)
                + 0.55 * sin(2 * Double.pi * 1320 * time)
            let sample = Int16(max(-1, min(1, tone * 0.22 * envelope)) * Double(Int16.max))
            appendLittleEndian(sample, to: &sampleData)
        }

        var data = Data()
        appendASCII("RIFF", to: &data)
        appendLittleEndian(UInt32(36 + sampleData.count), to: &data)
        appendASCII("WAVE", to: &data)
        appendASCII("fmt ", to: &data)
        appendLittleEndian(UInt32(16), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt32(sampleRate), to: &data)
        appendLittleEndian(UInt32(sampleRate * 2), to: &data)
        appendLittleEndian(UInt16(2), to: &data)
        appendLittleEndian(UInt16(16), to: &data)
        appendASCII("data", to: &data)
        appendLittleEndian(UInt32(sampleData.count), to: &data)
        data.append(sampleData)
        return data
    }

    private static func appendASCII(_ string: String, to data: inout Data) {
        data.append(contentsOf: string.utf8)
    }

    private static func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var value = value.littleEndian
        withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
    }
}
