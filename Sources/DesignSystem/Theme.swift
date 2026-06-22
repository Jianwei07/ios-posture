import SwiftUI

// Sage design tokens. See design.md.
enum Theme {

    // MARK: Color (Sage — light)
    enum Palette {
        static let bg       = Color(hex: 0xF4F2EC)  // app background
        static let surface  = Color(hex: 0xFBFAF6)  // cards / raised
        static let ink      = Color(hex: 0x2A2A26)  // primary text + icon stroke
        static let inkSoft  = Color(hex: 0x6F685E)  // secondary text
        static let inkFaint = Color(hex: 0x9A9183)  // tertiary / captions
        static let accent   = Color(hex: 0x4F8A7B)  // single accent (teal)

        static let aligned  = Color(hex: 0x5F9A78)  // sage green
        static let drift    = Color(hex: 0xCC8A5A)  // clay / ochre
        static let slouch   = Color(hex: 0xB05A38)  // terracotta
    }

    // MARK: Typography (SF Pro / system)
    enum Font {
        static func hero(_ size: CGFloat = 40) -> SwiftUI.Font {
            .system(size: size, weight: .semibold).monospacedDigit()
        }
        static func number(_ size: CGFloat = 28) -> SwiftUI.Font {
            .system(size: size, weight: .semibold).monospacedDigit()
        }
        static func title(_ size: CGFloat = 20) -> SwiftUI.Font {
            .system(size: size, weight: .semibold)
        }
        static func body(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .regular)
        }
        static func caption(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium)
        }
        static func label(_ size: CGFloat = 11) -> SwiftUI.Font {
            .system(size: size, weight: .bold)
        }
    }

    // MARK: Motion
    enum Motion {
        static let ui    = Animation.spring(duration: 0.35, bounce: 0.15)
        static let pose  = Animation.spring(duration: 0.50, bounce: 0.20)
        static let fade  = Animation.easeOut(duration: 0.22)
        static let press: CGFloat = 0.97
    }

    enum Radius {
        static let card: CGFloat = 18
        static let chip: CGFloat = 14
        static let pill: CGFloat = 999
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Pressable button style (scale 0.97 on press)

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.Motion.press : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension View {
    func pressable() -> some View { buttonStyle(PressableStyle()) }
}
