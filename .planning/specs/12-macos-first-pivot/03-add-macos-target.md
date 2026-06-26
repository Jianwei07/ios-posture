# Task: Add macOS target

## Objective
Add a macOS 14+ app target in the existing monorepo while preserving the iOS app.

## Context
- `project.yml` is the source for XcodeGen.
- `Synthesis.xcodeproj/project.pbxproj` already has user/Xcode signing changes; inspect before regenerating.
- `.planning/specs-legacy-20260626` preserves old planning state.
- macOS requires `CMHeadphoneMotionManager` on macOS 14.0+.

## Changes
1. Add a `SynthesisMac` application target to `project.yml` with platform `macOS` and deployment target `14.0`.
2. Keep iOS target `Synthesis` unchanged except for shared source membership needed by adapters.
3. Do not attach iOS HealthKit entitlements/frameworks to the macOS target.
4. Use generated or macOS-specific Info.plist settings; keep iOS-only plist keys out of macOS.
5. Run XcodeGen only after reviewing current project diffs and preserving signing/team changes if possible.

## Verification
- `xcodegen generate`
- `xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac -destination 'platform=macOS' build`
- `xcodebuild -project Synthesis.xcodeproj -scheme Synthesis -destination 'generic/platform=iOS' build`

## Done
- `SynthesisMac` appears as a buildable scheme.
- iOS target remains buildable.
