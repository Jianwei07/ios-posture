import SwiftUI

// Bunga raya hibiscus — Malaysia. Five red petals with the signature long
// gold stamen reaching past the bloom.
struct Hibiscus: Plant {
    var bend: Double
    var color: Color

    private let petal = Color(hex: 0xD24B43)
    private let core = Color(hex: 0xB23A33)
    private let stamen = Color(hex: 0xE4A93D)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.26)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.45), size: size, side: 1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)
            let o = CGPoint.zero

            for i in 0..<5 {
                bloom.fill(FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.135),
                                             rx: w * 0.115, ry: w * 0.165,
                                             rotation: Double(i) * 2 * .pi / 5, around: o),
                           with: .color(petal))
            }
            bloom.fill(Path(ellipseIn: CGRect(x: -w * 0.055, y: -w * 0.055, width: w * 0.11, height: w * 0.11)),
                       with: .color(core))

            // Stamen: thin gold column out of the core, anther dot at the end.
            var column = Path()
            column.move(to: o)
            column.addLine(to: CGPoint(x: w * 0.19, y: -w * 0.19))
            bloom.stroke(column, with: .color(stamen),
                         style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
            bloom.fill(Path(ellipseIn: CGRect(x: w * 0.155, y: -w * 0.225, width: w * 0.07, height: w * 0.07)),
                       with: .color(stamen))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
