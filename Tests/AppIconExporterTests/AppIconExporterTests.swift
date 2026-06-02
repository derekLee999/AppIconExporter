import AppKit
import Testing
@testable import AppIconExporter

@Test
func defaultDirectoryLoadsFromUserDefaults() {
    let suiteName = #function
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.set("/tmp/example", forKey: "defaultExportDirectoryPath")
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let store = UserDefaultsPreferencesStore(userDefaults: defaults)

    #expect(store.loadDefaultDirectory()?.path == "/tmp/example")
}

@Test
func savingDefaultDirectoryPersistsPathString() {
    let suiteName = #function
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let store = UserDefaultsPreferencesStore(userDefaults: defaults)
    store.saveDefaultDirectory(URL(fileURLWithPath: "/tmp/output", isDirectory: true))

    #expect(defaults.string(forKey: "defaultExportDirectoryPath") == "/tmp/output")
}

@Test
func selectedAppUsesFilenameFallbackWhenDisplayNameMissing() {
    let url = URL(fileURLWithPath: "/Applications/Finder.app")
    let app = SelectedApp(url: url, displayName: "")

    #expect(app.exportFileName == "Finder.png")
}

@MainActor
@Test
func validateAppURLRejectsNonAppPath() {
    let service = SystemAppIconService()
    #expect(service.isAppBundle(URL(fileURLWithPath: "/tmp/test.txt")) == false)
}

@MainActor
@Test
func exportTargetURLUsesAppNameAndDirectory() {
    let service = SystemAppIconService()
    let app = SelectedApp(url: URL(fileURLWithPath: "/Applications/Finder.app"), displayName: "Finder")
    let directory = URL(fileURLWithPath: "/tmp/output", isDirectory: true)

    #expect(service.buildExportURL(for: app, directory: directory).path == "/tmp/output/Finder.png")
}

@MainActor
@Test
func pngDataThrowsWhenImageEncodingFails() {
    let service = SystemAppIconService()
    let image = NSImage(size: .zero)

    #expect(throws: AppIconServiceError.self) {
        _ = try service.pngData(for: image)
    }
}

@MainActor
@Test
func selectingValidAppUpdatesPreviewState() {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let appURL = URL(fileURLWithPath: "/Applications/Finder.app")
    service.loadedApp = LoadedApp(
        selectedApp: SelectedApp(url: appURL, displayName: "Finder"),
        icon: NSImage(size: NSSize(width: 64, height: 64))
    )

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([appURL])

    #expect(viewModel.selectedApp?.displayName == "Finder")
    #expect(viewModel.exportFileNamePreview == "Finder.png")
    #expect(viewModel.previewImage != nil)
}

@MainActor
@Test
func scanningDirectoryLoadsBatchItems() {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let sourceDirectory = URL(fileURLWithPath: "/Applications", isDirectory: true)
    let safariURL = URL(fileURLWithPath: "/Applications/Safari.app")
    let mailURL = URL(fileURLWithPath: "/Applications/Mail.app")
    service.directoryURLs.insert(sourceDirectory)
    service.scannedAppURLs = [mailURL, safariURL]
    service.loadedAppsByURL = [
        mailURL: LoadedApp(
            selectedApp: SelectedApp(url: mailURL, displayName: "Mail"),
            icon: NSImage(size: NSSize(width: 64, height: 64))
        ),
        safariURL: LoadedApp(
            selectedApp: SelectedApp(url: safariURL, displayName: "Safari"),
            icon: NSImage(size: NSSize(width: 64, height: 64))
        )
    ]

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([sourceDirectory])

    #expect(viewModel.mode == .batch)
    #expect(viewModel.sourceDirectory?.path == "/Applications")
    #expect(viewModel.discoveredAppCount == 2)
    #expect(viewModel.pendingExportCount == 2)
    #expect(viewModel.status?.kind == .success)
}

@MainActor
@Test
func batchExportWritesUniqueFileNames() async {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let sourceDirectory = URL(fileURLWithPath: "/Applications", isDirectory: true)
    let outputDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let firstURL = URL(fileURLWithPath: "/Applications/One.app")
    let secondURL = URL(fileURLWithPath: "/Applications/Two.app")
    service.directoryURLs.insert(sourceDirectory)
    service.scannedAppURLs = [firstURL, secondURL]
    service.loadedAppsByURL = [
        firstURL: LoadedApp(
            selectedApp: SelectedApp(url: firstURL, displayName: "Duplicate"),
            icon: makeTestIcon()
        ),
        secondURL: LoadedApp(
            selectedApp: SelectedApp(url: secondURL, displayName: "Duplicate"),
            icon: makeTestIcon()
        )
    ]
    store.savedDirectory = outputDirectory

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([sourceDirectory])
    await viewModel.exportAll()?.value

    #expect(viewModel.exportedCount == 2)
    #expect(viewModel.failedCount == 0)
    #expect(viewModel.batchItems.map(\.state).compactMap { state in
        if case let .exported(url) = state {
            return url.lastPathComponent
        }
        return nil
    } == ["Duplicate.png", "Duplicate 2.png"])
}

@MainActor
@Test
func batchExportSkipsDuplicateFileNamesWhenAutoNumberingIsOff() async {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let sourceDirectory = URL(fileURLWithPath: "/Applications", isDirectory: true)
    let outputDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: outputDirectory) }
    let firstURL = URL(fileURLWithPath: "/Applications/One.app")
    let secondURL = URL(fileURLWithPath: "/Applications/Two.app")
    service.directoryURLs.insert(sourceDirectory)
    service.scannedAppURLs = [firstURL, secondURL]
    service.loadedAppsByURL = [
        firstURL: LoadedApp(
            selectedApp: SelectedApp(url: firstURL, displayName: "Duplicate"),
            icon: makeTestIcon()
        ),
        secondURL: LoadedApp(
            selectedApp: SelectedApp(url: secondURL, displayName: "Duplicate"),
            icon: makeTestIcon()
        )
    ]
    store.savedDirectory = outputDirectory

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([sourceDirectory])
    viewModel.toggleAutoNumberDuplicateFiles()
    await viewModel.exportAll()?.value

    #expect(viewModel.exportedCount == 1)
    #expect(viewModel.skippedCount == 1)
    #expect(viewModel.failedCount == 0)
    #expect(viewModel.batchItems.map(\.state).compactMap { state in
        if case let .skipped(message) = state {
            return message
        }
        return nil
    } == ["文件已存在：Duplicate.png"])
}

@MainActor
@Test
func invalidDropDoesNotClearCurrentSelection() {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let appURL = URL(fileURLWithPath: "/Applications/Finder.app")
    service.loadedApp = LoadedApp(
        selectedApp: SelectedApp(url: appURL, displayName: "Finder"),
        icon: NSImage(size: NSSize(width: 64, height: 64))
    )

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([appURL])
    _ = viewModel.handleDroppedURLs([URL(fileURLWithPath: "/tmp/test.txt")])

    #expect(viewModel.selectedApp?.displayName == "Finder")
    #expect(viewModel.status?.kind == .error)
}

@MainActor
@Test
func exportWithoutSelectionShowsInlineError() {
    let viewModel = ExportViewModel(service: MockAppIconService(), preferencesStore: InMemoryPreferencesStore())

    viewModel.export()

    #expect(viewModel.status == ExportStatus(kind: .error, message: "请先选择一个应用。"))
}

@MainActor
@Test
func firstExportWithoutDefaultDirectoryRequestsSavePanel() {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let appURL = URL(fileURLWithPath: "/Applications/Finder.app")
    let saveURL = URL(fileURLWithPath: "/tmp/exports/Finder.png")
    service.loadedApp = LoadedApp(
        selectedApp: SelectedApp(url: appURL, displayName: "Finder"),
        icon: NSImage(size: NSSize(width: 64, height: 64))
    )
    service.nextSaveURL = saveURL

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([appURL])
    viewModel.export()

    #expect(service.requestedSaveFileName == "Finder.png")
    #expect(store.savedDirectory?.path == "/tmp/exports")
    #expect(viewModel.defaultExportDirectory?.path == "/tmp/exports")
    #expect(viewModel.status?.kind == .success)
}

@MainActor
@Test
func saveAsUpdatesDefaultDirectoryAfterSuccess() {
    let service = MockAppIconService()
    let store = InMemoryPreferencesStore()
    let appURL = URL(fileURLWithPath: "/Applications/Finder.app")
    let saveURL = URL(fileURLWithPath: "/tmp/custom/Finder Copy.png")
    service.loadedApp = LoadedApp(
        selectedApp: SelectedApp(url: appURL, displayName: "Finder"),
        icon: NSImage(size: NSSize(width: 64, height: 64))
    )
    service.nextSaveURL = saveURL

    let viewModel = ExportViewModel(service: service, preferencesStore: store)
    _ = viewModel.handleDroppedURLs([appURL])
    viewModel.saveAs()

    #expect(viewModel.defaultExportDirectory?.path == "/tmp/custom")
    #expect(store.savedDirectory?.path == "/tmp/custom")
}

@MainActor
@Test
func mainViewBuildsWithMockViewModel() {
    let viewModel = ExportViewModel(service: MockAppIconService(), preferencesStore: InMemoryPreferencesStore())
    _ = MainView(viewModel: viewModel)
}

private final class InMemoryPreferencesStore: PreferencesStoreing {
    var savedDirectory: URL?

    func loadDefaultDirectory() -> URL? {
        savedDirectory
    }

    func saveDefaultDirectory(_ url: URL?) {
        savedDirectory = url
    }
}

private func makeTestIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 64, height: 64))
    image.lockFocus()
    NSColor.systemBlue.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 64, height: 64)).fill()
    image.unlockFocus()
    return image
}

@MainActor
private final class MockAppIconService: AppIconService {
    var nextChosenApp: URL?
    var nextSourceDirectory: URL?
    var nextDirectory: URL?
    var nextSaveURL: URL?
    var loadedApp: LoadedApp?
    var loadedAppsByURL: [URL: LoadedApp] = [:]
    var scannedAppURLs: [URL] = []
    var directoryURLs = Set<URL>()
    var requestedSaveFileName: String?
    var writtenURL: URL?
    var writtenURLs: [URL] = []

    func chooseApp() -> URL? {
        nextChosenApp
    }

    func chooseSourceDirectory(current: URL?) -> URL? {
        nextSourceDirectory
    }

    func chooseDefaultDirectory(current: URL?) -> URL? {
        nextDirectory
    }

    func requestSaveLocation(suggestedFileName: String, defaultDirectory: URL?) -> URL? {
        requestedSaveFileName = suggestedFileName
        return nextSaveURL
    }

    func isAppBundle(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "app"
    }

    func isDirectory(_ url: URL) -> Bool {
        directoryURLs.contains(url)
    }

    func scanAppBundles(in directory: URL, recursive: Bool) throws -> [URL] {
        scannedAppURLs
    }

    func loadSelectedApp(at url: URL) throws -> LoadedApp {
        if let loadedApp = loadedAppsByURL[url] {
            return loadedApp
        }

        guard let loadedApp else {
            throw AppIconServiceError.unreadableBundle
        }
        return loadedApp
    }

    func pngData(for image: NSImage) throws -> Data {
        Data("png".utf8)
    }

    func buildExportURL(for app: SelectedApp, directory: URL) -> URL {
        directory.appendingPathComponent(app.exportFileName)
    }

    func confirmOverwrite(for url: URL) -> Bool {
        true
    }

    func writePNGData(_ data: Data, to url: URL) throws {
        writtenURL = url
        writtenURLs.append(url)
    }
}
