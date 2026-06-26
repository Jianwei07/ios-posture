# Verify

## 2026-06-26 — Leaf 01 Fix AirPods stream truth

Verdict: PASS

Must-haves:
- Capability and stream truth are separate: `MotionSource.isAvailable` remains capability, `MotionSource.isConnected` is connected/streaming state.
- AirPods connection monitoring is started via `CMHeadphoneMotionManager.startConnectionStatusUpdates()` from `SessionManager.begin()`.
- Delegate connect/disconnect and first real motion sample update stream truth in `HeadphoneMotionSource`.
- UI connection state uses `engine.isHeadphoneMotionConnected`, not capability.
- Session auto-start uses connected/streaming truth, preventing capability-only start/pause loops.
- Regression exists: `sessionDoesNotStartFromCapabilityOnly()` covers capability true plus no stream.

Checks:
- `xcodebuild test -project Synthesis.xcodeproj -scheme Synthesis -destination 'platform=iOS Simulator,name=iPhone 17'` -> TEST SUCCEEDED, 15 tests

Manual gap:
- Real A3047 AirPods QA still required; simulator cannot prove CoreMotion headphone samples.
