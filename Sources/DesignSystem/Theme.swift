import SwiftUI

// Warm-minimal design tokens. See design.md.
enum Theme {

    // MARK: Color
    enum Palette {
        static let canvas  = Color(hex: 0xF4EEE2)  // warm cream background
        static let surface = Color(hex: 0xFBF7EF)  // cards / raised
        static let ink     = Color(hex: 0x2E2A25)  // charcoal text + stickman
        static let inkSoft = Color(hex: 0x6B6457)  // secondary text
        static let honey   = Color(hex: 0xE0A33E)  // single accent

        static let good    = Color(hex: 0x7C9A6B)  // warm sage
        static let warn    = Color(hex: 0xD8973C)  // ochre
        static let poor    = Color(hex: 0xC96F53)  // clay
    }

    // MARK: Typography (SF Pro Rounded)
    enum Font {
        static func hero(_ size: CGFloat = 40) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func number(_ size: CGFloat = 28) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
        }
        static func title(_ size: CGFloat = 20) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func body(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .rounded)
        }
        static func caption(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .rounded)
        }
    }

    // MARK: Motion
    enum Motion {
        static let ui     = Animation.spring(duration: 0.35, bounce: 0.15)
        static let mascot = Animation.spring(duration: 0.50, bounce: 0.20)
        static let fade   = Animation.easeOut(duration: 0.22)
        static let press: CGFloat = 0.97
    }

    enum Radius {
        static let card: CGFloat = 22
        static let pill: CGFloat = 999
    }
}

// MARK: - Posture state colors

extension PostureState {
    var warmColor: Color {
        switch self {
        case .good:    return Theme.Palette.good
        case .warning: return Theme.Palette.warn
        case .poor:    return Theme.Palette.poor
        }
    }

    // Kind, human status copy — no shouting numbers.
    var kindCopy: String {
        switch self {
        case .good:    return "Sitting tall"
        case .warning: return "Ease back a little"
        case .poor:    return "Lift your head up"
        }
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
