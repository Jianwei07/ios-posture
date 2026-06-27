# Handoff

## Current — 2026-06-26 macOS-first pivot plan

Direction Check: CONFIRMED
Chosen direction: macOS-first Synthesis app with compact desktop screens, shared posture engine, and AirPods stream-based detection.
Why: `.planning/PLATFORM-STRATEGY.md` confirms `CMHeadphoneMotionManager` on macOS 14+, and Dorso proves the production pattern.
Main risk: none open for first slice; real AirPods QA passed on A3047.
User confirmation needed: no

Grill Gate: SKIPPED_NOT_NEEDED
Reason: user chose macOS pivot, compact similar screens, and Dorso reference; no first-slice ambiguity changes the plan.

Spec Session: 12 | `.planning/specs/12-macos-first-pivot`
Quality Gates: READY
Check result: PASS
Spec Tree: READY
Execution gate: OPENED_FOR_APPROVED_EXECUTION
Reason: Leaves 01-05 executed and verified.
Next: PR to main | stop

Verification:
- `python3 /Users/jayden77/.claude/skills/jayden-workflow/scripts/validate_specs.py /Users/jayden77/dev/ios-posture` -> spec tree valid
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS Simulator' build` -> BUILD SUCCEEDED
- `xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'` -> TEST SUCCEEDED, 15 tests
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` -> BUILD SUCCEEDED
- `xcodegen generate` -> generated project
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build` -> BUILD SUCCEEDED
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` -> BUILD SUCCEEDED after compact macOS shell

Archived legacy specs: `.planning/specs-legacy-20260626/`
Skills used: jayden-workflow, gsd-lite-plan, gsd-lite-check, diagnose

## macOS AirPods QA checklist — passed

- [x] Launch `SynthesisMac`; menu bar item appears.
- [x] Open compact window from menu bar.
- [x] Wear A3047 AirPods Pro 2 USB-C; app reaches connected state without flicker.
- [x] Start calibration; real samples advance countdown.
- [x] Finish calibration; no fake baseline saved if samples absent.
- [x] Slouch changes live posture state.
- [x] Remove AirPods for 5s; app shows one stable disconnected state.
- [x] Reinsert AirPods; app resumes without start/pause loop.
- [x] Recalibrate from menu bar opens app and presents calibration.

## Where we are (2026-06-21, end of session)

Phase 1 engine WORKING. UI done. Mascot iterated twice and now uses SF Symbol.
Ready to continue next session — no loose ends, no broken build.

## Completed phases

### PHASE 1.6 — Simplify & Consolidate (DONE)
- Delegate-based AirPods connectivity (CMHeadphoneMotionManagerDelegate push, pattern from dorso)
- ONE 1Hz heartbeat in SessionManager (connect/pause/clock/downsample/reminders)
- Inlined CalibrationStore → PostureEngine (deleted file)
- SessionState → idle/active/paused (3 states only)
- Minimal settings: thresholds = constants in PostureClassifier; UserSettings = water+walk intervals
- Walk reminder = simple interval (no HealthKit); Walk card unlocked
- Downsampled posture readings (1/30s) + accumulators for score
- Removed HistoryView (data still collected silently for future AI/ML)
- Tabs = Today + Settings only
- 1473 → 1261 lines while ADDING walk reminder + delegate connectivity
- BUILD SUCCEEDED, 8/8 tests green, verified on simulator

### PHASE 1.7 — Seated Mascot procedural (DONE, then superseded by 1.8)
- Replaced standing front-view stickman with side-profile seated figure (Canvas/Path)
- Bigger head, lower body fixed, upper body mirrors pitch via spine curve
- SUPERSEDED: user found stick lines look unnatural regardless of proportions

### PHASE 1.8 — SF Symbol Mascot (DONE — current state)
- Replaced all 175 lines of Canvas/Path drawing with ~45-line SwiftUI Image view
- `figure.stand` SF Symbol + `rotationEffect(.degrees(18 * slouch), anchor: .init(x:0.5, y:0.76))`
- Pivots at hip — upper body leans forward as pitch drops, springs back when upright
- Breathing: `scaleEffect(1.013)` 4.5s ease-in-out loop
- Resting: 38% opacity + "z  z" text overlay
- `Theme.Motion.mascot` spring drives pitch-tracking animation
- BUILD SUCCEEDED, 8/8 tests green, screenshot confirmed

## Current file state (key files)

| File | Status |
|------|--------|
| Sources/DesignSystem/Stickman.swift | SF Symbol + tilt (45 lines) |
| Sources/DesignSystem/Theme.swift | Warm tokens, springs, font helpers |
| Sources/Views/TodayView.swift | Hub: greeting, mascot hero, habit cards, debug panel |
| Sources/Views/HabitCard.swift | Ring + metric module |
| Sources/Views/SettingsView.swift | 2 sliders (water + walk intervals) |
| Sources/App/ContentView.swift | Today + Settings tabs |
| Sources/PostureEngine/PostureEngine.swift | MotionSource seam + delegate + filter + calibration |
| Sources/Session/SessionManager.swift | 1Hz heartbeat, 3-state machine |
| Sources/Reminders/ReminderScheduler.swift | Posture alert + water + walk interval checks |
| Sources/Notifications/NotificationModule.swift | UNNotification + in-app overlay |
| Sources/Models/* | PostureSession, PostureReading, UserSettings, WaterEntry |

## Next session priorities

1. **Real-device pass** — re-set signing Team in Xcode (xcodegen regen wiped it). Build to iPhone, confirm AirPods delegate connectivity fires (Motion & Fitness + Notifications prompts → Allow). The delegate path (didConnect/didDisconnect) has never been tested on device.

2. **Mascot tilt feel** — on device, try slouching to see if 18° tilt reads clearly. May need to increase to 22-25° or adjust anchor. Also check if `figure.stand` looks good at the 260pt frame height on a real device display.

3. **Slouch sensitivity tune** — `StickmanMapping.slouch()` divides by 28. May need tuning once tested with real AirPods pitch range.

4. **Phase 2 backlog** — HealthKit step-aware walk, Apple Watch, AI/ML on-device report from collected downsampled PostureReading data.

## Architecture invariants (don't break)
- ONE heartbeat timer in SessionManager (no additional timers anywhere)
- AirPods connectivity = delegate push + 1Hz staleness backstop (no polling)
- Session clock = cumulative AirPods-in time (not wall clock)
- PostureReading downsampled 1/30s (not per-second)
- StickmanView API: `(slouch: Double, resting: Bool, ink: Color)` — TodayView must not change when mascot changes

## Skills used this project
grilling, jayden-workflow, design-taste-frontend, ponytail-audit

## Open Issues From Mobile QA

1. AirPods detection was skipped on mobile
- Real-device onboarding allowed the user past AirPods detection too easily.
- Expected: only proceed with posture setup after actual AirPods motion stream is detected.
- If user intentionally skips, button copy should be explicit: "Skip Posture Check".

2. Permissions are forced accepted
- Current permissions UI marks required permissions as accepted.
- Expected: user can uncheck/check permissions.
- Hit target must be the full permission row/button, not only the small circle.

3. Hold-still calibration did not count down
- App asked user to stay still, but countdown never started.
- Likely causes: AirPods not actually streaming, axis/confidence issue, or calibration never receives enough samples.
- Expected: if AirPods are not in / no motion stream / low confidence, do not infer baseline.
- Consider posture adjustment guidance during calibration: "go left", "go right", "raise head", etc., if axis confidence needs balancing.
- Add "Skip Posture Check" below "Hold Still" to skip to dashboard without saving a fake baseline.
- Accuracy rule: never save fallback/currentPitch/0 as baseline.
