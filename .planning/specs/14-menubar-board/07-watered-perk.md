# Task: Watered mood — perk-up on water log

## Objective
Logging water makes the mascot visibly perk: bend eases to 0 and brief droplet/sparkle accents show for ~2 s (board mood 4, "hydrate → it perks up"), in NowView hero and menu-bar popover.

## Context
- Design board section 04 mood strip: watered = upright pose + teal droplets (#4F8A7B) around bloom.
- `AppModel.liveBend` feeds both heroes. Add `wateredUntil: Date?` on AppModel; `noteWaterLogged()` sets `.now + 2`; `liveBend` returns 0 while active (animation spring already tweens); heroes overlay droplets while active.
- Water log entry points: NowView water chip, popover "+ Glass", notification action. Notification action writes SwiftData directly from NotificationModule — observing every path via AppModel call is only wired where AppModel reachable (NowView + popover); notification path skips perk (acceptable, app likely backgrounded).

## Changes
1. `Sources/App/AppModel.swift`: `wateredUntil` + `noteWaterLogged()` + bend override.
2. Water log call sites in `Sources/Views/NowView.swift` + `Sources/Views/MenuBarPopoverView.swift`: call `noteWaterLogged()`.
3. Droplet overlay (small `WaterPerkOverlay` view, DesignSystem) applied over PlantMascot in both heroes, visible only while active.

## Verification
- `xcodebuild build -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`
- `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`

## Done
- + Glass → plant straightens + droplets flash ~2 s in both surfaces; builds + tests green.
