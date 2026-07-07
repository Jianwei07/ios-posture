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
