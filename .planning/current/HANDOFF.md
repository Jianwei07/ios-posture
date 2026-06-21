# Handoff

## Where we are
Phase 1 code complete + cleaned (HealthKit stripped). Open-source README + LICENSE added.
Xcode.app installed but toolchain NOT yet switched (still on CommandLineTools).

## BLOCKER — user must run (needs sudo password)
```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```
Then I can: `xcodegen generate` → build → verify compile.

## Decisions this session
- Full Xcode workflow (dropped VSCode + Makefile)
- xcodegen = one-time scaffold only; manage in Xcode after, never re-run
- Phase 1 scope: posture detection + interval water reminder + UI. HealthKit/walk → Phase 2
- Water reminder = pure interval (no adaptive multiplier)

## Code fix made (pre-build review)
PostureEngine: added **watchdog timer**. CMHeadphoneMotionManager goes silent on
AirPods removal without any callback — watchdog flips `isActive=false` after 1.5s
of no motion samples. Critical for "pause on removal" requirement.

## Known items to verify on first device test
- AirPods removal → session pauses (watchdog) → reinsert recalibrates
- SwiftData container auto-includes PostureReading via relationship (not explicitly listed in modelContainer) — confirm it persists
- Connection polling in SessionActiveView relies on eng.isActive (now watchdog-driven)

## Skills used
grilling, jayden-workflow
