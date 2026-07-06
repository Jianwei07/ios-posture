import SwiftUI

// Ratchaphruek / golden shower — Thailand. A naturally drooping raceme of
// small gold blossoms cascading down the stem.
struct GoldenShower: Plant {
    var bend: Double
    var color: Color

    private let blossom = Color(hex: 0xEBB61F)
    private let dot = Color(hex: 0xC68F0E)

    var body: some View {
        Canvas { ctx, size in
            let b = CGFloat(max(0, min(1, bend)))
            let w = size.width, h = size.height, cx = w / 2
            let potTop = h * 0.72

            // Stem arcs away from the cascade; bend deepens the arc.
            let tip = CGPoint(x: cx - w * 0.13 + w * 0.30 * b, y: h * (0.24 + 0.14 * Double(b)))
            var stem = Path()
            stem.move(to: CGPoint(x: cx + w * 0.04, y: potTop + h * 0.02))
            stem.addQuadCurve(to: tip, control: CGPoint(x: cx + w * 0.10, y: h * 0.45))
            ctx.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.055, lineCap: .round))

            // Cascade: blossoms strung below the tip, swinging with bend.
            let drops: [(CGFloat, CGFloat, CGFloat)] = [  // (dx, dy, r) in w units
                (0.00, 0.00, 0.085),
                (0.09, 0.14, 0.085),
                (-0.06, 0.17, 0.075),
                (0.08, 0.30, 0.075),
                (-0.04, 0.36, 0.068),
                (0.10, 0.44, 0.068),
            ]
            for (i, d) in drops.enumerated() {
                let sway = w * 0.06 * b * CGFloat(i) / 5  // lower blossoms swing further
                let c = CGPoint(x: tip.x + d.0 * w + sway, y: tip.y + d.1 * w)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - d.2 * w, y: c.y - d.2 * w,
                                                width: d.2 * w * 2, height: d.2 * w * 2)),
                         with: .color(blossom))
                if i % 2 == 0 {
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.026, y: c.y - w * 0.026,
                                                    width: w * 0.052, height: w * 0.052)),
                             with: .color(dot))
                }
            }

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
