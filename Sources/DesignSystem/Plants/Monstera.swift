import SwiftUI

// Monstera — terracotta pot + 2 stems fanning into split-leaf canopy.
// bend=0: upright fanned canopy. bend=1: stems rotate down and outward,
// leaves follow the stem they're attached to instead of swinging on their own.
struct Monstera: Plant {
    var bend: Double
    var color: Color

    private let potColor = Color(hex: 0xC98A5B)
    private let potOutline = Color(hex: 0x4A3526)
    private let soilColor = Color(hex: 0x3A2A1E)
    private let stemColor = Color(hex: 0x4A3526)
    private let leafOutline = Color(hex: 0x243018)

    var body: some View {
        Canvas { ctx, size in
            let b = max(0, min(1, bend))
            let w = size.width, h = size.height
            let cx = w / 2

            // Ground shadow
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w * 0.26, y: h * 0.91,
                                             width: w * 0.52, height: h * 0.05)),
                     with: .color(.black.opacity(0.10)))

            // Pot — terracotta trapezoid + dark outline
            let potTop = h * 0.70, potBot = h * 0.91
            let potTopW = w * 0.22, potBotW = w * 0.17
            var pot = Path()
            pot.move(to: CGPoint(x: cx - potTopW, y: potTop))
            pot.addLine(to: CGPoint(x: cx + potTopW, y: potTop))
            pot.addLine(to: CGPoint(x: cx + potBotW, y: potBot))
            pot.addLine(to: CGPoint(x: cx - potBotW, y: potBot))
            pot.closeSubpath()
            ctx.fill(pot, with: .color(potColor))
            ctx.stroke(pot, with: .color(potOutline),
                       style: StrokeStyle(lineWidth: w * 0.022, lineJoin: .round))

            // Pot rim — thick dark line at top
            var rim = Path()
            rim.move(to: CGPoint(x: cx - potTopW, y: potTop))
            rim.addLine(to: CGPoint(x: cx + potTopW, y: potTop))
            ctx.stroke(rim, with: .color(potOutline),
                       style: StrokeStyle(lineWidth: w * 0.035, lineCap: .butt))

            // Soil ellipse inside rim
            ctx.fill(Path(ellipseIn: CGRect(x: cx - potTopW + w * 0.02, y: potTop - h * 0.012,
                                             width: (potTopW - w * 0.02) * 2, height: h * 0.035)),
                     with: .color(soilColor))

            // Stems fan from the pot. Bend rotates each stem's own emission
            // angle further away from vertical (signed by which side it
            // already leans), so the stem itself visibly droops down and
            // outward — not just its tip nudged a few points sideways.
            let baseY = potTop
            let bendAngle = b * 0.45          // rad of extra lean at full slouch (~26°)
            let ctrlBendFrac = 0.35           // fraction of that lean the mid-stem control point picks up

            let stems: [(angle: Double, len: Double, bendScale: Double)] = [
                (-0.38, 0.52, 1.1),
                ( 0.28, 0.56, 1.0),
            ]
            let showHoles = size.width >= 80  // holes alias into noise at thumbnail scale

            for (i, stem) in stems.enumerated() {
                let isBack = i == 0
                let alpha = isBack ? 0.82 : 1.0
                let sign: Double = stem.angle < 0 ? -1 : 1
                let stemBend = sign * bendAngle * stem.bendScale
                let tipA = stem.angle + stemBend
                let tipX = cx + sin(tipA) * stem.len * w
                let tipY = baseY - cos(tipA) * stem.len * h
                let ctrlA = stem.angle + stemBend * ctrlBendFrac
                let ctrlX = cx + sin(ctrlA) * stem.len * w * 0.45
                let ctrlY = baseY - cos(ctrlA) * stem.len * h * 0.5
                var sPath = Path()
                sPath.move(to: CGPoint(x: cx, y: baseY))
                sPath.addQuadCurve(to: CGPoint(x: tipX, y: tipY),
                                   control: CGPoint(x: ctrlX, y: ctrlY))
                ctx.stroke(sPath, with: .color(stemColor.opacity(alpha)),
                           style: StrokeStyle(lineWidth: w * (isBack ? 0.026 : 0.032),
                                              lineCap: .round))

                // Leaves along stem, base→tip so upper leaves overlap lower.
                // Leaf rotation follows the stem's own local bend at that t
                // (more of it near the tip) plus a small residual per-leaf
                // droop, so the canopy rides the stem instead of swinging
                // on its own.
                let leafSizes: [(t: Double, len: Double, off: Double)] = [
                    (0.50, 0.20, -0.6),
                    (0.72, 0.24,  0.5),
                    (0.96, 0.19, -0.3),
                ]
                for ll in leafSizes {
                    let u = 1 - ll.t
                    let lx = u*u*cx + 2*u*ll.t*ctrlX + ll.t*ll.t*tipX
                    let ly = u*u*baseY + 2*u*ll.t*ctrlY + ll.t*ll.t*tipY
                    let follow = stemBend * (ctrlBendFrac + (1 - ctrlBendFrac) * ll.t)
                    let leafAngle = stem.angle + ll.off + follow + sign * b * 0.10 * ll.t
                    drawLeaf(ctx: ctx, base: CGPoint(x: lx, y: ly),
                             angle: leafAngle, length: ll.len * w,
                             w: w, fill: color.opacity(alpha),
                             outlineWidth: w * (isBack ? 0.006 : 0.008),
                             bend: b, showHoles: showHoles)
                }
            }
        }
        .aspectRatio(0.82, contentMode: .fit)
    }

    // One cubic-Bézier segment of the blade margin (unit leaf space).
    private struct Seg {
        let c1: CGPoint, c2: CGPoint, p: CGPoint
        init(_ c1x: Double, _ c1y: Double, _ c2x: Double, _ c2y: Double,
             _ px: Double, _ py: Double) {
            c1 = CGPoint(x: c1x, y: c1y)
            c2 = CGPoint(x: c2x, y: c2y)
            p  = CGPoint(x: px, y: py)
        }
    }

    // Upper margin, base (0,0) → tip (1,0), +y = droop side.
    // Three deep marginal splits (in-and-back-out wedges angled toward base).
    private static let upperMargin: [Seg] = [
        Seg(-0.05, 0.14,  0.01, 0.30,  0.09, 0.33),  // base lobe
        Seg( 0.15, 0.40,  0.20, 0.44,  0.26, 0.44),  // → split 1 entry
        Seg( 0.24, 0.36,  0.19, 0.20,  0.16, 0.13),  // split 1 in
        Seg( 0.22, 0.16,  0.28, 0.38,  0.34, 0.45),  // split 1 out
        Seg( 0.40, 0.48,  0.45, 0.46,  0.50, 0.42),  // margin bulge → split 2 entry
        Seg( 0.48, 0.32,  0.44, 0.17,  0.42, 0.11),  // split 2 in
        Seg( 0.47, 0.15,  0.52, 0.33,  0.58, 0.40),  // split 2 out
        Seg( 0.64, 0.40,  0.70, 0.35,  0.74, 0.30),  // → split 3 entry
        Seg( 0.72, 0.22,  0.70, 0.13,  0.68, 0.09),  // split 3 in
        Seg( 0.72, 0.11,  0.76, 0.21,  0.80, 0.26),  // split 3 out
        Seg( 0.88, 0.22,  0.97, 0.08,  1.00, 0.00),  // taper to tip
    ]

    // Elongated fenestration holes flanking the midrib (unit space).
    private static let holes: [CGRect] = [
        CGRect(x: 0.245, y:  0.198, width: 0.11, height: 0.044),
        CGRect(x: 0.495, y:  0.168, width: 0.11, height: 0.044),
        CGRect(x: 0.290, y: -0.252, width: 0.10, height: 0.044),
        CGRect(x: 0.530, y: -0.192, width: 0.10, height: 0.044),
    ]

    private func drawLeaf(ctx: GraphicsContext, base: CGPoint,
                          angle: Double, length: Double, w: Double,
                          fill: Color, outlineWidth: Double,
                          bend: Double, showHoles: Bool) {
        // Blade outline in unit space: up the +y margin, mirrored back down −y.
        var blade = Path()
        blade.move(to: .zero)
        for s in Self.upperMargin {
            blade.addCurve(to: s.p, control1: s.c1, control2: s.c2)
        }
        func flip(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x, y: -p.y) }
        for i in stride(from: Self.upperMargin.count - 1, through: 0, by: -1) {
            let end = i == 0 ? CGPoint.zero : flip(Self.upperMargin[i - 1].p)
            blade.addCurve(to: end,
                           control1: flip(Self.upperMargin[i].c2),
                           control2: flip(Self.upperMargin[i].c1))
        }
        blade.closeSubpath()

        var leaf = blade
        if showHoles {
            for hole in Self.holes { leaf.addPath(Path(ellipseIn: hole)) }
        }

        let transform = CGAffineTransform(translationX: base.x, y: base.y)
            .rotated(by: angle)
            .scaledBy(x: length, y: length)
        let world = leaf.applying(transform)
        ctx.fill(world, with: .color(fill), style: FillStyle(eoFill: true))
        ctx.stroke(blade.applying(transform), with: .color(leafOutline),
                   style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))

        // Midrib — quadratic whose sag grows with bend (tip leads the droop).
        var rib = Path()
        rib.move(to: CGPoint(x: 0.02, y: 0))
        rib.addQuadCurve(to: CGPoint(x: 0.96, y: 0),
                         control: CGPoint(x: 0.5, y: 0.06 + 0.20 * bend))
        ctx.stroke(rib.applying(transform), with: .color(leafOutline.opacity(0.4)),
                   style: StrokeStyle(lineWidth: w * 0.006, lineCap: .round))
    }
}
