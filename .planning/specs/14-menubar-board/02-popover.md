# Task: Menu-bar popover — 318 pt Sage window

## Objective
Clicking the glyph opens a window-style MenuBarExtra, 318 pt wide, Sage card background: header (Posture + AirPods pill + gear), stateful hero (plant + state word + stat), water/walk cards, soft-alerts row, footer Recalibrate | Open app | Quit.

## Context
- Design board section 02 (Locked). Surface: window-style MenuBarExtra (SwiftUI equivalent of transient NSPopover). 318 pt wide, height hugs content, card #F4F2EC (`Theme.Palette.bg`), inner cards `Theme.Palette.surface`.
- Replace menu-style content in `Sources/App/SynthesisApp.swift` with `.menuBarExtraStyle(.window)`.
- Hero copy: aligned → "Aligned" (#5F9A78) / "Standing tall — nice." / "N min upright today"; drift → "Easing forward" (#CC8A5A) / "Gently sit tall." / "−X° · M min"; wilt → "Wilting" (#B05A38) / "Time to reset & water." / "−X° · M min"; idle → ink "Not tracking" / connection hint.
- Data: `AppModel` (`menuBarState`, `isConnected`, `liveBend`, `session.activeSessionSeconds`, `engine.forwardAngle`), plant kind from `UserSettings.selectedPlant`, water via SwiftData `WaterEntry` (glass = 250 ml, target `dailyWaterTargetMl`), walk = interval countdown (no macOS steps).
- Drift/wilt duration: expose from `MenuBarReducer`/`AppModel` (reducer already tracks `slouchSince`; add `private(set)` accessor surfaced through reduce result or AppModel property).
- Soft-alerts segmented Gentle | Off binds `UserSettings.softAlertsEnabled`. That field is created in THIS leaf (inline default `true`); leaf 03 adds the remaining alert fields.
- Walk countdown: add `ReminderScheduler.minutesUntilWalk(sessionSeconds:)` (compute from `lastWalkReminderAt` + `baseWalkIntervalMin`).

## Changes
1. `Sources/Models/UserSettings.swift`: add `var softAlertsEnabled: Bool = true` (inline default — lightweight migration) + `reset()`.
2. `Sources/Reminders/ReminderScheduler.swift`: add `minutesUntilWalk(sessionSeconds:) -> Int`.
3. New `Sources/Views/MenuBarPopoverView.swift` (macOS-only): header row, hero card (PlantMascot 58×76, `liveBend`, state color), water card (ring = todayMl/target, count "n / N" glasses, "+ Glass" button inserts `WaterEntry(volumeMl: 250)`), walk card (ring = elapsed/interval fraction, "Next in Xm"), soft-alerts row (Gentle/Off segmented), footer (Recalibrate posts `.recalibrateRequested` + `openWindow(id:"main")`; Open app; Quit `NSApplication.shared.terminate`). Fixed `.frame(width: 318)`.
4. `Sources/App/SynthesisApp.swift`: MenuBarExtra content = `MenuBarPopoverView()`, add `.menuBarExtraStyle(.window)`.
5. `Sources/App/AppModel.swift`: expose slouch/drift elapsed minutes for hero stat.

## Verification
- `xcodebuild build -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`
- `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`

## Done
- Popover opens as 318 pt window with all five zones; + Glass increments water ring immediately; footer actions work; builds + tests green.

## Check note (WaterEntry model name)
- Repo has `Sources/Models/WaterLog.swift` — confirm model type name (`WaterEntry` per SynthesisApp container) before coding.
