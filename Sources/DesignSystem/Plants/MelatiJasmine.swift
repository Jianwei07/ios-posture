import SwiftUI

// Melati putih jasmine — Indonesia. Five ivory petals, gold heart.
struct MelatiJasmine: Plant {
    var bend: Double
    var color: Color

    private let petal = Color(hex: 0xFBF7EF)
    private let outline = Color(hex: 0xE7DDC9)
    private let heart = Color(hex: 0xEBC46A)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.28)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.44), size: size, side: -1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)
            let o = CGPoint.zero

            for i in 0..<5 {
                let path = FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.115),
                                             rx: w * 0.09, ry: w * 0.135,
                                             rotation: Double(i) * 2 * .pi / 5, around: o)
                bloom.fill(path, with: .color(petal))
                bloom.stroke(path, with: .color(outline), lineWidth: 1)
            }
            bloom.fill(Path(ellipseIn: CGRect(x: -w * 0.05, y: -w * 0.05, width: w * 0.10, height: w * 0.10)),
                       with: .color(heart))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
