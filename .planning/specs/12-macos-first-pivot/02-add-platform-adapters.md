# Task: Add platform adapters

## Objective
Make shared source compile for iOS and macOS with the smallest platform seams.

## Context
- Current iOS-only references: `UIApplication` in `DisconnectedView.swift`, HealthKit in `StepReader.swift`, iOS plist/entitlements.
- `UserNotifications`, `SwiftUI`, `SwiftData`, and `CoreMotion` can remain shared.
- Do not extract a Swift package yet; target membership and `#if os(...)` are cheaper for this first pivot.

## Changes
1. Make `Sources/Health/StepReader.swift` HealthKit-backed on iOS and no-op on macOS.
2. Replace direct `UIApplication.openSettingsURLString` in `Sources/Views/DisconnectedView.swift` with a tiny platform conditional or omit the settings button action on macOS.
3. Guard any iOS-only imports/usages with `#if os(iOS)`.
4. Keep `NotificationModule`, `SunlightScheduler`, and SwiftData shared unless the macOS build proves a specific compile issue.
5. Do not add `IOBluetooth`, camera fallback, or new dependencies.

## Verification
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build`
- After macOS target exists: `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build`

## Done
- Shared files contain no unguarded iOS-only APIs.
- iOS build still works before adding macOS target.
