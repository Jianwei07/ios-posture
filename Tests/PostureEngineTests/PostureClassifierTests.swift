import Testing
@testable import Synthesis

@Suite("PostureClassifier")
struct PostureClassifierTests {
    // Balanced: drift past 15°, slouch past 15 + 6 = 21°.
    let classifier = PostureClassifier(threshold: 15.0, slouchGap: 6.0)
    let neutral = 0.0

    @Test func aligned() {
        #expect(classifier.classify(filteredPitch: 0, neutralPitch: neutral) == .aligned)
        #expect(classifier.classify(filteredPitch: -10, neutralPitch: neutral) == .aligned)
        #expect(classifier.classify(filteredPitch: -14, neutralPitch: neutral) == .aligned)
    }

    @Test func drift() {
        #expect(classifier.classify(filteredPitch: -15, neutralPitch: neutral) == .drift)
        #expect(classifier.classify(filteredPitch: -20, neutralPitch: neutral) == .drift)
    }

    @Test func slouch() {
        #expect(classifier.classify(filteredPitch: -21, neutralPitch: neutral) == .slouch)
        #expect(classifier.classify(filteredPitch: -40, neutralPitch: neutral) == .slouch)
    }

    @Test func headBackStaysAligned() {
        // Leaning back (pitch above baseline) is not a slouch.
        #expect(classifier.classify(filteredPitch: 20, neutralPitch: neutral) == .aligned)
    }

    @Test func noNeutralReturnsAligned() {
        #expect(classifier.classify(filteredPitch: -30, neutralPitch: nil) == .aligned)
    }

    @Test func sensitivityShiftsThreshold() {
        let strict = PostureClassifier(threshold: 8.0, slouchGap: 6.0)
        #expect(strict.classify(filteredPitch: -10, neutralPitch: neutral) == .drift)
        let relaxed = PostureClassifier(threshold: 22.0, slouchGap: 6.0)
        #expect(relaxed.classify(filteredPitch: -10, neutralPitch: neutral) == .aligned)
    }
}
