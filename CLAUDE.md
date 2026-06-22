# CLAUDE.md

AirPods Pro IMU → real-time head posture detection → adaptive reminders. Fully local. No backend, no account.

**Phase 1:** posture detection + water reminder + UI. **Phase 2 deferred:** HealthKit, walk reminder.

## Build

**Real device required** — CMHeadphoneMotionManager fails in Simulator.

```bash
open Posture.xcodeproj
xcodebuild -scheme Posture -destination 'platform=iOS,name=<Device>' build
xcodebuild test -scheme Posture -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

```
PostureEngine/    ← MotionSource seam (real/sim) + filter + inline calibration + classifier
Session/          ← SessionManager: ONE 1Hz heartbeat (connect/pause/clock/record/remind), states idle/active/paused
Models/           ← SwiftData: PostureSession, PostureReading (downsampled), UserSettings, WaterEntry
Reminders/        ← ReminderScheduler: posture alert + water/walk intervals
Notifications/    ← UNNotification + in-app overlay
DesignSystem/     ← Theme (warm tokens), Stickman (procedural hand-drawn mascot)
Views/            ← SwiftUI: TodayView (hub), HabitCard, SettingsView
```

Data flow: `PostureEngine → SessionManager → ReminderScheduler → NotificationModule`.
Connectivity: `CMHeadphoneMotionManagerDelegate` (connect/disconnect push) + 1Hz availability/staleness check. NO separate watchdog/polling timers.

## Constraints

- AirPods Pro 2nd gen only (CMHeadphoneMotionManager)
- Pause fully on AirPods removal — no degraded mode
- Session clock = cumulative AirPods-in time, not wall clock
- iOS 17.0+ (SwiftData + `@Observable`)
- Zero external dependencies
- On-device only: no backend/analytics; posture data downsampled (~1/30s)

## Posture Detection

Primary signal: pitch (head tilt down) via AirPods IMU. Thresholds are constants in
`PostureClassifier`: poor >20°, warning >10°, forward head >15°. Low-pass filter α=0.15.

## Reminder Logic

```
postureAlert  → >30s continuous poor posture, 5min cooldown (constants in ReminderScheduler)
waterReminder → every UserSettings.baseWaterIntervalMin of active session time
walkReminder  → every UserSettings.baseWalkIntervalMin (simple interval, no HealthKit)
```

Settings expose only the two intervals. Walk needs no HealthKit — it's a plain interval nudge.

## Planning

Specs: `.planning/specs/<NN-branch>/specs.json`  
State: `.planning/STATE.md` | Root: `.planning/PROJECT.md`
