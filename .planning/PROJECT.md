# iOS Posture App

## Problem Statement (Root)

Software engineers wear AirPods Pro for hours. Those AirPods have a 9-axis IMU.
Use what's already in their ears to detect bad head posture and adaptively remind
them to fix posture, drink water, and take a walk — no new hardware required.

## Stack

- Swift 5.9+ / SwiftUI / SwiftData
- CMHeadphoneMotionManager (AirPods Pro 2+)
- HealthKit (read steps, write sessions)
- UserNotifications (local only)
- iOS 17.0 minimum
- Zero external dependencies

## Distribution

Personal sideload (free Apple ID). Open source MIT.

## Pivot Anchor

Return to Problem Statement if any branch fails or scope changes.
Re-derive which branches still apply from root.
