# Task: Menu-bar glyph — monochrome plant + state dot

## Objective
Menu bar shows custom stem-and-bloom glyph (adapts light/dark bar) with a colored state dot at the base: aligned #5F9A78, drift #CC8A5A, wilt #B05A38, idle = no dot. Wilt subtly bends the stem.

## Context
- Design board section 01 (Locked): glyph stays monochrome template-style; state carried only by dot. 5-petal bloom (ellipses rotated 72° about bloom center), vertical stem, hole punched in bloom center.
- Current: `Sources/App/SynthesisApp.swift:50` uses `MenuBarExtra("Synthesis", systemImage: appModel.menuBarState.symbolName)`.
- `Sources/App/MenuBarState.swift` — reducer stays; `symbolName` no longer used by macOS scene (keep for iOS/back-compat or delete if unreferenced).
- SwiftUI MenuBarExtra label templates custom views (colors stripped). Fix: `Image(nsImage:)` with `isTemplate = false`, built via `NSImage(size:flipped:drawingHandler:)` — handler is re-invoked at draw time so `NSColor.labelColor` inside it resolves against the live menu-bar appearance. Dot drawn in fixed Sage state color.

## Changes
1. New `Sources/App/MenuBarGlyph.swift` (macOS-only, `#if os(macOS)`): `enum MenuBarGlyph { static func image(for state: MenuBarState) -> NSImage }`. 18×18 pt canvas; stem = 2pt rounded line; bloom = 5 rotated ellipses + punched center (use `NSBezierPath` + even-odd or draw center circle in `.clear` composite); wilt state curves stem path right and drops bloom center. Dot: 6pt circle bottom-right, 1.4pt border in `labelColor`-contrasting clear gap (draw dot after clearing a 8.8pt circle behind it using destinationOut).
2. `Sources/App/SynthesisApp.swift`: macOS `MenuBarExtra` gets `label:` closure `Image(nsImage: MenuBarGlyph.image(for: appModel.menuBarState))`.

## Verification
- `cd /Users/jayden77/dev/ios-posture && xcodebuild build -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`
- Existing tests still green: `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`

## Done
- Menu bar renders plant glyph with green/clay/terracotta dot matching MenuBarState; no dot when idle; builds + tests green.
