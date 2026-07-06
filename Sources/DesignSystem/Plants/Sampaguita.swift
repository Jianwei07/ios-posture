import SwiftUI

// Sampaguita jasmine — Philippines. A main white bloom plus a smaller bud
// cluster on a short side branch.
struct Sampaguita: Plant {
    var bend: Double
    var color: Color

    private let petal = Color(hex: 0xFBF7EF)
    private let outline = Color(hex: 0xE7DDC9)
    private let heart = Color(hex: 0xEBC46A)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.30)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.48), size: size, side: 1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)

            // Main bloom: 4 petals in a cross.
            let mainCenter = CGPoint(x: -w * 0.05, y: 0)
            for i in 0..<4 {
                let path = FlowerParts.petal(center: CGPoint(x: mainCenter.x, y: mainCenter.y - w * 0.105),
                                             rx: w * 0.075, ry: w * 0.115,
                                             rotation: Double(i) * .pi / 2, around: mainCenter)
                bloom.fill(path, with: .color(petal))
                bloom.stroke(path, with: .color(outline), lineWidth: 1)
            }
            bloom.fill(Path(ellipseIn: CGRect(x: mainCenter.x - w * 0.04, y: mainCenter.y - w * 0.04,
                                              width: w * 0.08, height: w * 0.08)),
                       with: .color(heart))

            // Bud cluster up-right on a short branch: 3 smaller petals.
            let budCenter = CGPoint(x: w * 0.17, y: -w * 0.16)
            var branch = Path()
            branch.move(to: .zero)
            branch.addQuadCurve(to: budCenter, control: CGPoint(x: w * 0.10, y: -w * 0.04))
            bloom.stroke(branch, with: .color(color), style: StrokeStyle(lineWidth: w * 0.028, lineCap: .round))
            for i in 0..<3 {
                let path = FlowerParts.petal(center: CGPoint(x: budCenter.x, y: budCenter.y - w * 0.075),
                                             rx: w * 0.05, ry: w * 0.08,
                                             rotation: Double(i) * 2 * .pi / 3, around: budCenter)
                bloom.fill(path, with: .color(petal))
                bloom.stroke(path, with: .color(outline), lineWidth: 1)
            }
            bloom.fill(Path(ellipseIn: CGRect(x: budCenter.x - w * 0.026, y: budCenter.y - w * 0.026,
                                              width: w * 0.052, height: w * 0.052)),
                       with: .color(heart))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
