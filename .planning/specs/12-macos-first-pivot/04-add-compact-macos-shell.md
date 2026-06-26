# Task: Add compact macOS shell

## Objective
Provide a small native macOS app shell while reusing the existing visual language.

## Context
- User asked screens stay similar and small on macOS.
- Dorso reference uses compact windows around 420-480px wide plus menu-bar controls.
- Existing SwiftUI screens can be reused first; do not redesign the product.

## Changes
1. Add a macOS entry point or platform branch that creates a compact main window.
2. Add a `MenuBarExtra` with status, open app, recalibrate, and quit.
3. Constrain macOS window width around 420-480px and keep content vertically compact.
4. Reuse `NowView`, `TrendsView`, `SettingsView`, `OnboardingFlow`, and `CalibrateView` where practical.
5. Keep iOS `WindowGroup` behavior unchanged.

## Verification
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build`
- Manual: launch macOS app, confirm menu bar item appears and opens the compact window.

## Done
- macOS app has a native menu-bar control surface and compact window.
- iOS UI is unchanged.
