import SwiftUI

// Lotus — Vietnam. Layered pink petals fanning from the bloom base, deeper
// pink heart petal, gold center.
struct Lotus: Plant {
    var bend: Double
    var color: Color

    private let petal = Color(hex: 0xE58AA8)
    private let inner = Color(hex: 0xD26E90)
    private let center = Color(hex: 0xEBC46A)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.30)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.46), size: size, side: -1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)
            let base = CGPoint.zero  // petals fan from the bloom base

            // Outer fan: wide low petals, slightly translucent like the board.
            for angle in [-1.15, 1.15] {
                bloom.fill(FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.13),
                                             rx: w * 0.075, ry: w * 0.15,
                                             rotation: angle, around: base)
                    , with: .color(petal.opacity(0.82)))
            }
            // Mid pair.
            for angle in [-0.62, 0.62] {
                bloom.fill(FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.155),
                                             rx: w * 0.08, ry: w * 0.165,
                                             rotation: angle, around: base),
                           with: .color(petal))
            }
            // Tall central petal + deeper heart.
            bloom.fill(FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.17),
                                         rx: w * 0.085, ry: w * 0.18,
                                         rotation: 0, around: base),
                       with: .color(petal))
            bloom.fill(FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.10),
                                         rx: w * 0.045, ry: w * 0.11,
                                         rotation: 0, around: base),
                       with: .color(inner))
            bloom.fill(Path(ellipseIn: CGRect(x: -w * 0.035, y: -w * 0.05, width: w * 0.07, height: w * 0.07)),
                       with: .color(center))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
