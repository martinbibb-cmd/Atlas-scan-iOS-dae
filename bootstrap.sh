#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

xcodegen generate
xcodebuild -resolvePackageDependencies -project AtlasScan.xcodeproj
