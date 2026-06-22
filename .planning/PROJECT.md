# iOS Posture App

## Problem Statement (Root)

Software engineers wear AirPods Pro for hours. Those AirPods have a 9-axis IMU.
Use what's already in their ears to detect bad head posture and adaptively remind
them to fix posture, drink water, and take a walk — no new hardware required.

## Vision

Posture → Water → Movement → Lifestyle. A warm desk companion that grows with you.
On-device, private, open source MIT.

## Stack

- Swift 5.9+ / SwiftUI / SwiftData
- CMHeadphoneMotionManager (AirPods Pro 2nd gen)
- UserNotifications (local only)
- iOS 17.0 minimum
- Zero external dependencies

## Distribution

Personal sideload (free Apple ID). Open source MIT.

## Mascot identity

SF Symbol `figure.stand` + SwiftUI `rotationEffect` at hip anchor.
Tilts forward (18°) as pitch drops — the figure IS your posture.
Warm charcoal on cream. Breathing animation always on.

## Phase scope

**Phase 1 (current):** AirPods posture detection + lifecycle, water + walk interval reminders, Today hub UI. All on-device.

**Phase 2 (backlog):** HealthKit step-aware walk reminder, Apple Watch companion, AI/ML on-device wellness report from collected downsampled PostureReading data.

## Pivot Anchor

Return to Problem Statement if any branch fails or scope changes.
Re-derive which branches still apply from root.
