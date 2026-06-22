# Handoff

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
