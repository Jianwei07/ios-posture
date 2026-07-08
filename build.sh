#!/usr/bin/env bash
# Build Synthesis.app from source and open it. Local, ad-hoc signed build —
# no Apple Developer account needed, and no Gatekeeper prompt (quarantine is
# only set on files downloaded via browser/curl, not on a local git clone).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found — installing via Homebrew..."
  brew install xcodegen
fi

echo "Generating Xcode project..."
xcodegen generate

echo "Building Synthesis (Release, ad-hoc signed)..."
xcodebuild -project Synthesis.xcodeproj -scheme SynthesisMac \
  -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY=- build

APP="build/Build/Products/Release/Synthesis.app"
echo "Built: $APP"
open "$APP"
