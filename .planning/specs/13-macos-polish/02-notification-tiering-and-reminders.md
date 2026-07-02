# Task: Notification tiering + water/walk reminder logic

## Objective
Make reminders soft by default (water/walk/sunlight = silent, in-app only) while posture stays a priority alert with sound. Add water smart-skip with a "Log 250ml" notification action, and make the walk reminder presence-aware instead of relying on unavailable HealthKit step data on macOS.

## Context
- `Sources/Notifications/NotificationModule.swift` — singleton `NotificationModule.shared`. `fire()` builds `UNMutableNotificationContent` with `sound = .default` unconditionally, posts immediately, and posts an in-app `overlayNotification` for `NowView`'s flash banner. No `UNUserNotificationCenterDelegate` is set, so on macOS foreground banners can be suppressed.
- `Sources/Reminders/ReminderScheduler.swift` — `tick(postureState:sessionSeconds:)` called 1Hz from `SessionManager`. Posture escalates after 360s sustained slouch (5min cooldown) — keep as-is, priority tier. Water fires blind every `baseWaterIntervalMin` of session time, ignoring `WaterEntry` data. Walk fires every `baseWalkIntervalMin`; on macOS `StepReader.todaySteps` is always 0 (`#if os(iOS)` HealthKit-gated), so the pace-check branch never runs and it degrades to a blind interval anyway.
- `Sources/Sunlight/SunlightScheduler.swift:35-38` builds its own notification content with `sound = .default` — needs to route through the shared soft-tier builder.
- `Sources/Session/SessionManager.swift` — 1Hz heartbeat, states idle/active/paused; `pauseSession()`/resume paths exist but don't currently track pause duration.
- `Sources/Models/WaterLog.swift` defines `WaterEntry` (SwiftData `@Model`, `volumeMl` default 250).
- `AppModel` will (after leaf 03) own one shared `ModelContainer`; for this leaf, wire a `ModelContext` accessor into the scheduler via a closure seam rather than assuming the leaf-03 lift has happened — keep the seam injectable so leaf 03 just supplies the real closure.

## Changes
1. `NotificationModule.swift`: add `ReminderType.isPriority` (`true` only for `.posture`). Add `configure(container: ModelContainer)` that sets `UNUserNotificationCenter.current().delegate = self` (class becomes `NSObject, UNUserNotificationCenterDelegate`) and registers a `UNNotificationCategory` for water with a `UNNotificationAction(identifier: "synthesis.water.log", title: "Log 250 ml")`. Build a shared `content(for:detail:)` helper: priority → `sound = .default`, `interruptionLevel = .active`; soft → `sound = nil`, `interruptionLevel = .passive`. Implement `willPresent` (priority → `[.banner, .sound]`, soft → `[.banner]`) and `didReceive` (water log action → `Task { @MainActor in }` insert `WaterEntry()` into the container's `mainContext` and save). `configure(container:)` must be called at app-launch time (App `init`), not inside a deferred `.task`, or action taps that launch the app from a terminated state get dropped.
2. `SunlightScheduler.swift`: switch its notification content construction to the shared `content(for:detail:)` builder so sunlight nudges go soft too.
3. `ReminderScheduler.swift`: add injectable seams `var lastWaterLogAt: (() -> Date?)?` and `var waterProgress: (() -> (todayMl: Double, targetMl: Double))?`. Replace the water branch: at the interval boundary, if `lastWaterLogAt()` is within the last `baseWaterIntervalMin` minutes, defer (advance `lastWaterReminderAt` without firing); if `waterProgress()` shows today's total ≥ target, skip; otherwise fire with progress-softened detail copy. Also inject a `fire: (ReminderType, String?) -> Void` closure (default `{ NotificationModule.shared.fire($0, detail: $1) }`) so scheduler logic is unit-testable without `UNUserNotificationCenter`.
4. `ReminderScheduler.swift`: replace `checkWalk` — delete the `currentStepCount`-based pace-check branch entirely (dead on macOS, unreliable in general); keep a plain interval fire. Add `func noteBreakTaken(sessionSeconds: Double)` that resets `lastWalkReminderAt = sessionSeconds`.
5. `SessionManager.swift`: track `private var pausedAt: Date?`, set on `pauseSession()`. On the `.paused → active` resume path, if `Date.now.timeIntervalSince(pausedAt) >= 300`, call `scheduler.noteBreakTaken(sessionSeconds: activeSessionSeconds)` before resuming (assume a ≥5min AirPods-out gap means the user walked). Clear `pausedAt` on resume. Remove the `scheduler.currentStepCount = stepReader?.todaySteps ?? 0` line from `tickActive()` and the now-unused `stepReader` wiring path into the scheduler (keep `StepReader` itself — NowView's walk chip on iOS still reads it directly).
6. `NowView.swift`: on macOS, show the walk chip step count as "—" instead of "0" (steps are structurally unavailable, not zero).

## Verification
- New `Tests/ReminderTests/ReminderSchedulerTests.swift` using the injected `fire` closure:
  - water fires at interval boundary with no recent log; defers when `lastWaterLogAt` is within interval; skipped when `waterProgress` shows target met
  - walk fires at `baseWalkIntervalMin`; `noteBreakTaken` resets the timer so the next fire is a full interval later
  - posture: no fire before 360s sustained slouch; fires after; 300s cooldown respected; interruption (state leaving slouch) resets the sustain clock; `escalateLongSlouches == false` suppresses entirely
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac test`
- Manual: trigger a water notification on macOS with the app window closed — confirm "Log 250 ml" action appears, tapping it updates the water chip when the window is reopened (NowView `@Query` reflects the new `WaterEntry` without restarting the app).
- Manual: confirm water/walk/sunlight notifications are silent; posture notification has sound.

## Done
- Posture alerts have sound; water/walk/sunlight are silent, banner-only.
- Water reminder skips when recently logged or target met; "Log 250 ml" action writes to SwiftData and the UI reflects it live.
- Walk reminder is presence-aware: resets after a ≥5min AirPods-out break, no longer depends on unavailable macOS step data.
- Scheduler logic is unit-tested without touching `UNUserNotificationCenter`.
