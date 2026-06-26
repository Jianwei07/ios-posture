# Task: Desktop UI and device QA

## Objective
Validate the macOS app with real AirPods and clean platform copy.

## Context
- User has A3047 AirPods Pro 2 USB-C.
- Simulator cannot read AirPods on either platform.
- First slice must prove CoreMotion stream, calibration countdown, and stable disconnect/reconnect.

## Changes
1. Replace iPhone-specific copy with Mac/desktop copy where shown in macOS target.
2. Replace “AirPods Pro only” copy with “compatible AirPods” unless a stricter claim is required.
3. Manually test Motion & Fitness permission, connect, calibrate, slouch, remove, and reinsert.
4. Record final macOS QA notes in `.planning/current/HANDOFF.md`.
5. Keep no-sample behavior safe: no fake baseline, no active timer, no flicker.

## Verification
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build`
- Manual A3047 AirPods QA checklist in `.planning/current/HANDOFF.md`.

## Done
- Real AirPods samples advance calibration on macOS.
- Removing AirPods produces one stable disconnected state.
- Reinsert resumes without UI flicker.
