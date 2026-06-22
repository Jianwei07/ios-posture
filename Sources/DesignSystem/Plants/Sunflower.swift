import SwiftUI

// Sunflower — stem tilts forward with bend, round head + petals.
// bend=0: tall green sprout, head up. bend=1: stem droops forward, head bows.
struct Sunflower: Plant {
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

            // Stem — quadratic curve, tip leans forward as bend grows
            let baseY = potTop
            let tipX = cx + w * 0.22 * b
            let tipY = h * 0.22 + h * 0.12 * b
            let ctrlX = cx + w * 0.08 * b
            let ctrlY = h * 0.48
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: baseY))
            stem.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: ctrlX, y: ctrlY))
            ctx.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))

            // Head — circle at tip
            let headR = w * 0.16
            let headRect = CGRect(x: tipX - headR, y: tipY - headR, width: headR * 2, height: headR * 2)
            ctx.fill(Path(ellipseIn: headRect), with: .color(Color(hex: 0x6B4E2A)))

            // Petals — 8 around the head
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4 + b * 0.3
                let px = tipX + cos(angle) * headR * 1.3
                let py = tipY + sin(angle) * headR * 1.3
                let petalR = headR * 0.5
                let petalRect = CGRect(x: px - petalR, y: py - petalR, width: petalR * 2, height: petalR * 2)
                ctx.fill(Path(ellipseIn: petalRect), with: .color(Color(hex: 0xE8B84B)))
            }

            // Head center dot
            ctx.fill(Path(ellipseIn: CGRect(x: tipX - headR * 0.5, y: tipY - headR * 0.5,
                                            width: headR, height: headR)),
                     with: .color(Color(hex: 0x5A3E22)))
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
