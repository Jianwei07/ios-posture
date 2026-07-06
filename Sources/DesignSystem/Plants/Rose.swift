import SwiftUI

// Rose — USA. Layered red cup: alternating warm/deep bands spiral inward,
// sepals collar the bloom.
struct Rose: Plant {
    var bend: Double
    var color: Color

    private let base = Color(hex: 0xC4523F)
    private let bandLight = Color(hex: 0xD06B57)
    private let bandDeep = Color(hex: 0xB8402F)
    private let bandInner = Color(hex: 0xDA7660)
    private let core = Color(hex: 0x93301F)
    private let sepal = Color(hex: 0x6FA487)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.27)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.40), size: size, side: -1, bend: bend, color: color.opacity(0.65))
            FlowerParts.leaf(ctx, at: stem.point(at: 0.55), size: size, side: 1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)

            // Sepal collar peeking under the cup.
            var sepals = Path()
            sepals.move(to: CGPoint(x: -w * 0.09, y: w * 0.02))
            sepals.addLine(to: CGPoint(x: 0, y: w * 0.14))
            sepals.addLine(to: CGPoint(x: w * 0.09, y: w * 0.02))
            sepals.closeSubpath()
            bloom.fill(sepals, with: .color(sepal))

            // Layered cup: each petal band sinks toward the lip so the whorl
            // reads as folded petals, not a bullseye.
            let head = CGPoint(x: 0, y: -w * 0.10)
            func band(_ rx: CGFloat, _ ry: CGFloat, _ dx: CGFloat, _ dy: CGFloat, _ c: Color) {
                bloom.fill(Path(ellipseIn: CGRect(x: head.x + dx * w - rx, y: head.y + dy * w - ry,
                                                  width: rx * 2, height: ry * 2)),
                           with: .color(c))
            }
            band(w * 0.20, w * 0.18, 0, 0, base)
            band(w * 0.175, w * 0.125, -0.015, 0.045, bandLight)
            band(w * 0.135, w * 0.090, 0.02, 0.075, bandDeep)
            band(w * 0.085, w * 0.058, -0.01, 0.095, bandInner)
            band(w * 0.036, w * 0.028, 0.005, 0.105, core)

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
