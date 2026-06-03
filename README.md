<div align="center">
  <img src="Assets/app-icon-compact.png" alt="App Icon Exporter icon" width="120" height="120">

  # App Icon Exporter

  Extract icons from macOS `.app` bundles and export them as clean PNG assets.

  English · [简体中文](README.zh-CN.md) · [Features](#features) · [Quick Start](#quick-start) · [Signing](#developer-id-signing)
</div>

## Overview

App Icon Exporter is a macOS SwiftUI utility for browsing application bundles, previewing their icons, and exporting those icons as reusable PNG files.

It supports both single-app export and batch directory export, with a custom desktop interface and a release packaging script for generating a signed `.app` bundle and `.dmg`.

## Features

- Export the icon from a single selected or dropped `.app` bundle.
- Batch scan a directory for `.app` bundles and export all discovered icons in one pass.
- Preview app icons before export.
- Choose and persist a default export directory.
- Open the export directory directly from the app.
- Handle duplicate filenames by adding numeric suffixes or skipping duplicates.
- Optionally scan nested directories recursively.
- Ship with a custom macOS-style frameless window UI.

## Quick Start

### Requirements

- macOS 14 or later
- Xcode with a Swift 6 toolchain
- Swift Package Manager

### Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

### Run

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run AppIconExporterApp
```

### Test

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Build, Run, and Package

Build a release `.app` bundle and `.dmg`:

```bash
./scripts/build-dmg.sh
```

Artifacts are written to `dist/`.

## Packaging

The packaging script assembles:

- a release app bundle at `dist/应用图标导出器.app`
- a compressed disk image at `dist/应用图标导出器.dmg`

It also generates the `.icns` icon asset from the source PNG in `Assets/`.

## Developer ID Signing

`./scripts/build-dmg.sh` follows this signing order:

1. Use a local `Developer ID Application` identity from Keychain Access when one is available.
2. Fall back to a project-local self-signed identity for local testing.

If you need to bootstrap the local test identity manually:

```bash
./scripts/ensure-local-signing.sh
```

To force ad-hoc signing for one build:

```bash
SIGN_IDENTITY=- ./scripts/build-dmg.sh
```

To explicitly select a signing identity:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-dmg.sh
```

If your keychain contains exactly one valid `Developer ID Application` identity, the packaging script will pick it automatically.

For external distribution, `Developer ID` signing is not the final step. You will typically also need notarization before Gatekeeper will accept the build on another Mac.

## Project Layout

- `Package.swift` — Swift package definition.
- `Sources/AppIconExporter` — models, services, view models, and SwiftUI views.
- `Sources/AppIconExporterApp` — macOS app entry point and window configuration.
- `Tests/AppIconExporterTests` — unit tests.
- `Assets` — source artwork for app icon generation.
- `scripts/build-dmg.sh` — release packaging script.
- `scripts/ensure-local-signing.sh` — local fallback signing bootstrap script.
- `docs` — planning and design notes.
- `mockups` — UI mockups used during design.
