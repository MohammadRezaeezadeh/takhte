#!/usr/bin/env bash
# Runs the same gates as CI: formatting, strict analysis and tests.
set -euo pipefail
cd "$(dirname "$0")/.."
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze --fatal-infos --fatal-warnings
flutter test --enable-vmservice "$@"
