import SwiftUI

// NOTE: This file renders the POSTURE PLANT mascot (a potted desk plant whose
// stem + leaves stand tall when posture is good and wilt forward as you slouch).
// Type names kept (`StickmanView` / `StickmanPose` / `StickmanMapping`) so the
// call site (TodayView) and the Xcode project file stay untouched.

// MARK: - Pose model (API unchanged)

struct StickmanPose {
    var slouch: Double = 0      // 0 = upright/healthy … 1 = wilted
    var resting: Bool = false   // AirPods out / idle

    static let upright = StickmanPose(slouch: 0)
    static let napping = StickmanPose(slouch: 0.30, resting: true)
}

enum StickmanMapping {
    static func slouch(pitch: Double, neutral: Double?) -> Double {
        let n = neutral ?? 0
        let delta = pitch - n
        let down    = max(0, -delta)
        let forward = max(0, delta)
        return min(1, (down + forward * 0.5) / 28)
    }
}

// MARK: - View: potted plant drawn with filled SwiftUI paths

struct StickmanView: View {
    var slouch: Double
    var resting: Bool = false
    var ink: Color = Theme.Palette.ink   // kept for API compat; unused by plant

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sway = false

    private var s: Double { max(0, min(1, slouch)) }

    var body: some View {
        Canvas { ctx, size in draw(&ctx, size: size) }
            .aspectRatio(0.82, contentMode: .fit)
            // Gentle sway pivoting at the pot base — plants sway, not pulse.
            .rotationEffect(.degrees(reduceMotion ? 0 : (sway ? 1.6 : -1.6)),
                            anchor: .init(x: 0.5, y: 0.95))
            .animation(Theme.Motion.mascot, value: slouch)
            .animation(Theme.Motion.fade, value: resting)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                    sway = true
                }
            }
    }

    // MARK: Drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        func P(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: x * size.width, y: y * size.height)
        }

        // Extra droop + dimming when resting (AirPods out).
        let droop = s + (resting ? 0.18 : 0)
        let foliageAlpha = resting ? 0.55 : 1.0

        // Foliage warms sage → clay as the plant wilts. Eased so it stays green
        // through small slouch, then shifts as it gets bad.
        let warmT = min(1, pow(droop, 1.4))
        let foliage = lerpColor(0x7C9A6B, 0xC96F53, warmT).opacity(foliageAlpha)

        // ---- Pot ----
        let potTop = 0.66, potBottom = 0.92
        let topL = P(0.30, potTop), topR = P(0.70, potTop)
        let botL = P(0.37, potBottom), botR = P(0.63, potBottom)
        var pot = Path()
        pot.move(to: topL)
        pot.addLine(to: topR)
        pot.addLine(to: CGPoint(x: botR.x, y: botR.y - 8))
        pot.addQuadCurve(to: CGPoint(x: botR.x - 10, y: botR.y),
                         control: CGPoint(x: botR.x, y: botR.y))
        pot.addLine(to: CGPoint(x: botL.x + 10, y: botL.y))
        pot.addQuadCurve(to: CGPoint(x: botL.x, y: botL.y - 8),
                         control: CGPoint(x: botL.x, y: botL.y))
        pot.closeSubpath()
        ctx.fill(pot, with: .color(Color(hex: 0xC98A5B)))

        // Pot rim — slightly wider, a shade deeper.
        let rimY = potTop
        let rim = Path(roundedRect: CGRect(x: P(0.275, rimY).x, y: P(0, rimY).y - size.height * 0.005,
                                           width: size.width * 0.45, height: size.height * 0.05),
                       cornerRadius: size.width * 0.025)
        ctx.fill(rim, with: .color(Color(hex: 0xB87A4C)))

        // Soil — thin dark ellipse just inside the rim.
        let soil = Path(ellipseIn: CGRect(x: P(0.32, rimY).x, y: P(0, rimY).y,
                                          width: size.width * 0.36, height: size.height * 0.022))
        ctx.fill(soil, with: .color(Color(hex: 0x4A3B2E)))

        // ---- Stem (tapered filled path) ----
        let base = P(0.5, 0.665)
        // Tip leans forward (+x) and drops (+y) as droop grows. Capped so a
        // fully wilted plant droops over the soil, not clear off the pot.
        let lean = min(1.0, droop)
        let tip = P(0.5 + 0.16 * lean, 0.30 + 0.22 * lean)
        let ctrl = P(0.5 + 0.085 * lean, 0.47)
        let baseHalf = size.width * 0.022   // stem thickness at soil
        let stem = taperedStem(base: base, control: ctrl, tip: tip, baseHalf: baseHalf)
        ctx.fill(stem, with: .color(foliage))

        // ---- Leaves ----
        // Angles in radians; 0 = pointing right. Up is negative (y down).
        // As droop grows, leaves sag (angles rotate downward).
        func leaf(at t: Double, length: Double, width: Double, baseAngle: Double, side: Double) {
            let anchor = pointOnStem(base: base, control: ctrl, tip: tip, t: t)
            let sag = droop * 0.9 * .pi / 4      // up to ~40° sag
            let ang = baseAngle * side + sag
            let dir = CGVector(dx: cos(ang), dy: sin(ang))
            let len = length * size.width
            let leafTip = CGPoint(x: anchor.x + dir.dx * len, y: anchor.y + dir.dy * len)
            let p = leafShape(from: anchor, to: leafTip, width: width * size.width)
            ctx.fill(p, with: .color(foliage))
            // subtle vein highlight
            var vein = Path()
            vein.move(to: anchor)
            vein.addLine(to: leafTip)
            ctx.stroke(vein, with: .color(.black.opacity(0.06)),
                       style: StrokeStyle(lineWidth: max(1, size.width * 0.004), lineCap: .round))
        }

        // crown leaf (largest) + two side leaves
        leaf(at: 0.62, length: 0.20, width: 0.085, baseAngle: .pi / 2.6, side: -1)  // left
        leaf(at: 0.78, length: 0.22, width: 0.090, baseAngle: .pi / 2.6, side:  1)  // right
        leaf(at: 0.98, length: 0.19, width: 0.080, baseAngle: .pi / 2.0, side: -1)  // crown
    }
}

// MARK: - Geometry helpers

// Point along the quadratic stem curve at parameter t (0 = base, 1 = tip).
private func pointOnStem(base: CGPoint, control: CGPoint, tip: CGPoint, t: Double) -> CGPoint {
    let u = 1 - t
    let x = u * u * base.x + 2 * u * t * control.x + t * t * tip.x
    let y = u * u * base.y + 2 * u * t * control.y + t * t * tip.y
    return CGPoint(x: x, y: y)
}

// Build a tapered stem: walk the curve, offset left/right by a shrinking half-width.
private func taperedStem(base: CGPoint, control: CGPoint, tip: CGPoint, baseHalf: CGFloat) -> Path {
    let steps = 14
    var left: [CGPoint] = [], right: [CGPoint] = []
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let pt = pointOnStem(base: base, control: control, tip: tip, t: t)
        // tangent (derivative of quadratic bezier)
        let u = 1 - t
        let dx = 2 * u * (control.x - base.x) + 2 * t * (tip.x - control.x)
        let dy = 2 * u * (control.y - base.y) + 2 * t * (tip.y - control.y)
        let len = max(0.0001, hypot(dx, dy))
        let nx = -dy / len, ny = dx / len
        let half = baseHalf * CGFloat(1 - 0.85 * t)   // taper toward tip
        left.append(CGPoint(x: pt.x + nx * half, y: pt.y + ny * half))
        right.append(CGPoint(x: pt.x - nx * half, y: pt.y - ny * half))
    }
    var p = Path()
    p.move(to: left.first!)
    left.dropFirst().forEach { p.addLine(to: $0) }
    right.reversed().forEach { p.addLine(to: $0) }
    p.closeSubpath()
    return p
}

// An almond/teardrop leaf from `from` to `to`, bowed on both sides.
private func leafShape(from: CGPoint, to: CGPoint, width: CGFloat) -> Path {
    let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
    let dx = to.x - from.x, dy = to.y - from.y
    let len = max(0.0001, hypot(dx, dy))
    let nx = -dy / len, ny = dx / len
    let c1 = CGPoint(x: mid.x + nx * width, y: mid.y + ny * width)
    let c2 = CGPoint(x: mid.x - nx * width, y: mid.y - ny * width)
    var p = Path()
    p.move(to: from)
    p.addQuadCurve(to: to, control: c1)
    p.addQuadCurve(to: from, control: c2)
    p.closeSubpath()
    return p
}

// MARK: - Color helper

// Linear interpolate between two hex colors in sRGB.
private func lerpColor(_ a: UInt32, _ b: UInt32, _ t: Double) -> Color {
    func ch(_ hex: UInt32, _ shift: UInt32) -> Double { Double((hex >> shift) & 0xFF) }
    let t = max(0, min(1, t))
    let r = ch(a, 16) + (ch(b, 16) - ch(a, 16)) * t
    let g = ch(a, 8)  + (ch(b, 8)  - ch(a, 8))  * t
    let bl = ch(a, 0) + (ch(b, 0)  - ch(a, 0))  * t
    return Color(.sRGB, red: r / 255, green: g / 255, blue: bl / 255, opacity: 1)
}
