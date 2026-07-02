import Foundation

// Ambient menu bar glyph state — ranges from "not tracking" to "sustained
// slouch". Deliberately coarser than the in-app posture word: the icon is
// glanceable, not a live readout, so it only changes on real transitions.
enum MenuBarState: Equatable {
    case idle, aligned, drift, wilt

    var symbolName: String {
        switch self {
        case .idle:    return "airpodspro"
        case .aligned: return "leaf.fill"
        case .drift:   return "leaf"
        case .wilt:    return "leaf.arrow.circlepath"
        }
    }
}

// Pure reducer: session/posture state + wall-clock time → MenuBarState.
// Kept separate from AppModel (and from PostureEngine's live ~20Hz updates)
// so the sustain-window logic is unit-testable without a live engine, and so
// AppModel can cheaply check "did the value actually change" before
// publishing — an @Observable write here would otherwise re-render the
// MenuBarExtra label on every posture sample.
struct MenuBarReducer {
    // Ambient glyph reacts faster than the loud escalation notification
    // (360s) — it's meant to be a quiet early signal, not a duplicate alert.
    private let sustainedSlouchSeconds: TimeInterval = 30

    private var slouchSince: Date?

    mutating func reduce(sessionState: SessionState, postureState: PostureState, now: Date) -> MenuBarState {
        guard sessionState == .active else {
            slouchSince = nil
            return .idle
        }

        guard postureState == .slouch else {
            slouchSince = nil
            return postureState == .aligned ? .aligned : .drift
        }

        let start = slouchSince ?? now
        slouchSince = start
        return now.timeIntervalSince(start) >= sustainedSlouchSeconds ? .wilt : .drift
    }
}
