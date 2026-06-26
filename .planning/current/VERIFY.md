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

## 2026-06-26 — Leaf 03 Add macOS target

Verdict: PASS

Must-haves:
- `project.yml` defines `SynthesisMac` as a macOS 14.0 app target.
- macOS target uses generated Info.plist and does not attach iOS HealthKit entitlements/framework.
- iOS target keeps HealthKit entitlement/framework and restored `DEVELOPMENT_TEAM` after XcodeGen regeneration.
- `SynthesisMac` is buildable from the generated project.
- iOS `Synthesis` remains buildable from the generated project.

Checks:
- `xcodegen generate` -> generated project
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build` -> BUILD SUCCEEDED
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` -> BUILD SUCCEEDED
- `xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'` -> TEST SUCCEEDED, 15 tests

Notes:
- Added minimal macOS compile guards for `navigationBarTitleDisplayMode` and sunlight location fallback.
- Compact macOS-specific shell remains leaf 04.

## 2026-06-26 — Leaf 04 Add compact macOS shell

Verdict: PASS

Must-haves:
- macOS app creates compact main window: `WindowGroup(id: "main")`, fixed `440x720`, `.windowResizability(.contentSize)`.
- macOS app has `MenuBarExtra` with Open App, Recalibrate, Quit.
- Recalibrate menu action opens main window and presents existing `CalibrateView`.
- iOS `WindowGroup` path unchanged behind `#else`.

Checks:
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build` -> BUILD SUCCEEDED
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` -> BUILD SUCCEEDED

Manual gap:
- Menu bar item visual/open behavior still needs manual launch check.

## 2026-06-26 — Leaf 05 Desktop UI and device QA

Verdict: UNCERTAIN

Done:
- Replaced stricter AirPods Pro copy with compatible AirPods copy where user-facing.
- Replaced phone copy with device copy.
- Added macOS Bluetooth settings open path.
- Added manual A3047 QA checklist to `HANDOFF.md`.

Checks pending:
- Real A3047 AirPods QA. Required for PASS.

Checks passed:
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build` -> BUILD SUCCEEDED
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` -> BUILD SUCCEEDED
