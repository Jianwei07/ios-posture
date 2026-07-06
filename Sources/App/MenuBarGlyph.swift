#if os(macOS)
import AppKit

// Menu-bar glyph: monochrome stem-and-bloom drawn in `labelColor` (resolved at
// draw time inside the NSImage drawing handler, so it tracks the light/dark
// menu bar) with posture state carried by a small Sage-colored dot at the
// base — the plant itself never takes the state color in the bar. Wilt bends
// the stem; the dot is the primary signal.
enum MenuBarGlyph {

    static func image(for state: MenuBarState) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            draw(state)
            return true
        }
        // Colors are ours (labelColor glyph + colored dot) — template
        // rendering would flatten the dot to monochrome.
        image.isTemplate = false
        image.accessibilityDescription = accessibilityLabel(for: state)
        return image
    }

    // MARK: Drawing (18×18 flipped canvas, geometry scaled from the board's 24-unit glyph)

    private static func draw(_ state: MenuBarState) {
        let ink = NSColor.labelColor

        let bloomCenter: NSPoint
        let stem = NSBezierPath()
        stem.lineWidth = 1.5
        stem.lineCapStyle = .round

        if state == .wilt {
            // Stem tips over; bloom hangs right and low.
            bloomCenter = NSPoint(x: 12.1, y: 9.2)
            stem.move(to: NSPoint(x: 8.4, y: 16.3))
            stem.curve(to: NSPoint(x: 11.0, y: 10.9),
                       controlPoint1: NSPoint(x: 8.4, y: 13.6),
                       controlPoint2: NSPoint(x: 9.2, y: 11.9))
        } else {
            bloomCenter = NSPoint(x: 9, y: 6.4)
            stem.move(to: NSPoint(x: 9, y: 16.3))
            stem.line(to: NSPoint(x: 9, y: 8.6))
        }

        ink.setStroke()
        stem.stroke()

        // 5 petals: ellipses radiating from the bloom center, 72° apart.
        let petalScale: CGFloat = state == .wilt ? 0.88 : 1
        let rx: CGFloat = 1.6 * petalScale
        let ry: CGFloat = 2.55 * petalScale
        let reach: CGFloat = 3.2 * petalScale  // bloom center → petal center

        let petals = NSBezierPath()
        for i in 0..<5 {
            let petal = NSBezierPath(ovalIn: NSRect(x: bloomCenter.x - rx,
                                                    y: bloomCenter.y - reach - ry,
                                                    width: rx * 2,
                                                    height: ry * 2))
            var spin = AffineTransform(translationByX: bloomCenter.x, byY: bloomCenter.y)
            spin.rotate(byDegrees: CGFloat(i) * 72)
            spin.translate(x: -bloomCenter.x, y: -bloomCenter.y)
            petal.transform(using: spin)
            petals.append(petal)
        }
        ink.setFill()
        petals.fill()

        // Hollow core, like the board glyph's punched center.
        punchCircle(at: bloomCenter, radius: 1.45)

        // State dot at the base, with a cleared halo so it reads on any bar
        // background and never merges with the stem.
        if let dot = dotColor(for: state) {
            let dotCenter = NSPoint(x: 14.2, y: 14.7)
            punchCircle(at: dotCenter, radius: 4.0)
            dot.setFill()
            NSBezierPath(ovalIn: NSRect(x: dotCenter.x - 2.9,
                                        y: dotCenter.y - 2.9,
                                        width: 5.8,
                                        height: 5.8)).fill()
        }
    }

    // Erases already-drawn pixels inside the circle (destination-out), so the
    // menu bar shows through — used for the bloom core and the dot halo.
    private static func punchCircle(at center: NSPoint, radius: CGFloat) {
        guard let ctx = NSGraphicsContext.current else { return }
        ctx.saveGraphicsState()
        ctx.compositingOperation = .destinationOut
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - radius,
                                    y: center.y - radius,
                                    width: radius * 2,
                                    height: radius * 2)).fill()
        ctx.restoreGraphicsState()
    }

    // Sage state colors (Theme.Palette equivalents, AppKit-side).
    private static func dotColor(for state: MenuBarState) -> NSColor? {
        switch state {
        case .idle:    return nil
        case .aligned: return NSColor(srgbRed: 0x5F / 255, green: 0x9A / 255, blue: 0x78 / 255, alpha: 1)
        case .drift:   return NSColor(srgbRed: 0xCC / 255, green: 0x8A / 255, blue: 0x5A / 255, alpha: 1)
        case .wilt:    return NSColor(srgbRed: 0xB0 / 255, green: 0x5A / 255, blue: 0x38 / 255, alpha: 1)
        }
    }

    private static func accessibilityLabel(for state: MenuBarState) -> String {
        switch state {
        case .idle:    return "Posture: not tracking"
        case .aligned: return "Posture: aligned"
        case .drift:   return "Posture: drifting"
        case .wilt:    return "Posture: slouching"
        }
    }
}
#endif
