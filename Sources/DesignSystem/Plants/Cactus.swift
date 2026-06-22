import SwiftUI

// Cactus — body tilts forward with bend, arms sag.
// bend=0: upright rounded body. bend=1: leans forward, arms droop.
struct Cactus: Plant {
    var bend: Double
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let b = max(0, min(1, bend))
            let w = size.width, h = size.height
            let cx = w / 2

            // Pot
            let potTop = h * 0.75, potBot = h * 0.95
            var pot = Path()
            pot.move(to: CGPoint(x: cx - w * 0.18, y: potTop))
            pot.addLine(to: CGPoint(x: cx + w * 0.18, y: potTop))
            pot.addLine(to: CGPoint(x: cx + w * 0.13, y: potBot))
            pot.addLine(to: CGPoint(x: cx - w * 0.13, y: potBot))
            pot.closeSubpath()
            ctx.fill(pot, with: .color(Color(hex: 0xC98A5B)))

            // Body — rounded rect that leans
            let bodyW = w * 0.28, bodyH = h * 0.5
            let bodyX = cx - bodyW / 2 + w * 0.12 * b  // lean right as bend grows
            let bodyY = potTop - bodyH
            let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
            ctx.fill(Path(roundedRect: bodyRect, cornerRadius: bodyW / 2),
                     with: .color(color))

            // Left arm — sags down as bend grows
            let armLStart = CGPoint(x: bodyX, y: bodyY + bodyH * 0.35)
            let armLEnd = CGPoint(x: bodyX - w * 0.12, y: bodyY + bodyH * 0.35 + h * 0.08 * b)
            var armL = Path()
            armL.move(to: armLStart)
            armL.addLine(to: CGPoint(x: armLStart.x - w * 0.08, y: armLStart.y))
            armL.addLine(to: armLEnd)
            ctx.stroke(armL, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round, lineJoin: .round))

            // Right arm — sags down as bend grows
            let armRStart = CGPoint(x: bodyX + bodyW, y: bodyY + bodyH * 0.25)
            let armREnd = CGPoint(x: bodyX + bodyW + w * 0.12, y: bodyY + bodyH * 0.25 + h * 0.06 * b)
            var armR = Path()
            armR.move(to: armRStart)
            armR.addLine(to: CGPoint(x: armRStart.x + w * 0.08, y: armRStart.y))
            armR.addLine(to: armREnd)
            ctx.stroke(armR, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round, lineJoin: .round))

            // Top dome
            ctx.fill(Path(ellipseIn: CGRect(x: bodyX, y: bodyY - bodyW * 0.15,
                                            width: bodyW, height: bodyW * 0.4)),
                     with: .color(color))
        }
        .aspectRatio(0.82, contentMode: .fit)
    }
}
