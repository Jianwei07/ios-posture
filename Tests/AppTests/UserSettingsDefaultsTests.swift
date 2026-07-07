import Foundation
import Testing
@testable import Synthesis

// Guards the SwiftData lightweight-migration contract: new non-optional
// @Model fields ship with inline defaults, and reset() restores the same
// values. A drift here corrupts what existing local stores migrate to.
@Suite("UserSettings — alert defaults")
struct UserSettingsDefaultsTests {
    @Test func alertLadderDefaults() {
        let settings = UserSettings()

        #expect(settings.softAlertsEnabled)
        #expect(settings.chimeOnSustainedDrift)
        #expect(settings.nudgeAfterDriftSeconds == 3.0)
        #expect(settings.chimeVolume == 0.5)
        #expect(settings.nudgeAfterDriftMin == 2.0)
        #expect(settings.quietHoursEnabled)
        #expect(settings.quietHoursStartMinutes == 1320)  // 22:00
        #expect(settings.quietHoursEndMinutes == 480)     // 08:00
    }

    @Test func resetRestoresAlertDefaults() {
        let settings = UserSettings()
        settings.softAlertsEnabled = false
        settings.chimeOnSustainedDrift = false
        settings.nudgeAfterDriftSeconds = 9
        settings.chimeVolume = 0.9
        settings.nudgeAfterDriftMin = 9
        settings.quietHoursEnabled = false
        settings.quietHoursStartMinutes = 0
        settings.quietHoursEndMinutes = 1

        settings.reset()

        #expect(settings.softAlertsEnabled)
        #expect(settings.chimeOnSustainedDrift)
        #expect(settings.nudgeAfterDriftSeconds == 3.0)
        #expect(settings.chimeVolume == 0.5)
        #expect(settings.nudgeAfterDriftMin == 2.0)
        #expect(settings.quietHoursEnabled)
        #expect(settings.quietHoursStartMinutes == 1320)
        #expect(settings.quietHoursEndMinutes == 480)
    }
}

@Suite("AppPersistence")
struct AppPersistenceTests {
    @Test func storeURLIsAppSpecific() {
        let appSupport = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let storeURL = AppPersistence.storeURL(
            applicationSupportDirectory: appSupport,
            bundleIdentifier: "com.jayden77.posture.mac"
        )

        #expect(storeURL.lastPathComponent == "Synthesis.store")
        #expect(storeURL.deletingLastPathComponent().lastPathComponent == "com.jayden77.posture.mac")
        #expect(storeURL != appSupport.appendingPathComponent("default.store"))
    }

    @MainActor
    @Test func containerIgnoresGenericDefaultStore() throws {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let genericDefaultStore = tempRoot.appendingPathComponent("default.store")
        try Data("not a synthesis store".utf8).write(to: genericDefaultStore)

        let container = try AppPersistence.makeContainer(
            applicationSupportDirectory: tempRoot,
            bundleIdentifier: "com.jayden77.posture.mac"
        )
        let settings = try AppPersistence.loadOrCreateSettings(in: container.mainContext)

        #expect(!settings.hasOnboarded)
        #expect(FileManager.default.fileExists(atPath: genericDefaultStore.path))
        #expect(FileManager.default.fileExists(atPath: AppPersistence.storeURL(
            applicationSupportDirectory: tempRoot,
            bundleIdentifier: "com.jayden77.posture.mac"
        ).path))
    }
}
