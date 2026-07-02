# State

## Current: macOS polish round (spec session 13) — leaves 01-03 DONE, leaf 04 reserved for Fable

## Status: Session 12 (macOS-first pivot) DONE, all 5 leaves verified. Session 13 leaves 01-03 executed, verified (mac build + iOS build + 32/32 native tests), and committed on `feat/macos-pivot`. Leaf 04 (plant redesign) untouched — reserved for a Fable session per user instruction.

## Next
- Push `feat/macos-pivot` to remote
- Hand `.planning/specs/13-macos-polish/04-plant-redesign.md` to a Fable session (Monstera/Cactus geometry — a taste call)
- Manual on-device QA still open: minimized-window menu bar glyph transitions, water notification "Log 250 ml" action end-to-end (see HANDOFF leaf 03/02 checkpoints)

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
