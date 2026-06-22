import SwiftUI

// Monstera — stem + split leaves droop forward.
// bend=0: upright stem, leaves pointing up. bend=1: stem curves, leaves droop forward.
struct Monstera: Plant {
    var bend: Double
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let b = max(0, min(1, bend))
            let w = size.width, h = size.height
            let cx = w / 2

            // Pot
            let potTop = h * 0.72, potBot = h * 0.95
            var pot = Path()
            pot.move(to: CGPoint(x: cx - w * 0.18, y: potTop))
            pot.addLine(to: CGPoint(x: cx + w * 0.18, y: potTop))
            pot.addLine(to: CGPoint(x: cx + w * 0.13, y: potBot))
            pot.addLine(to: CGPoint(x: cx - w * 0.13, y: potBot))
            pot.closeSubpath()
            ctx.fill(pot, with: .color(Color(hex: 0xC98A5B)))

            // Stem
            let baseY = potTop
            let tipX = cx + w * 0.14 * b
            let tipY = h * 0.28 + h * 0.08 * b
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: baseY))
            stem.addQuadCurve(to: CGPoint(x: tipX, y: tipY),
                              control: CGPoint(x: cx + w * 0.06 * b, y: h * 0.5))
            ctx.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.05, lineCap: .round))

            // Leaves — 3 almond shapes along stem, droop with bend
            func leaf(_ t: Double, len: Double, baseAngle: Double, side: Double) {
                // point along quadratic stem
                let u = 1 - t
                let px = u * u * cx + 2 * u * t * (cx + w * 0.06 * b) + t * t * tipX
                let py = u * u * baseY + 2 * u * t * (h * 0.5) + t * t * tipY
                let sag = b * 0.6
                let ang = baseAngle * side + sag
                let dx = cos(ang), dy = sin(ang)
                let leafLen = len * w
                let ex = px + dx * leafLen, ey = py + dy * leafLen
                // almond: two quad curves
                let mx = (px + ex) / 2, my = (py + ey) / 2
                let nx = -dy, ny = dx
                let halfW = leafLen * 0.35
                var p = Path()
                p.move(to: CGPoint(x: px, y: py))
                p.addQuadCurve(to: CGPoint(x: ex, y: ey),
                               control: CGPoint(x: mx + nx * halfW, y: my + ny * halfW))
                p.addQuadCurve(to: CGPoint(x: px, y: py),
                               control: CGPoint(x: mx - nx * halfW, y: my - ny * halfW))
                p.closeSubpath()
                ctx.fill(p, with: .color(color))
            }

            leaf(0.55, len: 0.18, baseAngle: -.pi / 2.5, side: -1)  // left
            leaf(0.78, len: 0.20, baseAngle: -.pi / 2.5, side:  1)  // right
            leaf(0.98, len: 0.17, baseAngle: -.pi / 2.0, side: -1)  // crown
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
