# State

## Current: macOS polish round (spec session 13) — executing

## Status: Session 12 (macOS-first pivot) DONE, all 5 leaves verified. Session 13 (polish) spec tree written, leaves 01-03 execution gate open (Sonnet), leaf 04 (plant redesign) reserved closed for Fable.

## Next
- Execute `.planning/specs/13-macos-polish/01-plumbing-and-bug-fixes.md`
- Execute `.planning/specs/13-macos-polish/02-notification-tiering-and-reminders.md`
- Execute `.planning/specs/13-macos-polish/03-appmodel-lift-and-menubar-icon.md`
- Commit + push after each verified leaf
- Hand `.planning/specs/13-macos-polish/04-plant-redesign.md` to Fable session

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
