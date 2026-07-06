# Task: Flower roster A — shared pot + 5 plants

## Objective
Five new procedural Canvas plants (Vanda orchid · Singapore, Hibiscus · Malaysia, Melati jasmine · Indonesia, Sampaguita · Philippines, Lotus · Vietnam), each bend-reactive (0 upright → 1 wilt), each in the shared terracotta pot.

## Context
- Design board section 04. All stemmed; bloom-and-wilt through moods. Pot geometry from board: rim rect (fill #B96A3D) + tapered body (#C67B4E).
- Follow `Sources/DesignSystem/Plants/Sunflower.swift` idiom exactly (read first): `Plant` protocol, Canvas drawing, bend curves stem tip + leans bloom, state `color` tints stem/petals.
- SVG geometry per flower is in the design board (already extracted this session): orchid = top petal + 2 side petals + labellum + gold throat (#B27BC4/#A96FBD/#8E4FA6); hibiscus = 5 rotated red ellipses (#D24B43) + long stamen (#E4A93D); jasmine = 5 white petals (#FBF7EF, stroke #e7ddc9) + gold center; sampaguita = two white clusters (4-petal + 3-petal) on one stem; lotus = layered pink petals (#E58AA8/#D26E90) + gold center.
- Petal colors stay species-true; ONLY stem/leaf tint follows posture `color` (sage→clay→terracotta), matching how board wilts recolor stems.
- New file per plant in `Sources/DesignSystem/Plants/`. Shared `PlantPot.swift` helper (draw(in:rect:)) used by new plants; leave Sunflower/Monstera untouched this leaf.

## Changes
1. New `Sources/DesignSystem/Plants/PlantPot.swift`.
2. New plant files: `VandaOrchid.swift`, `Hibiscus.swift`, `MelatiJasmine.swift`, `Sampaguita.swift`, `Lotus.swift`.
3. `Sources/DesignSystem/Plants/PlantMascot.swift`: add `PlantKind` cases `.vandaOrchid, .hibiscus, .melatiJasmine, .sampaguita, .lotus` with labels + region strings (add `var region: String?`), register in switch.

## Verification
- `xcodebuild build -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`
- `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`

## Done
- 5 new kinds selectable via `PlantKind.allCases`, render potted, bend animates; builds + tests green.
