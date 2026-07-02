# Task: Plumbing + bug fixes

## Objective
Close mechanical gaps found in macOS-pivot review: missing mac Info.plist keys, no mac test target, a cross-thread race in calibration, a timezone bug in sunlight math, dead code, duplicated card styling, and uncancellable timers.

## Context
- Repo is XcodeGen-managed (`project.yml` → `xcodegen generate`); never hand-edit `Synthesis.xcodeproj/project.pbxproj` directly.
- `SynthesisMac` target has `GENERATE_INFOPLIST_FILE: YES` with no usage-description keys — `CMHeadphoneMotionManager` on macOS 14 needs `NSMotionUsageDescription` or motion access silently fails.
- `SynthesisTests` is iOS-only (`platform: iOS`). `SynthesisMac`'s `PRODUCT_NAME` is `Synthesis`, so its module is also `Synthesis` — existing `@testable import Synthesis` test files compile unchanged against a new mac test target.
- `Sources/PostureEngine/PostureEngine.swift:145-167` — `process(pitch:)` runs on the motion `OperationQueue` and mutates `calibrationSamples`/`neutralPitch`/`isCalibrating` there, while `recalibrate()`/`cancelCalibration()` mutate the same state from main. Cross-thread, no sync.
- `Sources/Sunlight/SolarCalculator.swift:88-99` — sunrise/sunset computed as UTC minutes-of-day but added to *local* `startOfDay` → wrong nudge times outside UTC. `#if os(macOS)` also hardcodes San Francisco coords instead of using CoreLocation (which works fine on native macOS 10.15+). Force-unwraps `coord!` at :61-63. `asyncAfter` timeout (:37) can race the CLLocation delegate callback across threads.
- Dead code: `Sources/DesignSystem/SpineIcon.swift` (1-line tombstone), `WaterGoal` enum in `Sources/Models/WaterLog.swift:16-18` (unused, duplicates `UserSettings.dailyWaterTargetMl`), `NudgeStyle` (enum + `nudgeStyleRaw` field + `SettingsView` picker) — stored setting, never read anywhere.
- Card/chip background+stroke styling copy-pasted ~15× across `NowView.swift`, `TrendsView.swift`, `SettingsView.swift`.
- `NowView.swift:189` fire-and-forget `asyncAfter` banner dismiss; `CalibrateView.swift:106` raw `Timer` for a 10s timeout — both uncancellable against view lifecycle.
- `SynthesisApp.swift:15-19` — macOS window fixed at `.frame(width: 440, height: 720)`.

## Changes
1. `project.yml`: add to `SynthesisMac.settings.base` — `INFOPLIST_KEY_NSMotionUsageDescription`, `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` (copy iOS Info.plist strings). Add `SynthesisMacTests` target (`type: bundle.unit-test`, `platform: macOS`, `deploymentTarget: "14.0"`, `sources: [Tests]`, `dependencies: [{target: SynthesisMac}]`) and an explicit `SynthesisMac` scheme with build+test actions. Run `xcodegen generate`.
2. `PostureEngine.swift`: keep only `pitchFilter.filter(rawPitch)` on the motion queue; move calibration accumulation, `classifier.classify`, and all published-property writes inside the existing `DispatchQueue.main.async` hop. Extract the calibration-sample accumulation into a synchronous `ingest(smoothPitch:)` helper method so it stays unit-testable without threading.
3. `SolarCalculator.swift`: build the UTC anchor with a UTC-timezone `Calendar` before adding minute offsets; remove the macOS-only SF early-return (let `requestLocation()` run on macOS, keep the SF result only as the existing timeout fallback); replace `coord!` force-unwraps with `if let`; route delegate `finish` calls through `DispatchQueue.main.async` so the timeout and the delegate callback never touch `continuation` from different threads; add `now:`/`timeZone:` parameters to `computeFor` for deterministic tests.
4. Delete `SpineIcon.swift` and `WaterGoal`. Remove `NudgeStyle` entirely: enum, `nudgeStyleRaw` field + computed accessor + `reset()` reference in `UserSettings.swift`, and the "Nudge style" section in `SettingsView.swift`. Run `xcodegen generate` again (source list changed).
5. Add `Sources/DesignSystem/CardStyle.swift`: `.card(padding:)` View extension matching the existing `.pressable()` pattern (`Theme.Palette.surface` background + `Theme.Radius` corner + `Theme.Palette.ink.opacity(0.06)` stroke overlay). Replace the copy-pasted sites in NowView/TrendsView/SettingsView; leave sites with non-conforming padding as-is rather than over-parameterizing.
6. `NowView.swift`: replace the banner `asyncAfter` with a stored, cancellable `Task` (cancel-and-replace per flash). `CalibrateView.swift`: replace the raw `Timer` with the same `Task` pattern; cancel in `onDisappear`.
7. `SynthesisApp.swift`: replace the fixed window frame with `.frame(minWidth: 400, idealWidth: 440, maxWidth: 600, minHeight: 640, idealHeight: 720, maxHeight: .infinity)`, keep `.windowResizability(.contentSize)`.

## Verification
- `xcodegen generate && git diff --stat Synthesis.xcodeproj` (only expected churn)
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac build`
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` (iOS stays green)
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac test` (native, no simulator)
- `plutil -p <built SynthesisMac.app>/Contents/Info.plist | grep -i motion` confirms the usage string is present

## Done
- Mac target has motion + location usage strings; app can request AirPods motion access without silent failure.
- Native `SynthesisMacTests` target exists and runs the existing Swift Testing suite unchanged.
- Calibration state is single-owner (main thread); no cross-thread mutation.
- Sunlight times correct outside UTC; macOS uses real location, not hardcoded SF, except as timeout fallback.
- No dead code (`SpineIcon`, `WaterGoal`, `NudgeStyle`) remains.
- Card styling centralized in one modifier.
- Banner and calibration timeout are cancellable `Task`s, not raw `Timer`/`asyncAfter`.
- macOS window resizable within sane min/max bounds.
