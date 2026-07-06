import SwiftUI

// Dok Champa (plumeria) — Laos. Five pinwheel ivory petals around a big
// warm-gold heart.
struct DokChampa: Plant {
    var bend: Double
    var color: Color

    private let petal = Color(hex: 0xFBF7EF)
    private let outline = Color(hex: 0xEADFCA)
    private let heart = Color(hex: 0xF2D77E)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.28)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.44), size: size, side: -1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)
            let o = CGPoint.zero

            // Pinwheel: an off-axis teardrop petal repeated by rotation.
            var teardrop = Path()
            teardrop.move(to: o)
            teardrop.addQuadCurve(to: CGPoint(x: w * 0.10, y: -w * 0.21),
                                  control: CGPoint(x: -w * 0.06, y: -w * 0.16))
            teardrop.addQuadCurve(to: o,
                                  control: CGPoint(x: w * 0.15, y: -w * 0.06))
            for i in 0..<5 {
                let path = teardrop.applying(CGAffineTransform(rotationAngle: CGFloat(i) * 2 * .pi / 5))
                bloom.fill(path, with: .color(petal))
                bloom.stroke(path, with: .color(outline), lineWidth: 1)
            }
            bloom.fill(Path(ellipseIn: CGRect(x: -w * 0.075, y: -w * 0.075, width: w * 0.15, height: w * 0.15)),
                       with: .color(heart))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
