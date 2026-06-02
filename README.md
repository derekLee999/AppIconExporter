# AppIconExporter

AppIconExporter is a macOS SwiftUI utility for extracting icons from `.app` bundles and exporting them as PNG files.

It supports both single-app export and batch directory export, with a custom macOS-style interface and DMG packaging script.

## Features

- Batch scan a directory for `.app` bundles.
- Export all discovered app icons to PNG in one pass.
- Export a single selected or dropped `.app` icon.
- Preview app icons before export.
- Choose and persist a default export directory.
- Open the export directory from the app.
- Handle duplicate output filenames by either adding numeric suffixes or skipping duplicates.
- Optional recursive scanning for nested directories.
- Custom traffic-light window controls and frameless rounded window UI.

## Requirements

- macOS 14 or later
- Xcode with Swift 6 toolchain
- Swift Package Manager

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

## Test

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Run

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run AppIconExporterApp
```

## Package

Build a release `.app` bundle and `.dmg`:

```bash
./scripts/build-dmg.sh
```

Artifacts are written to `dist/`.

The packaging script uses an ad-hoc signature by default for local testing. For distribution, pass a Developer ID identity:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-dmg.sh
```

## Project Layout

- `Package.swift`: Swift package definition.
- `Sources/AppIconExporter`: app models, services, view models, and SwiftUI views.
- `Sources/AppIconExporterApp`: macOS app entry point and window configuration.
- `Tests/AppIconExporterTests`: unit tests.
- `Assets`: source images for app icon generation.
- `scripts/build-dmg.sh`: release packaging script.
- `mockups`: UI mockups used during design.
- `docs`: planning notes.

## Notes

The generated `.app` and `.dmg` are intentionally ignored by Git. Rebuild them locally with `./scripts/build-dmg.sh` when needed.
