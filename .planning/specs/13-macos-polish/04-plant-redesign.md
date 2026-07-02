# Task: Plant redesign — Monstera + Cactus

## Objective
Redesign the Monstera (third plant, weakest of the three) so its leaves read as real fenestrated foliage instead of a jagged zigzag, with natural progressive droop as posture worsens. Fix the Cactus so it leans instead of sliding sideways.

## Context
- `Sources/DesignSystem/Plants/Monstera.swift` (133 ln) — pot/soil/shadow drawing (lines ~20-49) and the 2-stem quadratic-curve layout with leaf placement along the curve (lines ~51-88) are solid; keep both. `drawSplitLeaf` (lines 93-132) is the weak point: leaves are built from 8 straight `addLine` segments per side, with "splits" faked by narrowing every even segment to 38% width — reads as a serrated zigzag, not a fenestrated leaf. Vein is a single straight line. Leaf angle is `stem.angle + off + b*0.35` (flat coefficient) so the whole canopy shifts uniformly with bend rather than drooping progressively.
- `Sources/DesignSystem/Plants/Cactus.swift` (60 ln) — body currently *translates* sideways with bend (`bodyX = cx - bodyW/2 + w*0.12*b`, line ~27) rather than leaning, so at high bend the body visibly slides off-center instead of tilting.
- Both conform to the `Plant` protocol (`bend: Double` 0-1, `color: Color`), drawn with `Canvas`+`Path`, `.aspectRatio(0.82, contentMode: .fit)`. `PlantMascot` wraps kind selection and applies `.animation(Theme.Motion.pose, value: bend)`.
- Call sites: `NowView.swift` hero (200pt, live `bend: app.liveBend`), `SettingsView.swift` `PlantPicker` thumbnails (small, all `bend: 0`), `CalibrateView.swift` (hardcoded `.sunflower`, unaffected by this leaf).
- `GraphicsContext.fill(_:with:style:)` with `FillStyle(eoFill: true)` is available (macOS 12+/iOS 15+, well within this project's macOS 14/iOS 17 floor) — use it for fenestration holes as subpaths within one filled `Path`, not separate shapes.

## Changes
1. `Monstera.swift`: replace `drawSplitLeaf` with a leaf built in **local unit space** (base at origin, tip at `(1, 0)`) then transformed into world space via `CGAffineTransform` (translate → rotate → scale), rather than the current inline world-space point math:
   - Outline: a heart-ish blade using `addCurve` (cubic Bézier) on both sides — base lobes near the petiole, max width around t≈0.4, tapering to a tip. Zero straight line segments in the outline.
   - Marginal splits: 2-3 smooth curved notches per side cutting in from the margin toward (not touching) the midrib, each built from two cubic curves (in and back out) — replaces the width-dip zigzag.
   - Fenestrations: 2-4 small elongated ellipse holes flanking the midrib as separate subpaths inside the same `Path`, filled with the outer outline using `ctx.fill(path, with: .color(fill), style: FillStyle(eoFill: true))` so they render as true holes.
   - Midrib: a quadratic curve from base to tip whose sag increases with `bend` (tip visibly leads the droop), replacing the single straight line.
   - Transform each finished unit leaf with `CGAffineTransform(translationX:y:).rotated(by:).scaledBy(x:y:)` matching its placement-along-stem position and length; apply via `path.applying(transform)`.
2. `Monstera.swift`: change leaf angle from the flat `stem.angle + ll.off + b*0.35` to a t-weighted term, e.g. `stem.angle + ll.off + b*(0.45 + 0.55*ll.t)` (`ll.t` = position along the stem, 0=base, 1=tip) — leaves farther from the base rotate more, producing a progressive fold instead of a uniform shift. Increase the midrib sag coefficient with `bend` correspondingly.
3. `Monstera.swift`: add simple depth — draw the back stem (index 0) and its leaves first at `fill.opacity(0.82)` with a slightly thinner stroke, then the front stem at full opacity; within each stem draw lower (closer to base) leaves before upper ones. No z-sort machinery needed, just draw order.
4. `Monstera.swift`: skip fenestration holes when the rendered `size.width < 80` (PlantPicker thumbnails) — at that scale the holes alias into noise; fall back to the plain outline+splits there.
5. `Cactus.swift`: replace the body-x translation with a real rotation about the pot-top anchor point using `ctx.drawLayer { layer in layer.translateBy(x: cx, y: potTop); layer.rotate(by: .radians(b * 0.30)); layer.translateBy(x: -cx, y: -potTop); /* draw body/arms/dome here with bend-independent x */ }`; remove the `b`-dependent term from `bodyX`. Keep the existing arm-sag behavior unchanged — it reads correctly layered on top of a true lean. Pot and ground shadow stay outside the rotated layer (unrotated).

## Verification
- No unit tests (Canvas drawing) — verification is visual, using the existing Simulator/`SimulatorOverlay` bend slider (or `bend:` hardcoded across `0.0, 0.3, 0.6, 1.0` in a scratch preview) to sweep the full range.
- Check all three posture-state colors (aligned/drift/slouch) at hero size (200pt, `NowView`).
- Check `PlantPicker` thumbnail size — confirm no aliasing/noise from skipped fenestrations.
- Check `CalibrateView` progress ring — confirm Monstera changes don't affect the (separately hardcoded) sunflower shown there.
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac build` and iOS build, to confirm no compile regressions from the Canvas/Path rewrite.

## Done
- Monstera leaves read as smooth fenestrated foliage (curved outline, real notches, midrib) at hero size, not a jagged zigzag.
- Canopy droops progressively with bend — leaves farther from the base lean more, tip-led.
- Two-stem depth is visually distinguishable (back stem slightly muted).
- Cactus leans as a rigid body about its base instead of sliding sideways at high bend.
- Both plants remain pure `Canvas`+`Path`, zero new assets, zero new dependencies.
