import SwiftUI

// Rumduol — Cambodia. A shy nodding bloom of three thick cream petals on a
// gently curved stem.
struct Rumduol: Plant {
    var bend: Double
    var color: Color

    private let petal = Color(hex: 0xF0E4A8)
    private let heart = Color(hex: 0xD9BE5C)

    var body: some View {
        Canvas { ctx, size in
            let b = CGFloat(max(0, min(1, bend)))
            let w = size.width, h = size.height, cx = w / 2
            let potTop = h * 0.72

            // Stem carries a natural nod even upright; bend deepens it.
            let tip = CGPoint(x: cx + w * 0.10 + w * 0.16 * b, y: h * (0.28 + 0.13 * Double(b)))
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: potTop + h * 0.02))
            stem.addQuadCurve(to: tip, control: CGPoint(x: cx + w * 0.02 + w * 0.07 * b, y: h * 0.42))
            ctx.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.055, lineCap: .round))

            let leafAt = CGPoint(x: cx + w * 0.015, y: h * 0.50)
            FlowerParts.leaf(ctx, at: leafAt, size: size, side: -1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: tip, bend: bend)

            // Three plump petals in a loose triangle.
            let spots: [(CGFloat, CGFloat, Double)] = [
                (0.02, -0.13, 0.5),
                (0.13, -0.02, 1.6),
                (0.02, 0.08, -0.6),
            ]
            for s in spots {
                let c = CGPoint(x: s.0 * w, y: s.1 * w)
                bloom.fill(FlowerParts.petal(center: c, rx: w * 0.075, ry: w * 0.105,
                                             rotation: s.2, around: c),
                           with: .color(petal))
            }
            bloom.fill(Path(ellipseIn: CGRect(x: -w * 0.005, y: -w * 0.055, width: w * 0.10, height: w * 0.10)),
                       with: .color(heart))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
