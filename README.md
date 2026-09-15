# RoundCorners

A lightweight native macOS menu bar app that adds smooth black corners to your displays. Built with Swift, AppKit, and SwiftUI for Apple Silicon Macs running macOS 13 or later.

## Features

- Static corner overlays across multiple displays and ordinary full-screen spaces.
- Click-through windows that do not intercept mouse input.
- Menu bar controls to enable or pause the overlay, without a Dock icon.
- Fixed continuous-corner preset at 26.1 pt, calibrated from a System Settings screenshot.
- Adjustable SwiftUI continuous corners from 1 to 36 pt, in 0.1 pt increments.
- Custom slider value and position are preserved when the fixed preset disables the slider.
- Pink filled slider track (`#EABEBB`) and a gray disabled state.
- Launch at login through Apple's ServiceManagement framework.
- No polling, network access, timers, or continuous animations. Battery usage has not been benchmarked.

## Install

1. Download `RoundCorners-macOS-arm64.zip` from this repository using the file's download button.
2. Unzip it and place `RoundCorners.app` in a permanent location.
3. Open the app and use the dashed rectangle icon in the menu bar.
4. If macOS requests approval for launch at login, open Login Items settings from the app menu.

The included app currently has a Chinese menu. This README and repository documentation are in English.

The app is locally ad-hoc signed, not notarized by Apple. macOS may require approval to open a downloaded build. Building locally is another option.

## Build from source

Install Xcode Command Line Tools, then run:

```sh
bash build.sh
open dist/RoundCorners.app
```

The build script produces an optimized arm64 application in `dist/` and applies an ad-hoc signature. No third-party dependencies or Xcode project are required.

## How it works

Each display uses four small, transparent, borderless AppKit windows. SwiftUI's `RoundedRectangle(cornerRadius:style: .continuous)` generates the corner paths. AppKit caches and draws the inverse paths as black masks.

The app updates the overlays when settings change, display configuration changes, or the Mac wakes. It does not continuously redraw while idle.

Both corner modes use Apple's continuous shape implementation. The fixed 26.1 pt preset is a screenshot-derived approximation of a System Settings window, **not an Apple-published universal window radius**. Different macOS versions or display scaling may need recalibration.

## Settings

- **Enable / Pause:** toggles the overlay. This action has no checkmark.
- **Fixed preset:** applies 26.1 pt while disabling the custom slider without changing its saved value.
- **SwiftUI:** enables the 1–36 pt slider.
- **Launch at login:** registers or unregisters the app with macOS.

Keep the app at a stable path after enabling launch at login. Before moving it, disable login launch, move the app, then enable it again.

## Limitations

- Apple Silicon and macOS 13 or later only.
- System security screens and exclusive full-screen applications are not guaranteed to show the overlay.
- Screenshots may include the black corners.
- No claim of pixel-identical matching to private macOS window geometry.
- Low-overhead design; power consumption has not been measured.

## Uninstall

Disable launch at login from the menu, quit the app, and delete `RoundCorners.app`.

## Project files

| File | Purpose |
| --- | --- |
| `main.swift` | App and menu implementation |
| `Info.plist` | App bundle metadata |
| `build.sh` | Compile and sign locally |
| `RoundCorners-macOS-arm64.zip` | Ready-to-extract local build, version 1.6 |
