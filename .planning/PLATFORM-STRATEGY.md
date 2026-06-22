# Platform Strategy

## Finding

`CMHeadphoneMotionManager` works on **macOS 14.0+** — not iOS-only as assumed.  
Reference: [dorso](https://github.com/tldev/dorso) — production macOS app using same API.

## Approach: macOS First, iOS Second

**Why macOS first:**
- No deploy-to-device friction (AirPods already paired to Mac)
- Faster iteration on posture engine + calibration math
- Immediate visual feedback (screen overlay vs phone in pocket)

**What stays shared:**
- `PostureEngine` — pitch math, low-pass filter, calibration, classifier
- `Models` — data structures, thresholds
- `Reminders` logic — interval math

**What differs per platform:**
- Notifications: `UNUserNotificationCenter` (iOS) vs `NSUserNotification`/overlay (macOS)
- UI: SwiftUI works both, but layout differs
- Device detection: macOS can use private `IOBluetooth` API (non-App-Store only)

## Migration Path

```
Phase 1 (now)     → macOS app, validate posture engine with real AirPods
Phase 2           → Extract shared Swift package (PostureEngine + Models)
Phase 3           → iOS target consumes same package, adds mobile UX
```

## Key Constraints

- `CMHeadphoneMotionManager` requires **macOS 14.0+** / **iOS 17.0+**
- Simulator still can't read AirPods on either platform — real device always needed
- Private `IOBluetooth` API (for AirPods model detection) = non-App-Store macOS only
