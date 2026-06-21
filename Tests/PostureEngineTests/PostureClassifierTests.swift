import Testing
@testable import Posture

@Suite("PostureClassifier")
struct PostureClassifierTests {
    let classifier = PostureClassifier(
        poorPitchThreshold: -20.0,
        warningPitchThreshold: -10.0,
        forwardHeadThreshold: 15.0
    )
    let neutral = 0.0

    @Test func goodPosture() {
        #expect(classifier.classify(filteredPitch: 0, neutralPitch: neutral) == .good)
        #expect(classifier.classify(filteredPitch: -5, neutralPitch: neutral) == .good)
        #expect(classifier.classify(filteredPitch: 9, neutralPitch: neutral) == .good)
    }

    @Test func warningPosture() {
        #expect(classifier.classify(filteredPitch: -11, neutralPitch: neutral) == .warning)
        #expect(classifier.classify(filteredPitch: -19, neutralPitch: neutral) == .warning)
    }

    @Test func poorPostureHeadDown() {
        #expect(classifier.classify(filteredPitch: -21, neutralPitch: neutral) == .poor)
        #expect(classifier.classify(filteredPitch: -40, neutralPitch: neutral) == .poor)
    }

    @Test func poorPostureForwardHead() {
        // +16° above neutral = forward head
        #expect(classifier.classify(filteredPitch: 16, neutralPitch: neutral) == .poor)
    }

    @Test func noNeutralReturnsGood() {
        #expect(classifier.classify(filteredPitch: -30, neutralPitch: nil) == .good)
    }
}
