# Task: Settings ▸ Alerts pane

## Objective
SettingsView gains an Alerts section matching the board: master soft-alerts toggle, which-alerts list (glyph pulse "always on" label, chime toggle, banner toggle), nudge-after-drift stepper, quiet hours toggle + time pickers. Sensitivity control stays where it is.

## Context
- Design board section 03 settings pane. Fields from leaves 02/03: `softAlertsEnabled`, `chimeOnSustainedDrift`, `nudgeAfterDriftMin`, `quietHoursEnabled`, `quietHoursStartMinutes/EndMinutes`, existing `escalateLongSlouches`.
- `Sources/Views/SettingsView.swift` — follow existing section/card idiom (read first; uses Theme tokens + CardStyle).
- Glyph dot row is informational (silent · always on) — no toggle.
- Stepper range 1–10 min, step 1. Quiet hours: two `DatePicker`s (hourAndMinute) mapped to minutes-of-day.

## Changes
1. `Sources/Views/SettingsView.swift`: add Alerts section per above; disable child rows when master off.
2. `Sources/App/AppModel.swift` `applySettings`: no engine change needed (scheduler reads settings live) — verify and leave note.

## Verification
- `xcodebuild build -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`
- `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet`

## Done
- All alert fields editable and persisted; children disabled when master off; builds + tests green.
