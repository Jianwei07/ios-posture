# Synthesis

[![CI](https://github.com/Jianwei07/ios-posture/actions/workflows/swift.yml/badge.svg)](https://github.com/Jianwei07/ios-posture/actions/workflows/swift.yml)
[![Release](https://img.shields.io/github/v/release/Jianwei07/ios-posture)](https://github.com/Jianwei07/ios-posture/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

App for office workers to live well. Uses **AirPods Pro** motion sensors to detect bad head
posture in real time and nudge you to fix it — plus interval water reminders, walk reminders,
and daylight-aware sunlight nudges. Fully local, no account, no backend.

> Software engineers wear AirPods for hours. Those AirPods have a 9-axis IMU. Use what's already
> in your ears to catch slouching — no new hardware.

## Status

**Phase 1 (in progress):** AirPods posture detection + session lifecycle, water reminder, session history.
**Phase 2 (planned):** HealthKit logging, step-aware walk reminders, Apple Watch companion.

## Install (macOS)

The macOS menu-bar app installs via Homebrew:

```bash
brew install --cask jianwei07/synthesis/synthesis
```

Or grab `Synthesis-<version>.zip` from the [latest release](https://github.com/Jianwei07/ios-posture/releases/latest) and drag `Synthesis.app` into Applications.

> **First launch:** builds are open source and not notarized (no paid Apple
> Developer account), so macOS blocks the first launch. Allow it under
> **System Settings → Privacy & Security → Open Anyway**, or install with
> `brew install --cask --no-quarantine jianwei07/synthesis/synthesis`.

The iOS app is build-from-source only for now (see [Build](#build)).

## How it works

- `CMHeadphoneMotionManager` streams head pitch/roll/yaw from AirPods Pro (2nd gen+)
- A 5-second calibration captures your neutral head position at session start
- Pitch is low-pass filtered, then classified against your neutral: **aligned / drift / slouch**
- Sustained slouch fires a local notification + in-app banner
- Removing AirPods pauses the session; reinserting recalibrates and resumes
- Session clock counts only AirPods-in time (not wall clock)

## Requirements

- **AirPods Pro 2nd gen** (older AirPods lack the motion sensor API)
- Mac on **macOS 14+** (menu-bar app) or iPhone on **iOS 17+**
- Xcode 16 (to build)
- Posture features need a **real device** — the sensor API does not work in Simulator

## Build

This repo uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to scaffold the Xcode project once from `project.yml`:

```bash
brew install xcodegen
xcodegen generate
open Synthesis.xcodeproj
```

Then set your signing team in Xcode (target → Signing & Capabilities) and run on your iPhone with ⌘R. Unit tests run on Simulator with ⌘U.

## Architecture

```
PostureEngine/   IMU wrapper, low-pass filter, calibration, classifier
Session/         state machine + session clock
Models/          SwiftData: PostureSession, PostureReading, UserSettings
Reminders/       posture alert + interval water reminder
Notifications/   local notifications + in-app overlay
Views/           SwiftUI: Now, Trends, Settings, Onboarding, Calibrate, Disconnected
```

Zero external runtime dependencies — pure Apple frameworks (SwiftUI, SwiftData, CoreMotion, UserNotifications).

## Privacy

Everything stays on your device. No account, no backend, no analytics, no tracking.
Posture data is stored locally (SwiftData) and downsampled. It exists only to power
future on-device wellness insights — it never leaves your phone.

## Prior art

- [workwell](https://github.com/wizenheimer/workwell) — demonstrated AirPods-based posture tracking.
- [dorso](https://github.com/tldev/dorso) — AirPods connectivity pattern (CMHeadphoneMotionManager delegate).

## License

MIT
