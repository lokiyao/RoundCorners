#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/dist/RoundCorners.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$PWD/.build/ModuleCache"
cp Info.plist "$APP/Contents/Info.plist"
xcrun swiftc main.swift -module-cache-path "$PWD/.build/ModuleCache" -o "$APP/Contents/MacOS/RoundCorners" -target arm64-apple-macosx13.0 -O -framework AppKit -framework ServiceManagement -framework SwiftUI
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
printf 'Built: %s\n' "$APP"
