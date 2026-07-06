# Task: Flower roster B — 5 plants + picker grid

## Objective
Remaining five plants (Golden shower · Thailand, Dok Champa · Laos, Rumduol · Cambodia, Padauk · Myanmar, Rose · USA) + PlantPicker becomes a wrapping grid with region captions and selected checkmark, Sunflower first/default.

## Context
- Design board section 04 grid: card per plant, name + region caption, selected card sage tint + check badge. Monstera stays available but cosmetic-only per board — position last, caption "Cosmetic".
- Geometry from board: golden shower = drooping stem + yellow circle clusters (#EBB61F/#C68F0E); dok champa = 5 pinwheel white petals + large gold center (#F2D77E); rumduol = curved stem + 3 cream petals (#F0E4A8); padauk = cluster of gold circles (#F4C64A/#D9A21F); rose = layered red cup (#C4523F/#D06B57/#B8402F/#DA7660/#93301F) + sepals.
- `Sources/DesignSystem/PlantPicker.swift`: HStack → `LazyVGrid` 3 columns; card style per board.

## Changes
1. New plant files: `GoldenShower.swift`, `DokChampa.swift`, `Rumduol.swift`, `Padauk.swift`, `Rose.swift` in `Sources/DesignSystem/Plants/`.
2. `PlantMascot.swift`: add 5 kinds + regions, register.
3. `Sources/DesignSystem/PlantPicker.swift`: grid layout, region caption, check badge on selected.

## Verification
- `xcodebuild build -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`
- `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`

## Done
- 12 kinds total render in grid picker; selection persists via `UserSettings.selectedPlant`; builds + tests green.
