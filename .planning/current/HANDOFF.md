# Handoff

## Current — 2026-07-02 macOS polish round

Direction Check: CONFIRMED
Chosen direction: harden macOS pivot (bug fixes, mac test target), tier reminders soft/priority with smart water-skip + presence-aware walk, add live menu-bar posture glyph as the minimized-state alert, redesign Monstera + Cactus. iOS-launch architecture direction recorded (SynthesisCore SPM extraction, thin adapters, deferred to session 14).
Why: user requested library/optimization pass + soft reminder logic + minimized posture alert + plant polish; 2 Explore agents + 1 Plan agent surfaced bugs (sunlight UTC timezone, calibration cross-thread race), dead code, missing mac Info.plist keys, and confirmed XcodeGen-managed project (no pbxproj hand-edits).
Main risk: leaf 04 (plant redesign) is a taste call, reserved for Fable to execute/review; leaves 01-03 are decision-complete and assigned to Sonnet.
User confirmation needed: no — execute command given ("Let sonnet execute 01-03, commit, push. for 04 we use fable").

Grill Gate: SKIPPED_NOT_NEEDED
Reason: 4-question AskUserQuestion round resolved all first-slice ambiguity (minimized alert mechanism, walk logic, water logic, fix scope) before planning.

Spec Session: 13 | `.planning/specs/13-macos-polish`
Quality Gates: READY
Check result: PASS (validate_specs.py: spec tree valid)
Spec Tree: READY
Execution gate: OPENED_FOR_APPROVED_EXECUTION — leaves 01-03 only. Leaf 04 stays closed for a Fable session.
Next: leaves 01-03 all done and committed. Push to remote, then hand leaf 04 to a Fable session.

Skills used: grilling (targeted AskUserQuestion, not full /grilling session — no first-slice ambiguity), jayden-workflow (this spec session).

### Leaf 01 checkpoint — DONE (2026-07-02)
- Fixed `PostureEngine` cross-thread calibration race: filter stays on motion queue, everything else (calibration accumulation, classify, published state) hops to main via extracted `ingest(smoothPitch:)`. Updated `PostureEngineCalibrationTests` to `async` + deterministic `drainMain()` helper (exploits serial FIFO main queue — no sleep).
- Fixed `SolarCalculator`: UTC-anchored sunrise/sunset (was local-startOfDay + UTC minutes → wrong outside UTC), removed macOS SF-hardcode (CoreLocation now runs on native macOS, gated on `.authorizedAlways` there vs `.authorizedWhenInUse` on iOS — `authorizedWhenInUse` is unavailable on macOS, caught by mac build), force-unwraps replaced, delegate `finish` calls routed through main to close the timeout race.
- Removed dead code: `SpineIcon.swift` (tombstone), `WaterGoal` enum, `NudgeStyle` (enum + field + SettingsView picker) end-to-end.
- Added `.card()` ViewModifier (`Sources/DesignSystem/CardStyle.swift`); replaced ~8 copy-paste sites across NowView/TrendsView/SettingsView (left 2 sites alone — banner's drift-colored border and emptyRow's dashed border are semantically different, not candidates).
- NowView banner + CalibrateView timeout: `asyncAfter`/raw `Timer` → cancellable `Task`.
- macOS window: fixed 440×720 → resizable (min 400×640, ideal 440×720, max 600×∞).
- `project.yml`: added `SynthesisMacTests` target + `SynthesisMac` scheme with test action; had to explicitly override `TEST_HOST`/`BUNDLE_LOADER` (auto-derived path assumed `SynthesisMac.app` but `PRODUCT_NAME` is overridden to `Synthesis`). Added mac `NSMotionUsageDescription`/`NSLocationWhenInUseUsageDescription`/`LSApplicationCategoryType` Info.plist keys — confirmed present in built app via `plutil`.

Verification: `xcodebuild -scheme SynthesisMac build` ✓, `xcodebuild -scheme Synthesis -destination 'generic/platform=iOS Simulator' build` ✓ (generic/platform=iOS fails on unrelated signing/provisioning, not code — pre-existing, unrelated to this leaf), `xcodebuild -scheme SynthesisMac test` ✓ 15/15 tests native (1.9s, no simulator).

### Leaf 02 checkpoint — DONE (2026-07-02)
- `NotificationModule` rewritten: `ReminderType.isPriority` (posture only) drives sound/interruptionLevel tiering (priority: `.default` sound + `.active`; soft: silent + `.passive`). Now `NSObject, UNUserNotificationCenterDelegate` — `configure(container:)` sets the delegate + registers a water category with a "Log 250 ml" `UNNotificationAction`, called from `SynthesisApp.init()` (must be launch-time, not deferred, or action taps from a terminated-app launch get dropped). `willPresent` checks `content.interruptionLevel == .active` directly (not fragile identifier-string parsing) to decide `[.banner,.sound]` vs `[.banner]`. `didReceive` inserts a `WaterEntry()` into the shared container's `mainContext` on the water-log action.
- `SynthesisApp` now builds one explicit `ModelContainer` in `init()` (was the `.modelContainer(for:)` convenience form) so `NotificationModule` and the UI observe the same store — this is a prerequisite for leaf 03's full AppModel lift, not a duplicate of it.
- `SunlightScheduler` routes through the shared `content(for:detail:)` builder instead of hand-building `UNMutableNotificationContent` with a hardcoded `.default` sound — sunlight nudges are soft now too.
- `ReminderScheduler` rewritten with injectable seams: `fire`/`cancelAll`/`now` closures (default to real `NotificationModule`/`Date()`) make it unit-testable without touching `UNUserNotificationCenter` or waiting real wall-clock minutes. Water: defers if `lastWaterLogAt()` (wired by `AppModel` via a `FetchDescriptor<WaterEntry>` against the shared context) is within the interval, skips if `waterProgress()` shows target met, else fires with progress-softened copy. Walk: dropped the dead HealthKit pace-check branch (always blind-fired on macOS anyway since `StepReader.todaySteps` is `#if os(iOS)`-gated to 0); added `noteBreakTaken(sessionSeconds:)`.
- `SessionManager`: tracks `pausedAt`; on resume after a ≥300s AirPods-out gap, calls `scheduler.noteBreakTaken()` (assumes the user walked during the break) before resuming. Removed the `stepReader` param and the dead `scheduler.currentStepCount` feed from `tickActive()`.
- `NowView` walk chip shows "—" on macOS instead of a misleading "0" (steps are structurally unavailable there, not zero).
- New `Tests/ReminderTests/ReminderSchedulerTests.swift` (11 tests) — water interval/defer/target-met, walk interval + `noteBreakTaken`, posture escalation/cooldown/interruption-reset/toggle-off, all via injected `fire`+`now` closures (no real notification center, no 6-minute sleeps).

Verification: `xcodebuild -scheme SynthesisMac build` ✓, `xcodebuild -scheme Synthesis -destination 'generic/platform=iOS Simulator' build` ✓, `xcodebuild -scheme SynthesisMac test` ✓ 26/26 tests native (0.02s). Manual water-notification-action → SwiftData → live chip update not verified end-to-end interactively in this session (no running app instance) — code path is structurally correct (shared container, `@MainActor` insert+save) and should be spot-checked with real AirPods/notifications before shipping.

### Leaf 03 checkpoint — DONE (2026-07-02)
- `AppModel` construction lifted from `ContentView`'s lazy `.task` into `SynthesisApp.init()`: builds the `ModelContainer` (from leaf 02), fetch-or-inserts the singleton `UserSettings` synchronously via `container.mainContext`, constructs `AppModel(settings:)` into `@State private var appModel`. Both the `WindowGroup` and `MenuBarExtra` scenes get `.environment(appModel)` + `.modelContainer(container)` as **Scene**-level modifiers (SwiftData/SwiftUI support this — confirmed by a clean build) — necessary because MenuBarExtra is a sibling scene, not a descendant view, so it couldn't see an `AppModel` built inside ContentView.
- `ContentView` now reads `@Environment(AppModel.self) private var app` (non-optional) instead of `@State private var app: AppModel?`; dropped the `setup()` settings-insert (moved to `SynthesisApp.init`) and all the `if let app` unwrapping. Also dropped now-redundant `.environment(app)` calls on `MainShell`/`OnboardingFlow`/`CalibrateView` — they already inherit it from the scene-level injection.
- New `Sources/App/MenuBarState.swift`: `MenuBarState` enum (idle/aligned/drift/wilt → SF Symbol per case) + pure `MenuBarReducer` struct (session+posture+wall-clock time → state, 30s slouch-sustain window — deliberately shorter than the 360s notification escalation since the glyph is an ambient early signal, not a duplicate alert). `SessionManager` gained `onHeartbeat: ((SessionState, PostureState) -> Void)?`, invoked at the end of the existing 1Hz `evaluate()` — no new timer. `AppModel.updateMenuBarState` only assigns `menuBarState` when the reducer's output actually changes, so the `@Observable` label re-renders on transitions only, not every heartbeat second.
- `MenuBarExtra` now shows `appModel.menuBarState.symbolName` as its icon and `appModel.menuBarStatusLine` in the dropdown ("Aligned · 32 min upright", etc.) — this is the "minimized" posture alert channel the user asked for: ambient, ties to a live SF Symbol, no sound/interruption. **Glyph mapping is a taste call, flagged for visual review**: idle→airpodspro, aligned→leaf.fill, drift→leaf, wilt→leaf.arrow.circlepath.
- New `Tests/AppTests/MenuBarStateTests.swift` (6 tests) — pure reducer tests: sub-threshold slouch stays drift, sustained (≥30s) becomes wilt, recovery is immediate, paused session forces idle, interruption resets the sustain clock, and a 40-tick sweep confirms exactly 2 state changes (no redundant re-publishes).

Verification: `xcodebuild -scheme SynthesisMac build` ✓, `xcodebuild -scheme Synthesis -destination 'generic/platform=iOS Simulator' build` ✓ (MenuBarExtra code stays inside the existing `#if os(macOS)` guard — iOS unaffected), `xcodebuild -scheme SynthesisMac test` ✓ 32/32 tests native. Manual on-device check (minimize window, sustain real slouch ≥30s, confirm glyph changes without any window visible) not performed this session — no real AirPods attached; flag for a hands-on pass before shipping.

### Leaf 04 checkpoint — DONE (2026-07-02, Fable session per plan)
- `Monstera.drawSplitLeaf` replaced by `drawLeaf`: blade built in unit space (base origin, tip (1,0)) from an 11-segment cubic-Bézier margin table (`upperMargin`) — base lobe, 3 deep in-and-back-out marginal splits per side (mirrored programmatically, reversed-cubic controls), taper to tip; zero straight segments. 4 elongated elliptical fenestration holes flank the midrib as subpaths in the same `Path`, rendered as true holes via `FillStyle(eoFill: true)`. Outline stroked from the blade path only (holes unstroked). Midrib is a quad curve whose sag control grows with bend (0.06 + 0.20·b). World placement via `CGAffineTransform` translate→rotate→scale.
- Progressive droop: leaf angle `stem.angle + off + b·(0.30 + 0.45·t)` — spec's example coefficients (0.45+0.55t) over-rotated at bend=1 (canopy clumped into a blob in the render sweep); tuned down after visual check.
- Depth: back stem (index 0) + its leaves draw first at 0.82 opacity with thinner stem/outline strokes; within each stem leaves draw base→tip.
- Fenestrations skipped when `size.width < 80` — PlantPicker thumbnails render plain split blades, no aliasing noise (confirmed at 64pt in the sweep).
- `Cactus`: body+arms+dome now rotate as one rigid piece about the pot-top anchor inside `ctx.drawLayer` (translate/rotate/translate-back, ~17° at b=1); `bodyX` lost its `b`-term. Pot unrotated. Arm sag unchanged, layers correctly on the lean.
- **Bonus animation fix (user: "for animation others")**: `Plant` protocol now extends `Animatable` with a default `animatableData` bridging `bend` — Canvas has no animatable properties of its own, so all three plants previously *snapped* between poses despite `.animation(Theme.Motion.pose, value: bend)`; now bend interpolates and the Canvas re-renders per frame. One protocol change, benefits Sunflower/Cactus/Monstera alike.

Verification: offscreen `ImageRenderer` sweep (scratchpad script compiling the 5 DesignSystem files standalone) rendered bend 0/0.3/0.6/1.0 at 200pt across all 3 state colors + 64pt thumbnail — visually inspected 2 iterations (initial + droop-coefficient tune). `xcodebuild -scheme SynthesisMac build` ✓, iOS Simulator build ✓, `xcodebuild -scheme SynthesisMac test` ✓ 32/32. Live in-app animation feel (spring interpolation at 200pt with real bend stream) still worth a hands-on look.

### Post-session bug sweep — DONE (2026-07-02, Fable)
User asked for a bug hunt after leaf 04. Four real bugs found and fixed:
- `HeadphoneMotionSource`: motion-update closure captured `self` strongly (retain cycle via manager→closure→self→manager) and fired `onAvailabilityChanged` from the motion queue — `SessionManager.evaluate()` then mutated `@Observable` state and inserted SwiftData models off-main. CoreMotion delegate callbacks have no main-thread guarantee either. All connect-state changes now funnel through `setConnected(_:)` which hops to main and de-dupes.
- `PostureEngine.isReceiving()`: `start()` resets `lastSampleAt = nil`, but AirPods motion takes ~1-2s to begin streaming — the next 1Hz heartbeat saw "not receiving" and flapped the session active↔paused (engine start/stop churn) until the first sample landed. Added a 4s spin-up grace window (`startedAt`) that counts as receiving until the first sample.
- `SunlightScheduler.nextNudge`: always stored the *morning* nudge, so the Now chip said "done today" all afternoon while the afternoon nudge was still pending. Now picks the next upcoming window.
- `SolarCalculator.compute()`: `continuation` was assigned from the caller's executor while the timeout/delegate finish paths ran on main (race), and a second overlapping `compute()` would overwrite and leak the first continuation (hung task forever). All continuation access now hops to main; an overlapping call resolves immediately with the fallback.
Also: fixed the `var stable written but never read` test warning in MotionFilterTests (asserts the settled baseline now).

Verification: mac build ✓ (one pre-existing-class Sendable warning in SolarCalculator, Swift 6 audit explicitly out of scope), iOS Simulator build ✓, 32/32 native tests ✓.

### PR review fix — DONE (2026-07-02)
[HIGH] finding from PR #2 review (github.com/Jianwei07/ios-posture/pull/2#issuecomment-4867532637): connected-but-stalled AirPods stream (isConnected stays true, samples just stop — no disconnect event) could loop `.paused` → `.active` on every heartbeat via `startSession()`, and `PostureEngine.isReceiving()` reports true during each post-`start()` spin-up grace (added in the earlier bug sweep) even with zero real samples — so `tickActive()` ran and counted stale `currentPitch`/`postureState` as active time + fed it to the reminder scheduler, indefinitely, while the stream stayed dead.

Fix: `SessionManager.tickActive()` now also requires `engine.lastSampleAt != nil` (cleared by `PostureEngine.start()`, set only by a genuine incoming sample) before counting anything. The grace window still prevents the *pause* flap (no immediate re-pause after a legitimate start), but ticking itself is a no-op until a real sample proves the stream is actually alive — no more stale-data accumulation during a stall.

New `Tests/SessionTests/SessionManagerStallTests.swift` — `resumingWithoutARealSampleDoesNotCountATick()`: drives `SessionManager.evaluate()` via the same `source.onAvailabilityChanged?()` seam the existing calibration test suite uses (no new access-level changes needed). Confirmed the test reproduces the exact reported defect: reverting the fix locally made it fail (`activeSessionSeconds` incrementing to 1 then 2 with zero real samples emitted); restored, it passes.

[LOW] SolarCalculator non-Sendable capture warning — left as-is per the reviewer's own note (non-blocking under current Swift 5.9 config; same pre-existing class of warning flagged and deliberately deferred earlier this session, out of scope for a full Swift 6 concurrency audit).

Verification: `xcodebuild -scheme SynthesisMac build` ✓, iOS Simulator build ✓, `xcodebuild -scheme SynthesisMac test` ✓ 33/33 (32 + 1 new).

**Spec session 13 complete: all 4 leaves + bug sweep + PR review fix done on `feat/macos-pivot`. Remaining before ship: manual on-device QA (menu bar glyph, water notification action, plant animation feel, real AirPods stall scenario).**

---

## Previous — 2026-06-26 macOS-first pivot plan

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
