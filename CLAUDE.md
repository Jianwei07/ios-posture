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
PostureEngine/    ← IMU wrapper, low-pass filter, calibration, classifier
Session/          ← State machine (idle→calibrating→active→paused→ended), session clock
Models/           ← SwiftData: PostureSession, PostureReading, UserSettings
Reminders/        ← ReminderScheduler: posture alert + water interval
Notifications/    ← UNNotification + in-app overlay
Views/            ← SwiftUI: SessionActiveView, HistoryView, SettingsView
```

Data flow: `PostureEngine → SessionManager → ReminderScheduler → NotificationModule`

## Constraints

- AirPods Pro 2nd gen only (CMHeadphoneMotionManager)
- Pause fully on AirPods removal — no degraded mode
- Session clock = cumulative AirPods-in time, not wall clock
- iOS 17.0+ (SwiftData + `@Observable`)
- Zero external dependencies

## Posture Detection

Primary signal: pitch (head tilt down) via AirPods IMU.  
Thresholds in `UserSettings`: poor >20°, warning >10°, forward head >15°.  
Low-pass filter α=0.15 on raw IMU.

## Reminder Logic (Phase 1)

```
postureAlert   → >30s continuous poor posture, 5min cooldown
waterReminder  → every baseWaterIntervalMin of active session time (default 30min)
```

Water = pure interval, settings-driven. Posture-quality adaptation + walk reminder → Phase 2.

## Planning

Specs: `.planning/specs/<NN-branch>/specs.json`  
State: `.planning/STATE.md` | Root: `.planning/PROJECT.md`
