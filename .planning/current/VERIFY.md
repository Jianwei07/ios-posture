# Verify

## 2026-06-26 — Leaf 01 Fix AirPods stream truth

Verdict: PASS

Must-haves:
- Capability and stream truth are separate: `MotionSource.isAvailable` remains capability, `MotionSource.isConnected` is connected/streaming state.
- AirPods connection monitoring is started via `CMHeadphoneMotionManager.startConnectionStatusUpdates()` from `SessionManager.begin()`.
- Delegate connect/disconnect and first real motion sample update stream truth in `HeadphoneMotionSource`.
- UI connection state uses `engine.isHeadphoneMotionConnected`, not capability.
- Session auto-start uses connected/streaming truth, preventing capability-only start/pause loops.
- Regression exists: `sessionDoesNotStartFromCapabilityOnly()` covers capability true plus no stream.

Checks:
- `xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'` -> TEST SUCCEEDED, 15 tests

Manual gap:
- Real A3047 AirPods QA still required; simulator cannot prove CoreMotion headphone samples.

## 2026-06-26 — Leaf 02 Add platform adapters

Verdict: PASS

Must-haves:
- `StepReader` compiles as HealthKit-backed on iOS and no-op on macOS via `#if os(iOS)`.
- `DisconnectedView.openSettings()` guards `UIApplication` behind `#if os(iOS)`.
- No new dependency, Bluetooth fallback, camera fallback, or package extraction added.
- iOS build remains green before adding the macOS target.

Checks:
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` -> BUILD SUCCEEDED
- `xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'` -> TEST SUCCEEDED, 15 tests
- `python3 /Users/jayden77/.claude/skills/jayden-workflow/scripts/validate_specs.py /Users/jayden77/dev/ios-posture` -> spec tree valid

Manual gap:
- macOS build waits for leaf 03, because `SynthesisMac` target does not exist yet.
