import SwiftUI

// Standard surface card: Theme.Palette.surface fill + faint ink stroke.
// Matches the pattern copy-pasted across NowView/TrendsView/SettingsView.
extension View {
    func card(radius: CGFloat = Theme.Radius.chip) -> some View {
        self
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.Palette.ink.opacity(0.06)))
    }
}
