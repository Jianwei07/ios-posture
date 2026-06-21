# State

## Current Session: 01-env-setup

## Status: BLOCKED — waiting for user to install Xcode 16

## Completed
- [x] HealthKit stripped from code (Phase 1 scope: posture + water only)
- [x] All Swift source written (18 files, no HealthKit)
- [x] project.yml ready (no healthkit capability)
- [x] Full-Xcode workflow decided (no VSCode, no Makefile)
- [x] .gitignore set to track Posture.xcodeproj after scaffold
- [x] CLAUDE.md + planning artifacts updated

## Blocked On: Leaf 0.1 — Xcode Install (user doing manually)

User installing Xcode 16 from App Store. After it finishes:
1. `sudo xcodebuild -license accept`
2. `cd /Users/jayden77/dev/ios-posture && xcodegen generate`  (one-time scaffold)
3. `open Posture.xcodeproj`
4. Xcode → Settings → Accounts → add Apple ID
5. Posture target → Signing & Capabilities → set Team
6. iPhone: Developer Mode ON, plug in, trust
7. Select iPhone in device dropdown → ⌘R
8. ⌘U for unit tests on Simulator

## Phase 1 Scope
IN: AirPods posture detection + lifecycle, interval water reminder, UI/UX, history persistence
OUT (Phase 2): HealthKit logging, walk reminder, Apple Watch
