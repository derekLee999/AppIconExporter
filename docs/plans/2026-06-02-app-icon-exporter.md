# App Icon Exporter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS SwiftUI utility that accepts a single `.app` by picker or drag-and-drop, previews the app icon, exports it as PNG, and remembers a default export directory.

**Architecture:** Use a small Swift Package with a SwiftUI app entry point and a focused `ExportViewModel` that coordinates all user actions. Bridge to AppKit only for native macOS capabilities such as icon extraction, open/save panels, overwrite confirmation, and PNG encoding.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation, Swift Package Manager, `swift build`, `swift test`

---

### Task 1: Scaffold the macOS Swift package app

**Files:**
- Create: `Package.swift`
- Create: `Sources/AppIconExporter/AppIconExporterApp.swift`
- Create: `Tests/AppIconExporterTests/AppIconExporterTests.swift`

**Step 1: Write the failing test**

Create a placeholder test target that imports the module and references the planned view model type:

```swift
import Testing
@testable import AppIconExporter

@Test func moduleLoads() {
    _ = ExportViewModel(service: MockAppIconService())
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: FAIL because the package and module do not exist yet.

**Step 3: Write minimal implementation**

- Create a macOS executable package.
- Add a minimal SwiftUI `@main` app.
- Add a placeholder `ExportViewModel` and mock service protocol to satisfy the test.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: PASS with one placeholder test.

### Task 2: Implement the domain types and preferences persistence

**Files:**
- Create: `Sources/AppIconExporter/Models/ExportStatus.swift`
- Create: `Sources/AppIconExporter/Models/SelectedApp.swift`
- Create: `Sources/AppIconExporter/Services/PreferencesStore.swift`
- Modify: `Tests/AppIconExporterTests/AppIconExporterTests.swift`

**Step 1: Write the failing tests**

Add tests that verify:

```swift
@Test func defaultDirectoryLoadsFromUserDefaults() async throws
@Test func savingDefaultDirectoryPersistsPathString() async throws
@Test func selectedAppUsesFilenameFallbackWhenDisplayNameMissing() async throws
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: FAIL because the types and persistence store are incomplete.

**Step 3: Write minimal implementation**

- Add a `SelectedApp` model carrying URL, display name, and derived filename.
- Add `ExportStatus` for idle, success, and error messaging.
- Add `PreferencesStore` backed by `UserDefaults`.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: PASS for all model and persistence tests.

### Task 3: Implement AppKit-backed icon and export services

**Files:**
- Create: `Sources/AppIconExporter/Services/AppIconService.swift`
- Create: `Sources/AppIconExporter/Services/SystemAppIconService.swift`
- Modify: `Tests/AppIconExporterTests/AppIconExporterTests.swift`

**Step 1: Write the failing tests**

Add tests that verify:

```swift
@Test func validateAppURLRejectsNonAppPath() async throws
@Test func exportTargetURLUsesAppNameAndDirectory() async throws
@Test func pngDataThrowsWhenImageEncodingFails() async throws
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: FAIL because the service and helpers do not exist yet.

**Step 3: Write minimal implementation**

- Define the `AppIconService` protocol.
- Implement `.app` validation.
- Implement icon extraction via `NSWorkspace.shared.icon(forFile:)`.
- Implement PNG encoding from `NSImage`.
- Implement target URL building and disk writes.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: PASS for service-level tests.

### Task 4: Implement the export view model flow

**Files:**
- Create: `Sources/AppIconExporter/ViewModels/ExportViewModel.swift`
- Modify: `Sources/AppIconExporter/Services/AppIconService.swift`
- Modify: `Tests/AppIconExporterTests/AppIconExporterTests.swift`

**Step 1: Write the failing tests**

Add tests that verify:

```swift
@Test func selectingValidAppUpdatesPreviewState() async throws
@Test func invalidDropDoesNotClearCurrentSelection() async throws
@Test func exportWithoutSelectionShowsInlineError() async throws
@Test func firstExportWithoutDefaultDirectoryRequestsSavePanel() async throws
@Test func saveAsUpdatesDefaultDirectoryAfterSuccess() async throws
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: FAIL because the view model behavior is not implemented.

**Step 3: Write minimal implementation**

- Add observable state for selected app, preview image, drag state, status, and busy state.
- Implement select, drop, export, and save-as action methods.
- Keep overwrite confirmation and save-panel branching in the service boundary so tests can mock it cleanly.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: PASS for all flow tests.

### Task 5: Build the SwiftUI interface and drag-and-drop experience

**Files:**
- Create: `Sources/AppIconExporter/Views/MainView.swift`
- Create: `Sources/AppIconExporter/Views/GlassCard.swift`
- Modify: `Sources/AppIconExporter/AppIconExporterApp.swift`

**Step 1: Write the failing test**

Add a lightweight compile-time test that instantiates the main view with a mock view model:

```swift
@Test func mainViewBuildsWithMockViewModel() {
    _ = MainView(viewModel: ExportViewModel(service: MockAppIconService()))
}
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: FAIL because the main view does not exist yet.

**Step 3: Write minimal implementation**

- Build the approved two-pane layout.
- Implement the drag target that only accepts `.app`.
- Add the icon preview, file name preview, default directory section, status banner, and action buttons.
- Style the UI with a restrained Liquid Glass treatment.

**Step 4: Run test to verify it passes**

Run: `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
Expected: PASS and the package compiles.

### Task 6: Verify build and runtime behavior

**Files:**
- Modify: `README.md`

**Step 1: Write the failing test**

No new unit test. Treat missing build and run instructions as the failing condition.

**Step 2: Run verification commands**

Run:
- `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
- `cd /Users/shuai/Documents/code/AppIconExporter && swift build`

Expected: both commands succeed.

**Step 3: Write minimal implementation**

- Add a short `README.md` with build/run instructions.
- Record any limitations, such as direct execution through `swift run`.

**Step 4: Run final verification**

Run:
- `cd /Users/shuai/Documents/code/AppIconExporter && swift test`
- `cd /Users/shuai/Documents/code/AppIconExporter && swift build`

Expected: both commands succeed after docs are added.
