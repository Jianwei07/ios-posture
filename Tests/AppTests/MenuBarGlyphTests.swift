#if os(macOS)
import AppKit
import Testing
@testable import Synthesis

@Suite("MenuBarGlyph")
struct MenuBarGlyphTests {
    private let allStates: [MenuBarState] = [.idle, .aligned, .drift, .wilt]

    @Test func standardMenuBarSize() {
        for state in allStates {
            let image = MenuBarGlyph.image(for: state)
            #expect(image.size == NSSize(width: 18, height: 18))
        }
    }

    @Test func neverTemplateRendered() {
        // Template rendering would flatten the colored state dot to monochrome.
        for state in allStates {
            #expect(!MenuBarGlyph.image(for: state).isTemplate)
        }
    }

    @Test func accessibilityLabelsAreDistinctPerState() {
        let labels = allStates.map { MenuBarGlyph.image(for: $0).accessibilityDescription }
        for label in labels {
            #expect(label?.isEmpty == false)
        }
        #expect(Set(labels.compactMap { $0 }).count == allStates.count)
    }

    @Test func stateDotChangesPixels() {
        // Idle has no dot; each tracked state draws its own dot color —
        // all four renders must differ.
        let renders = allStates.map { MenuBarGlyph.image(for: $0).tiffRepresentation }
        for render in renders {
            #expect(render != nil)
        }
        #expect(Set(renders.compactMap { $0 }).count == allStates.count)
    }
}
#endif
