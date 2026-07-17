# Releasing Synthesis

Releases are tag-driven. Pushing a tag `v<version>` runs
[`release.yml`](.github/workflows/release.yml), which builds the macOS app
(ad-hoc signed), zips it, and publishes a GitHub Release with the sha256.

The primary install path is build-from-source (`./build.sh`, see README) —
the release zip is a secondary download for people who don't want Xcode, and
carries the Gatekeeper caveat since it's a downloaded (quarantined) binary.

## Checklist

1. **Bump the version** in `project.yml` (single source of truth):
   ```yaml
   MARKETING_VERSION: "1.0.1"   # semver, must match the tag
   CURRENT_PROJECT_VERSION: "2" # increment by 1 every release
   ```
2. **Regenerate the project** and commit both files:
   ```bash
   xcodegen generate
   git add project.yml Synthesis.xcodeproj
   ```
3. **PR → merge to `main`** (main is protected; CI must pass).
4. **Tag the merge commit and push the tag:**
   ```bash
   git checkout main && git pull
   git tag v1.0.1
   git push origin v1.0.1
   ```
5. **Watch the Release workflow** (Actions → Release). It publishes the
   GitHub Release with `Synthesis-1.0.1.zip`.
6. **Verify install:**
   ```bash
   ./build.sh   # build-from-source path
   # or, for the release zip:
   curl -L -o Synthesis.zip https://github.com/Jianwei07/ios-posture/releases/latest/download/Synthesis-1.0.1.zip
   ditto -x -k Synthesis.zip .
   open Synthesis.app
   ```

## Versioning rules

- **Semver** on `MARKETING_VERSION`: patch = fixes, minor = features,
  major = breaking changes to stored data or behavior.
- Tag is always `v` + `MARKETING_VERSION`; the workflow fails if they differ.
- `CURRENT_PROJECT_VERSION` (build number) only ever increments.
- SwiftData caution: new non-optional `@Model` fields need inline defaults;
  never delete/rename persisted fields without a migration plan — users'
  local stores must survive every upgrade.

## Signing status

Builds are **ad-hoc signed** (free Apple ID — no Developer ID certificate, no
notarization). A local build (`./build.sh`) never touches Gatekeeper since
it's never quarantined. The release zip *is* quarantined (downloaded via
browser/curl) so its README caveat about "Open Anyway" still applies. If a
paid Apple Developer account is added later: sign with a Developer ID
Application cert and add a `xcrun notarytool submit --wait` +
`xcrun stapler staple` step to `release.yml` to remove that caveat too.

## Yanking a release

Delete the GitHub Release + tag. Never reuse a version number — publish a
new patch instead.
