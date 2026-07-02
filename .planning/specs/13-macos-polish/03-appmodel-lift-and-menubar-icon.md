# Task: AppModel lift + live menu bar icon

## Objective
Lift `AppModel` construction to the App level so the `MenuBarExtra` scene can observe live posture state, and add a gentle, non-flashing menu bar glyph that reflects posture — the primary "minimized" alert channel, ambient rather than interruptive.

## Context
- `Sources/App/ContentView.swift:71-81` currently builds `AppModel` lazily in `.task`, stored as `@State private var app: AppModel?`. `Sources/App/SynthesisApp.swift:21-31`'s `MenuBarExtra` scene has no access to it today; only a one-way `Notification.Name("synthesis.recalibrateRequested")` bridges MenuBarExtra → ContentView.
- `SynthesisApp.swift:41` currently uses `.modelContainer(for: [PostureSession, UserSettings, WaterEntry])` (implicit container per-scene); leaf 02's `NotificationModule.configure(container:)` needs one explicit shared `ModelContainer` created at app-launch.
- `App.init()` in SwiftUI is MainActor-isolated, so building the container and doing an initial `UserSettings` fetch-or-insert there is legal and matches the existing lazy-insert pattern in `ContentView.setup()` (which this leaf removes).
- `SynthesisMac`'s `PRODUCT_NAME` is `Synthesis` — the lift code is platform-neutral, no new `#if os()` needed beyond the existing `MenuBarExtra` guard.
- `SessionManager` runs one 1Hz `Timer`-driven `evaluate()` — the menu bar update should piggyback this, not add a new timer, and should assign the published state only on change (an `@Observable` label bound to per-sample `postureState`, which updates near 20Hz, would re-render constantly).

## Changes
1. `SynthesisApp.swift`: in `init()`, create one `ModelContainer` for `[PostureSession, UserSettings, WaterEntry]` (`try!`, matching the framework's own fatal-on-failure convention for `.modelContainer(for:)`), fetch-or-insert the singleton `UserSettings` via `FetchDescriptor<UserSettings>()` on `container.mainContext`, call `NotificationModule.shared.configure(container:)`, and construct `AppModel(settings:)` into `@State private var appModel: AppModel` (via `State(initialValue:)` in init). Attach `.environment(appModel)` and `.modelContainer(container)` to both the `WindowGroup` and the `MenuBarExtra` scene content.
2. `ContentView.swift`: remove `@State private var app: AppModel?` and the `setup()` settings-insert logic (now done in `SynthesisApp.init`); switch to `@Environment(AppModel.self) private var app`; keep `.task { app.start(modelContext: modelContext) }` for heartbeat/permission-prompt timing (unchanged — `start` is already idempotent-guarded). Remove now-unnecessary `if let app` unwrapping.
3. Add a pure `MenuBarReducer`-style piece of state to `AppModel` (or a small dedicated type in `Sources/App/`): `enum MenuBarState { case idle, aligned, drift, wilt }`, `private(set) var menuBarState: MenuBarState = .idle`. Add `SessionManager.onHeartbeat: ((SessionState, PostureState) -> Void)?`, invoked at the end of the existing `evaluate()` — no new timer. `AppModel` wires this closure in `start()` and reduces: session not `.active` → `.idle`; sustained `.slouch` ≥30s (tracked via a `slouchSince: Date?`, cleared on any non-slouch state) → `.wilt`; `.slouch` <30s or `.drift` → `.drift`; `.aligned` → `.aligned`. Assign `menuBarState` only when the computed value differs from the current one, so downstream `@Observable` invalidation only fires on actual transitions.
4. `SynthesisApp.swift` `MenuBarExtra`: add a live status line (e.g. `Text(appModel.menuBarStatusLine)` — short computed string like "Aligned · 32 min upright" or "AirPods not connected") above the existing Open/Recalibrate/Quit buttons. Change the `label:` closure from the static `Image(systemName: "airpodspro")` to `Image(systemName: appModel.menuBarState.symbolName)` where `symbolName` maps `idle → "airpodspro"`, `aligned → "leaf.fill"`, `drift → "leaf"`, `wilt → "leaf.arrow.circlepath"` (all monochrome/template-safe SF Symbols — flag this mapping for visual review, it's a taste call, not a technical constraint).

## Verification
- New `Tests/AppTests/MenuBarStateTests.swift`: pure reducer test feeding `(SessionState, PostureState, elapsed time)` sequences — slouch held <30s stays `.drift`; ≥30s transitions to `.wilt`; leaving slouch recovers immediately to `.drift`/`.aligned`; session going `.paused` forces `.idle`; assert the state-change count matches only actual transitions (no redundant assignments).
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac build && xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac test`
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build` (iOS still compiles — MenuBarExtra code stays inside the existing `#if os(macOS)` guard)
- Manual on real AirPods: minimize/hide the main window, sustain a slouch ≥30s, confirm the menu bar glyph changes without any window being visible; recover posture and confirm it reverts promptly; confirm the glyph does not flicker during brief posture noise.

## Done
- `AppModel` is constructed once at app launch and shared via `.environment` to both scenes; `ContentView` no longer owns a nullable `AppModel`.
- One explicit `ModelContainer` is shared by both scenes and `NotificationModule`.
- Menu bar icon reflects posture state live, updates only on state transitions, recovers immediately, never flashes.
- iOS target is unaffected and still builds.
