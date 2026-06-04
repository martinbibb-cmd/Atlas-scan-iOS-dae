#!/usr/bin/env bash
# Requires bash, xcodegen, and xcodebuild.
set -euo pipefail

cd "$(dirname "$0")"

xcodegen generate
xcodebuild -resolvePackageDependencies -project AtlasScan.xcodeproj
