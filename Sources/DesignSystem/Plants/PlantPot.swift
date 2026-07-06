import SwiftUI

// Shared parts for the national-flower roster (design board section 04):
// every flower sits in the same terracotta pot, grows the same bend-reactive
// stem, and reuses the same leaf and petal primitives — only the bloom
// differs per species. Petal colors stay species-true; the posture state
// `color` tints stem and leaves only.

enum PlantPot {
    static let rim = Color(hex: 0xB96A3D)
    static let body = Color(hex: 0xC67B4E)

    // Rim bar + tapered body. `potTop` is the rim's top edge (y).
    static func draw(_ ctx: GraphicsContext, size: CGSize, potTop: CGFloat) {
        let w = size.width, cx = w / 2
        let rimH = size.height * 0.055
        let rimW = w * 0.46

        ctx.fill(Path(roundedRect: CGRect(x: cx - rimW / 2, y: potTop, width: rimW, height: rimH),
                      cornerRadius: rimH * 0.4),
                 with: .color(rim))

        let bodyTop = potTop + rimH
        let bodyBot = size.height * 0.98
        var pot = Path()
        pot.move(to: CGPoint(x: cx - w * 0.165, y: bodyTop))
        pot.addLine(to: CGPoint(x: cx + w * 0.165, y: bodyTop))
        pot.addLine(to: CGPoint(x: cx + w * 0.125, y: bodyBot))
        pot.addQuadCurve(to: CGPoint(x: cx - w * 0.125, y: bodyBot),
                         control: CGPoint(x: cx, y: bodyBot + w * 0.03))
        pot.closeSubpath()
        ctx.fill(pot, with: .color(body))
    }
}

enum FlowerParts {
    struct Stem {
        let base: CGPoint
        let tip: CGPoint
        let control: CGPoint

        // Point on the quad curve at parameter t (0 = base, 1 = tip).
        func point(at t: CGFloat) -> CGPoint {
            let u = 1 - t
            let x = u * u * base.x + 2 * u * t * control.x + t * t * tip.x
            let y = u * u * base.y + 2 * u * t * control.y + t * t * tip.y
            return CGPoint(x: x, y: y)
        }
    }

    // Bend-reactive stem, same feel as Sunflower's: tip leans forward and
    // sinks as bend grows. `topY` = tip height fraction at bend 0.
    @discardableResult
    static func stem(_ ctx: GraphicsContext, size: CGSize, bend: Double,
                     color: Color, potTop: CGFloat, topY: CGFloat = 0.24) -> Stem {
        let b = CGFloat(max(0, min(1, bend)))
        let w = size.width, h = size.height, cx = w / 2

        let geometry = Stem(
            base: CGPoint(x: cx, y: potTop + h * 0.02),
            tip: CGPoint(x: cx + w * 0.24 * b, y: h * topY + h * 0.14 * b),
            control: CGPoint(x: cx + w * 0.09 * b, y: h * (topY + 0.5) / 2)
        )

        var path = Path()
        path.move(to: geometry.base)
        path.addQuadCurve(to: geometry.tip, control: geometry.control)
        ctx.stroke(path, with: .color(color),
                   style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
        return geometry
    }

    // Pointed leaf blob attached at `p`, reaching out to `side` (−1 left,
    // +1 right). Sags slightly with bend.
    static func leaf(_ ctx: GraphicsContext, at p: CGPoint, size: CGSize,
                     side: CGFloat, bend: Double, color: Color) {
        let w = size.width
        let sag = w * 0.06 * CGFloat(max(0, min(1, bend)))
        let tip = CGPoint(x: p.x + side * w * 0.24, y: p.y + w * 0.10 + sag)
        var path = Path()
        path.move(to: p)
        path.addQuadCurve(to: tip, control: CGPoint(x: p.x + side * w * 0.17, y: p.y - w * 0.05 + sag))
        path.addQuadCurve(to: p, control: CGPoint(x: p.x + side * w * 0.11, y: p.y + w * 0.15))
        ctx.fill(path, with: .color(color))
    }

    // Ellipse petal centered at `center`, rotated about `pivot`.
    static func petal(center: CGPoint, rx: CGFloat, ry: CGFloat,
                      rotation: Double, around pivot: CGPoint) -> Path {
        let rect = CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
        let transform = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: rotation)
            .translatedBy(x: -pivot.x, y: -pivot.y)
        return Path(ellipseIn: rect).applying(transform)
    }

    // Rotated graphics context whose origin is the stem tip — blooms draw in
    // tip-local coordinates and pick up a gentle extra droop with bend.
    static func bloomContext(_ ctx: GraphicsContext, tip: CGPoint, bend: Double) -> GraphicsContext {
        var bloom = ctx
        bloom.translateBy(x: tip.x, y: tip.y)
        bloom.rotate(by: .radians(0.45 * max(0, min(1, bend))))
        return bloom
    }
}
