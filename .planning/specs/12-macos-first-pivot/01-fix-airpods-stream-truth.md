# Task: Fix AirPods stream truth

## Objective
Stop connected/disconnected flicker by making connected mean active AirPods motion stream, not CoreMotion capability.

## Context
- `Sources/PostureEngine/PostureEngine.swift` owns `MotionSource` and `HeadphoneMotionSource`.
- `Sources/Session/SessionManager.swift` currently starts from `engine.isHeadphoneMotionAvailable`.
- `Sources/App/AppModel.swift` exposes `isConnected` to UI.
- Dorso reference: macOS AirPods detector uses `CMHeadphoneMotionManager.authorizationStatus()`, `startConnectionStatusUpdates()`, delegate callbacks, and treats receiving motion/delegate state as connected.
- User hardware: A3047 AirPods Pro 2 USB-C, motion capable.

## Changes
1. Update `MotionSource` with separate capability and streaming/connected state.
2. In `HeadphoneMotionSource`, call `startConnectionStatusUpdates()` when monitoring starts and stop it only when the source is fully torn down.
3. Track delegate connect/disconnect and first sample receipt as the streaming truth.
4. Expose `AppModel.isConnected` from streaming truth, not `isDeviceMotionAvailable`.
5. Update `SessionManager` so `idle` starts only when streaming/connected or after an explicit calibration start can receive samples; avoid start/pause loops when capability is true but samples are absent.
6. Add/update one Swift Testing regression using `FakeMotionSource`: capability true plus no samples must not oscillate active/paused.

## Verification
- `xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'`
- Manual later on Mac/iPhone: remove AirPods, wait 5s, confirm disconnected state is stable with no flicker.

## Done
- UI connection state stays stable when AirPods are out.
- Calibration countdown only advances when real samples arrive.
- No fake baseline is saved when samples never arrive.
