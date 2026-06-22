# State

## Current: PHASE 1.9 PLANT MASCOT — DONE

## Status: Build green, 8/8 tests pass, simulator verified (upright + wilt). Ready for real-device pass next session.

## Verified
- [x] BUILD SUCCEEDED (sim)
- [x] 8/8 unit tests green
- [x] Plant renders: terracotta pot + rim + soil, tapered green stem, 3 leaves
- [x] Upright (pitch 0) = tall green sprout; wilt (pitch -32) = stem droops forward + foliage warms sage→clay (verified via temp sim pitch, reverted)
- [x] Filled tapered Paths (not strokes) — fixes the "wireframe" cheapness of prior attempts
- [x] Gentle sway (±1.6° at pot base, 4.5s loop), Reduced-Motion aware
- [x] StickmanView/StickmanPose/StickmanMapping names + filename kept — TodayView + .xcodeproj untouched, no xcodegen rerun

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
