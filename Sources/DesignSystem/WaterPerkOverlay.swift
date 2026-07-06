import SwiftUI

// Teal droplets + sparkle flashed over the plant mascot right after a water
// log (design board mood 4: "hydrate → it perks up"). Purely decorative.
struct WaterPerkOverlay: View {
    private let teal = Color(hex: 0x4F8A7B)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            drop(ctx, at: CGPoint(x: w * 0.76, y: size.height * 0.18), h: w * 0.14)
            drop(ctx, at: CGPoint(x: w * 0.20, y: size.height * 0.30), h: w * 0.10)
            let r = w * 0.025
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.64 - r, y: size.height * 0.42 - r,
                                            width: r * 2, height: r * 2)),
                     with: .color(teal))
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // Teardrop: pointed top swelling into a round belly.
    private func drop(_ ctx: GraphicsContext, at top: CGPoint, h: CGFloat) {
        let belly = h * 0.42
        var path = Path()
        path.move(to: top)
        path.addCurve(to: CGPoint(x: top.x, y: top.y + h),
                      control1: CGPoint(x: top.x - belly * 1.4, y: top.y + h * 0.55),
                      control2: CGPoint(x: top.x - belly, y: top.y + h))
        path.addCurve(to: top,
                      control1: CGPoint(x: top.x + belly, y: top.y + h),
                      control2: CGPoint(x: top.x + belly * 1.4, y: top.y + h * 0.55))
        path.closeSubpath()
        ctx.fill(path, with: .color(teal))
    }
}
