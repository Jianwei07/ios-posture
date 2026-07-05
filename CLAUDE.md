# CLAUDE.md

Synthesis — app for office workers to live well. AirPods Pro IMU → real-time head
posture detection → gentle nudges + water + walk + sunlight. Fully local. No backend, no account.

Design: **Sage** system — see `design.md` (sourced from Claude Design project "Posture IOS").
Three live states: **aligned → drift → slouch**. Tabs: **Now · Trends · Settings**.

**Phase 1:** posture engine + onboarding + Now/Trends/Settings + escalation banner.
**Phase 2 deferred:** HealthKit steps (walk chip), Dynamic Island Live Activity quiet nudge (needs an ActivityKit widget-extension target).

## Build

**Real device required** — CMHeadphoneMotionManager fails in Simulator.

```bash
open Synthesis.xcodeproj
xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS,name=<Device>' build
xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Architecture

```
App/              ← SynthesisApp, ContentView (onboarding gate + tab shell + Disconnected overlay),
                     AppModel (owns engine+session+scheduler, shared across tabs via @Environment)
PostureEngine/    ← MotionSource seam (real/sim) + filter + calibration + classifier; PostureState = aligned/drift/slouch
Session/          ← SessionManager: ONE 1Hz heartbeat (connect/pause/clock/record/remind), states idle/active/paused
Models/           ← SwiftData: PostureSession, PostureReading (downsampled), UserSettings, WaterEntry
Reminders/        ← ReminderScheduler: escalation banner (sustained slouch) + water/walk intervals
Notifications/    ← UNNotification + in-app overlay
DesignSystem/     ← Theme (Sage tokens), Plants (procedural Canvas mascots, bend-driven: Sunflower/Monstera)
Views/            ← SwiftUI: NowView, TrendsView, SettingsView, OnboardingFlow, CalibrateView, DisconnectedView
```

Data flow: `PostureEngine → SessionManager → ReminderScheduler → NotificationModule`.
Connectivity: `CMHeadphoneMotionManagerDelegate` (connect/disconnect push) + 1Hz availability/staleness check. NO separate watchdog/polling timers.
SwiftData: new non-optional `@Model` fields MUST have inline defaults (lightweight migration). Do not delete/rename persisted fields without a migration plan; keep unused fields if local stores may exist.

## Constraints

- AirPods Pro 2nd gen only (CMHeadphoneMotionManager)
- Pause fully on AirPods removal — no degraded mode
- Session clock = cumulative AirPods-in time, not wall clock
- iOS 17.0+ (SwiftData + `@Observable`)
- Zero external dependencies
- On-device only: no backend/analytics; posture data downsampled (~1/30s)

## Posture Detection

`forwardAngle = neutral − filteredPitch` (deg below calibrated baseline). In `PostureClassifier`:
`angle < threshold` → aligned · `>= threshold` → drift · `>= threshold + slouchGap(6)` → slouch.
`threshold` = user sensitivity: Relaxed 22° / Balanced 15° / Strict 8° (`UserSettings.sensitivity`).
Baseline captured by 5s still hold (calibration), persisted in `UserSettings.baselinePitch`. Low-pass α=0.15.

## Reminder Logic

```
escalation banner → settings.escalateLongSlouches AND >=6min sustained slouch, 5min cooldown
waterReminder     → every UserSettings.baseWaterIntervalMin of active session time
walkReminder      → every UserSettings.baseWalkIntervalMin (simple interval, no HealthKit)
```

Quiet nudge (Dynamic Island + chime) is the DEFAULT in the design but NOT yet built — needs an
ActivityKit widget-extension target (Phase 2). Banner is the only implemented loud path.

## Planning

Specs: `.planning/specs/<NN-branch>/specs.json`
State: `.planning/STATE.md` | Root: `.planning/PROJECT.md`
