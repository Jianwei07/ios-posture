# State

## Current: Menubar design board (spec session 14) — COMPLETE, all 7 leaves done on `feat/macos-bar`

Glyph+state dot, 318pt window popover, chime+quiet hours, Settings▸Alerts pane, 10 national-flower mascots + grid picker, watered perk. Spec: `.planning/specs/14-menubar-board`. Source: Claude Design "Posture - macOS Menubar" board (locked).

Post-PR loop (2026-07-06): CI red fixed — hand-edited SynthesisMac.xcscheme diverged from xcodegen output; `productName: Synthesis` in project.yml now generates it correctly (never hand-edit Synthesis.xcodeproj). +20 tests for session-14 logic → 68/68 in 15 suites (walk countdown, liveBend, watered perk, MenuBarGlyph, UserSettings alert defaults). PR #5 CI green.

Next: on-device QA — glyph dot in light/dark bar, popover live data with real AirPods, chime audibility through AirPods, quiet-hours behavior overnight, new mascots' wilt feel with live bend.

## Previous: macOS polish round (spec session 13) — COMPLETE, all 4 leaves done

## Status: Session 13 all leaves + bug sweep done on `feat/macos-pivot`; PR #2 open to main (https://github.com/Jianwei07/ios-posture/pull/2). Bug sweep fixed: motion-source threading (off-main @Observable/SwiftData writes), session start flap (4s spin-up grace), sunlight nextNudge display, SolarCalculator continuation race.

## Next
- Manual on-device QA: menu bar glyph transitions (minimized, sustained slouch ≥30s), water notification "Log 250 ml" action end-to-end, plant pose animation feel with live bend stream
- Session 14 candidate: SynthesisCore SPM extraction for iOS relaunch (see plan's architecture direction)

## Previous: macOS-first pivot — DONE (session 12)

## Previous: PHASE 1.10 BASELINE ACCURACY — DONE

## Status: Build green, 13/13 tests pass. No fake/inferred baselines; calibration explicit + stability-gated. Monstera redrawn.

## Verified
- [x] BUILD SUCCEEDED (sim)
- [x] 13/13 unit tests green (4 new calibration tests)
- [x] Engine: no auto-calibrate on start(); only after recalibrate()
- [x] Engine: 4° spread gate rejects unstable holds
- [x] CalibrateView: no ?? currentPitch fallback; failure → Try Again
- [x] NowView: "Set your baseline" CTA when no baseline (not "Getting your baseline…")
- [x] Monstera: terracotta pot + rim + outline, 2 stems, 6 split leaves with notches + veins

## Phases done
- [x] 1.5 — Design system + Today hub (Theme, Stickman procedural, TodayView, HabitCard, WaterLog)
- [x] 1.6 — Simplify: delegate connectivity, 1 timer, 3 states, 2 settings, walk unlocked, history UI removed
- [x] 1.7 — Seated stickman procedural (superseded)
- [x] 1.8 — SF Symbol figure.stand (superseded — read as bathroom sign)
- [x] 1.9 — Plant mascot (current). User rejected all 3 literal-human attempts; picked living plant over abstract-spine/orb/Lottie.

## Next
- Real-device pass: re-set Xcode signing Team → build to iPhone → AirPods delegate test
- Tune plant wilt feel (lean 0.16, drop 0.22, sag 40°) once tested with real AirPods pitch
- Optional: nicer leaf placement / add a 4th leaf if it feels sparse
- Phase 2: HealthKit walk, Apple Watch, AI/ML reports
