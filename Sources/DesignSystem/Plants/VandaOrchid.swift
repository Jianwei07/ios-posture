import SwiftUI

// Vanda 'Miss Joaquim' orchid — Singapore. Fan of violet petals over a
// deep-purple labellum with a gold throat.
struct VandaOrchid: Plant {
    var bend: Double
    var color: Color

    private let petalTop = Color(hex: 0xB27BC4)
    private let petalSide = Color(hex: 0xA96FBD)
    private let labellum = Color(hex: 0x8E4FA6)
    private let throat = Color(hex: 0xEBC46A)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.28)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.42), size: size, side: -1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)
            let o = CGPoint.zero

            // Dorsal petal + two spread laterals.
            bloom.fill(FlowerParts.petal(center: CGPoint(x: 0, y: -w * 0.15), rx: w * 0.085, ry: w * 0.16,
                                         rotation: 0, around: o),
                       with: .color(petalTop))
            bloom.fill(FlowerParts.petal(center: CGPoint(x: -w * 0.16, y: -w * 0.02), rx: w * 0.14, ry: w * 0.085,
                                         rotation: -0.4, around: CGPoint(x: -w * 0.16, y: -w * 0.02)),
                       with: .color(petalSide))
            bloom.fill(FlowerParts.petal(center: CGPoint(x: w * 0.16, y: -w * 0.02), rx: w * 0.14, ry: w * 0.085,
                                         rotation: 0.4, around: CGPoint(x: w * 0.16, y: -w * 0.02)),
                       with: .color(petalSide))

            // Labellum: pointed lip below the throat.
            var lip = Path()
            lip.move(to: CGPoint(x: 0, y: -w * 0.02))
            lip.addQuadCurve(to: CGPoint(x: 0, y: w * 0.22),
                             control: CGPoint(x: -w * 0.12, y: w * 0.12))
            lip.addQuadCurve(to: CGPoint(x: 0, y: -w * 0.02),
                             control: CGPoint(x: w * 0.12, y: w * 0.12))
            bloom.fill(lip, with: .color(labellum))

            bloom.fill(Path(ellipseIn: CGRect(x: -w * 0.045, y: -w * 0.005, width: w * 0.09, height: w * 0.09)),
                       with: .color(throat))

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
