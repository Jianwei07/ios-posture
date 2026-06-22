# Posture

Open-source iOS app that uses **AirPods Pro** motion sensors to detect bad head posture in real time and nudge you to fix it — plus interval water reminders. Fully local, no account, no backend.

> Software engineers wear AirPods for hours. Those AirPods have a 9-axis IMU. Use what's already in your ears to catch slouching — no new hardware.

## Status

**Phase 1 (in progress):** AirPods posture detection + session lifecycle, interval water reminder, session history.
**Phase 2 (planned):** HealthKit logging, step-aware walk reminders, Apple Watch companion.

## How it works

- `CMHeadphoneMotionManager` streams head pitch/roll/yaw from AirPods Pro (2nd gen+)
- A 3-second calibration captures your neutral head position at session start
- Pitch is low-pass filtered, then classified against your neutral: **good / warning / poor**
- Sustained poor posture (>30s) fires a local notification + in-app banner
- Removing AirPods pauses the session; reinserting recalibrates and resumes
- Session clock counts only AirPods-in time (not wall clock)

## Requirements

- **AirPods Pro 2nd gen** (older AirPods lack the motion sensor API)
- iPhone on **iOS 17+**
- Xcode 16 (to build)
- Posture features need a **real device** — the sensor API does not work in Simulator

## Build

This repo uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to scaffold the Xcode project once from `project.yml`:

```bash
brew install xcodegen
xcodegen generate
open Posture.xcodeproj
```

Then set your signing team in Xcode (target → Signing & Capabilities) and run on your iPhone with ⌘R. Unit tests run on Simulator with ⌘U.

## Architecture

```
PostureEngine/   IMU wrapper, low-pass filter, calibration, classifier
Session/         state machine + session clock
Models/          SwiftData: PostureSession, PostureReading, UserSettings
Reminders/       posture alert + interval water reminder
Notifications/   local notifications + in-app overlay
Views/           SwiftUI: session, history, settings
```

Zero external runtime dependencies — pure Apple frameworks (SwiftUI, SwiftData, CoreMotion, UserNotifications).

## Privacy

Everything stays on your device. No account, no backend, no analytics, no tracking.
Posture data is stored locally (SwiftData) and downsampled. It exists only to power
future on-device wellness insights — it never leaves your phone.

## Prior art

- [workwell](https://github.com/wizenheimer/workwell) — demonstrated AirPods-based posture tracking.
- [dorso](https://github.com/tldev/dorso) — AirPods connectivity pattern (CMHeadphoneMotionManager delegate).

This project is a fresh implementation with a stickman that mirrors your posture, simple
interval reminders (water + walk), and on-device session history.

## License

MIT
