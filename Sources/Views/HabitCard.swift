import SwiftUI

// A progress ring drawn in the warm palette.
struct HabitRing: View {
    var progress: Double          // 0…1
    var color: Color
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.Motion.ui, value: progress)
        }
    }
}

// A reusable habit module: ring + metric + label. Tappable.
// Adding a new lifestyle habit later = one more of these.
struct HabitCard: View {
    var title: String
    var value: String
    var caption: String
    var progress: Double
    var color: Color
    var locked: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.Palette.inkSoft)
                    Spacer()
                    HabitRing(progress: locked ? 0 : progress, color: color)
                        .frame(width: 26, height: 26)
                }

                Spacer(minLength: 0)

                Text(locked ? "Soon" : value)
                    .font(Theme.Font.number(24))
                    .foregroundStyle(locked ? Theme.Palette.inkSoft : Theme.Palette.ink)
                Text(caption)
                    .font(Theme.Font.caption(11))
                    .foregroundStyle(Theme.Palette.inkSoft)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
            .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.ink.opacity(0.06))
            )
            .opacity(locked ? 0.6 : 1)
        }
        .pressable()
        .disabled(locked || action == nil)
    }
}
