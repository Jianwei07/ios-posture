# Releasing Synthesis

Releases are tag-driven. Pushing a tag `v<version>` runs
[`release.yml`](.github/workflows/release.yml), which builds the macOS app
(ad-hoc signed), zips it, and publishes a GitHub Release with the sha256.
The Homebrew cask lives in
[`Jianwei07/homebrew-synthesis`](https://github.com/Jianwei07/homebrew-synthesis)
and is bumped manually after each release.

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
   GitHub Release with `Synthesis-1.0.1.zip` and prints the **sha256** in the
   release notes.
6. **Bump the Homebrew cask** in `Jianwei07/homebrew-synthesis`:
   edit `Casks/synthesis.rb` — update `version` and `sha256` — commit, push.
7. **Verify install:**
   ```bash
   brew update
   brew reinstall --cask --no-quarantine jianwei07/synthesis/synthesis
   open -a Synthesis
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
notarization). Users must approve first launch via System Settings →
Privacy & Security, or install with `--no-quarantine`. If a paid Apple
Developer account is added later: sign with a Developer ID Application cert
and add a `xcrun notarytool submit --wait` + `xcrun stapler staple` step to
`release.yml`, then drop the caveats from the cask.

## Yanking a release

Delete the GitHub Release + tag, revert the cask bump in the tap. Never
reuse a version number — publish a new patch instead.
