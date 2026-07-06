import Foundation
import Testing
@testable import Synthesis

// AppModel's popover-facing derived state. A seeded baseline with no motion
// samples yet means currentPitch = 0, so forwardAngle == baselinePitch —
// which lets liveBend be driven directly through UserSettings.
@MainActor
@Suite("AppModel — live bend")
struct AppModelLiveBendTests {
    private func makeModel(baseline: Double?) -> AppModel {
        let settings = UserSettings()
        settings.baselinePitch = baseline
        return AppModel(settings: settings)
    }

    @Test func zeroWithoutBaseline() {
        let model = makeModel(baseline: nil)
        #expect(model.liveBend == 0)
    }

    @Test func midSpanBendIsProportional() {
        // Balanced threshold 15 + slouchGap 6 + 4 headroom = 25° span.
        let model = makeModel(baseline: 12.5)
        #expect(abs(model.liveBend - 0.5) < 0.001)
    }

    @Test func backwardLeanClampsToZero() {
        let model = makeModel(baseline: -10)
        #expect(model.liveBend == 0)
    }

    @Test func deepSlouchClampsToOne() {
        let model = makeModel(baseline: 100)
        #expect(model.liveBend == 1)
    }
}

@MainActor
@Suite("AppModel — watered perk")
struct AppModelWateredPerkTests {
    private func makeModel() -> AppModel {
        let settings = UserSettings()
        settings.baselinePitch = 12.5  // liveBend 0.5 when perk inactive
        return AppModel(settings: settings)
    }

    @Test func inactiveByDefault() {
        let model = makeModel()
        #expect(!model.isWateredPerkActive)
    }

    @Test func loggingWaterStraightensThePlant() {
        let model = makeModel()
        model.noteWaterLogged()

        #expect(model.isWateredPerkActive)
        #expect(model.liveBend == 0)  // perk overrides posture bend
    }

    @Test func perkExpiresAfterTwoSeconds() async throws {
        let model = makeModel()
        model.noteWaterLogged()

        try await Task.sleep(for: .seconds(2.3))

        #expect(!model.isWateredPerkActive)
        #expect(model.wateredUntil == nil)  // expiry published so overlays dismiss
        #expect(abs(model.liveBend - 0.5) < 0.001)  // bend resumes
    }

    @Test func reloggingExtendsThePerk() async throws {
        let model = makeModel()
        model.noteWaterLogged()

        try await Task.sleep(for: .seconds(1.0))
        model.noteWaterLogged()  // second glass mid-perk

        // 2.3s after the FIRST log — the first expiry task must not have
        // killed the second log's window.
        try await Task.sleep(for: .seconds(1.3))
        #expect(model.isWateredPerkActive)

        try await Task.sleep(for: .seconds(1.0))
        #expect(!model.isWateredPerkActive)
    }
}
