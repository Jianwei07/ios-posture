import SwiftUI

// Padauk — Myanmar. A burst of small fragrant gold blossoms clustered at
// the stem tip.
struct Padauk: Plant {
    var bend: Double
    var color: Color

    private let blossom = Color(hex: 0xF4C64A)
    private let dot = Color(hex: 0xD9A21F)

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let potTop = size.height * 0.72

            let stem = FlowerParts.stem(ctx, size: size, bend: bend, color: color, potTop: potTop, topY: 0.30)
            FlowerParts.leaf(ctx, at: stem.point(at: 0.46), size: size, side: 1, bend: bend, color: color.opacity(0.65))

            let bloom = FlowerParts.bloomContext(ctx, tip: stem.tip, bend: bend)

            // Cluster of overlapping blossoms; every other one gets a center dot.
            let cluster: [(CGFloat, CGFloat, CGFloat)] = [  // (dx, dy, r) in w units
                (-0.11, -0.08, 0.085),
                (0.04, -0.14, 0.085),
                (0.14, 0.00, 0.085),
                (-0.05, 0.03, 0.078),
                (0.05, -0.02, 0.072),
            ]
            for (i, c) in cluster.enumerated() {
                let center = CGPoint(x: c.0 * w, y: c.1 * w)
                bloom.fill(Path(ellipseIn: CGRect(x: center.x - c.2 * w, y: center.y - c.2 * w,
                                                  width: c.2 * w * 2, height: c.2 * w * 2)),
                           with: .color(blossom))
                if i < 3 {
                    bloom.fill(Path(ellipseIn: CGRect(x: center.x - w * 0.026, y: center.y - w * 0.026,
                                                      width: w * 0.052, height: w * 0.052)),
                               with: .color(dot))
                }
            }

            PlantPot.draw(ctx, size: size, potTop: potTop)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
