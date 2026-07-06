# Task: Soft-alert engine — chime on sustained drift + quiet hours

## Objective
Level-2 alert: soft chime plays (default output → AirPods) after sustained drift-or-worse ≥ `nudgeAfterDriftMin` (default 2 min), cooldown 5 min, gated by master `softAlertsEnabled`, `chimeOnSustainedDrift`, and quiet hours. Quiet hours also gate the Level-3 banner and water/walk notifications.

## Context
- Design board section 03 (Locked): L1 glyph dot (leaf 01, always on), L2 chime on sustained drift, L3 banner opt-in (`escalateLongSlouches`, existing 6-min path stays). Quiet hours default 22:00–08:00 on. "Respect Focus & DND" toggle: UNNotifications already respect Focus; no public macOS API to gate NSSound — omit toggle, logged in QUESTIONS.md.
- `Sources/Reminders/ReminderScheduler.swift`: pattern to follow = `checkPostureAlert`. Chime tracks `postureState != .aligned` sustained start.
- Chime playback: `NSSound(named: "Glass")` (macOS system sound, soft) behind seam closure so tests inject a spy; `#if os(macOS)` in NotificationModule.

## Changes
1. `Sources/Models/UserSettings.swift`: add inline-defaulted fields `chimeOnSustainedDrift: Bool = true`, `nudgeAfterDriftMin: Double = 2.0`, `quietHoursEnabled: Bool = true`, `quietHoursStartMinutes: Int = 1320`, `quietHoursEndMinutes: Int = 480`; extend `reset()`.
2. `Sources/Reminders/ReminderScheduler.swift`: add `playChime` closure seam (default → `NotificationModule.shared.playChime()`); `checkChime(_ state:)` — sustained non-aligned ≥ nudge minutes, 5-min cooldown, reset on aligned; `isQuietNow()` helper (minutes-of-day window, handles overnight wrap); gate chime AND `fire()` calls (posture/water/walk) on quiet hours + posture banner additionally on `softAlertsEnabled`.
3. `Sources/Notifications/NotificationModule.swift`: `func playChime()` — `#if os(macOS)` `NSSound(named: "Glass")?.play()`.
4. `Tests/ReminderTests/ReminderSchedulerTests.swift`: new tests — chime fires after 2 min sustained drift; not before; cooldown respected; aligned resets; `softAlertsEnabled=false` silences; quiet-hours window (incl. overnight wrap 22:00→08:00) silences chime and banner.

## Verification
- `xcodebuild test -project Synthesis.xcodeproj -scheme SynthesisMac -quiet` — all green incl. new tests.

## Done
- Tests prove chime timing/gates; existing banner/water/walk behavior unchanged outside quiet hours; builds green.
