import SwiftUI

// Monstera — terracotta pot + 2 stems fanning into split-leaf canopy.
// bend=0: upright fanned canopy. bend=1: stems curve forward, leaves droop.
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

            // Stems fan from pot; droop right + down as bend grows.
            let baseY = potTop
            let droopX = b * w * 0.10
            let droopY = b * h * 0.08

            let stems: [(angle: Double, len: Double)] = [
                (-0.38, 0.52),
                ( 0.28, 0.56),
            ]

            for stem in stems {
                let tipX = cx + sin(stem.angle) * stem.len * w + droopX
                let tipY = baseY - cos(stem.angle) * stem.len * h + droopY
                let ctrlX = cx + sin(stem.angle) * stem.len * w * 0.45 + droopX * 0.3
                let ctrlY = baseY - cos(stem.angle) * stem.len * h * 0.5 + droopY * 0.2
                var sPath = Path()
                sPath.move(to: CGPoint(x: cx, y: baseY))
                sPath.addQuadCurve(to: CGPoint(x: tipX, y: tipY),
                                   control: CGPoint(x: ctrlX, y: ctrlY))
                ctx.stroke(sPath, with: .color(stemColor),
                           style: StrokeStyle(lineWidth: w * 0.032, lineCap: .round))

                // Leaves along stem — 3 per stem, drooping with bend
                let leafSizes: [(t: Double, len: Double, off: Double)] = [
                    (0.50, 0.20, -0.6),
                    (0.72, 0.24,  0.5),
                    (0.96, 0.19, -0.3),
                ]
                for ll in leafSizes {
                    let u = 1 - ll.t
                    let lx = u*u*cx + 2*u*ll.t*ctrlX + ll.t*ll.t*tipX
                    let ly = u*u*baseY + 2*u*ll.t*ctrlY + ll.t*ll.t*tipY
                    let leafAngle = stem.angle + ll.off + b * 0.35
                    drawSplitLeaf(ctx: ctx, base: CGPoint(x: lx, y: ly),
                                  angle: leafAngle, length: ll.len,
                                  w: w, fill: color)
                }
            }
        }
        .aspectRatio(0.82, contentMode: .fit)
    }

    private func drawSplitLeaf(ctx: GraphicsContext, base: CGPoint,
                               angle: Double, length: Double, w: Double, fill: Color) {
        let len = length * w
        let tipX = base.x + cos(angle) * len
        let tipY = base.y + sin(angle) * len
        let halfW = len * 0.42
        let perpX = -sin(angle), perpY = cos(angle)

        // Build notched leaf path — 3 deep splits per side.
        var p = Path()
        p.move(to: base)
        let segs = 8
        for i in 1...segs {
            let t = Double(i) / Double(segs)
            let ew = halfW * sin(.pi * t)
            let isDip = (i % 2 == 0) && i < segs
            let ww = isDip ? ew * 0.38 : ew
            p.addLine(to: CGPoint(x: base.x + (tipX - base.x) * t + perpX * ww,
                                  y: base.y + (tipY - base.y) * t + perpY * ww))
        }
        for i in 1..<segs {
            let t = 1.0 - Double(i) / Double(segs)
            let ew = halfW * sin(.pi * t)
            let isDip = (i % 2 == 0) && i < segs
            let ww = isDip ? ew * 0.38 : ew
            p.addLine(to: CGPoint(x: base.x + (tipX - base.x) * t - perpX * ww,
                                  y: base.y + (tipY - base.y) * t - perpY * ww))
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(fill))
        ctx.stroke(p, with: .color(leafOutline),
                   style: StrokeStyle(lineWidth: w * 0.008, lineJoin: .round))

        // Central vein
        var v = Path()
        v.move(to: base)
        v.addLine(to: CGPoint(x: tipX, y: tipY))
        ctx.stroke(v, with: .color(leafOutline.opacity(0.4)),
                   style: StrokeStyle(lineWidth: w * 0.006))
    }
}
