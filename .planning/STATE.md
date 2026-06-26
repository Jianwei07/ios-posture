# State

## Current: macOS-first pivot planned

## Status: Spec session 12 drafted. Execution gate closed. Legacy specs preserved in `.planning/specs-legacy-20260626/`.

## Next
- Review/approve `.planning/specs/12-macos-first-pivot/`.
- Execute only after explicit execution command.
- First implementation leaf fixes AirPods stream truth before adding macOS target.

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
