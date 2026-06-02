import AppKit
import Foundation
import Observation

public enum ExportMode: Equatable, Sendable {
    case batch
    case single
}

@MainActor
public final class ExportViewModel: ObservableObject {
    @Published public private(set) var mode: ExportMode = .batch
    @Published public private(set) var selectedApp: SelectedApp?
    @Published public private(set) var previewImage: NSImage?
    @Published public private(set) var sourceDirectory: URL?
    @Published public private(set) var batchItems: [BatchExportItem] = []
    @Published public private(set) var status: ExportStatus?
    @Published public private(set) var dragState: DragValidationState = .idle
    @Published public private(set) var isExporting = false
    @Published public private(set) var isRecursiveScan = false
    @Published public private(set) var autoNumberDuplicateFiles = true
    @Published public private(set) var currentExportIndex = 0
    @Published public private(set) var defaultExportDirectory: URL?

    private let service: AppIconService
    private let preferencesStore: PreferencesStoreing
    private var batchExportTask: Task<Void, Never>?

    public init(
        service: AppIconService,
        preferencesStore: PreferencesStoreing = UserDefaultsPreferencesStore()
    ) {
        self.service = service
        self.preferencesStore = preferencesStore
        self.defaultExportDirectory = preferencesStore.loadDefaultDirectory()
    }

    public var exportFileNamePreview: String {
        selectedApp?.exportFileName ?? "应用名称.png"
    }

    public var discoveredAppCount: Int {
        batchItems.count
    }

    public var pendingExportCount: Int {
        batchItems.filter { $0.state == .pending }.count
    }

    public var exportedCount: Int {
        batchItems.filter {
            if case .exported = $0.state {
                return true
            }
            return false
        }.count
    }

    public var failedCount: Int {
        batchItems.filter {
            if case .failed = $0.state {
                return true
            }
            return false
        }.count
    }

    public var skippedCount: Int {
        batchItems.filter {
            if case .skipped = $0.state {
                return true
            }
            return false
        }.count
    }

    public var exportProgressFraction: Double {
        guard !batchItems.isEmpty else {
            return 0
        }
        return Double(exportedCount + skippedCount + failedCount) / Double(batchItems.count)
    }

    public var currentExportSummary: String {
        guard isExporting else {
            return batchItems.isEmpty ? "等待扫描目录" : "准备导出"
        }

        if let exportingItem = batchItems.first(where: {
            if case .exporting = $0.state {
                return true
            }
            return false
        }) {
            return "正在导出：\(exportingItem.exportFileName)"
        }

        return "正在导出"
    }

    public func setMode(_ mode: ExportMode) {
        guard !isExporting else {
            return
        }

        self.mode = mode
        dragState = .idle
        status = nil
    }

    public func toggleMode() {
        setMode(mode == .batch ? .single : .batch)
    }

    public func chooseApp() {
        guard !isExporting else {
            status = ExportStatus(kind: .error, message: "导出进行中，请等待完成后再切换应用。")
            return
        }

        guard let url = service.chooseApp() else {
            return
        }
        mode = .single
        loadApp(at: url)
    }

    public func chooseSourceDirectory() {
        guard !isExporting else {
            status = ExportStatus(kind: .error, message: "导出进行中，请等待完成后再更换目录。")
            return
        }

        guard let directory = service.chooseSourceDirectory(current: sourceDirectory) else {
            return
        }
        scanDirectory(directory)
    }

    public func chooseDefaultExportDirectory() {
        guard let directory = service.chooseDefaultDirectory(current: defaultExportDirectory) else {
            return
        }

        defaultExportDirectory = directory
        preferencesStore.saveDefaultDirectory(directory)
        status = ExportStatus(kind: .success, message: "默认导出位置已更新。")
    }

    public func openDefaultExportDirectory() {
        guard let defaultExportDirectory else {
            status = ExportStatus(kind: .error, message: "请先设置导出位置。")
            return
        }

        NSWorkspace.shared.open(defaultExportDirectory)
    }

    public func toggleRecursiveScan() {
        guard !isExporting else {
            status = ExportStatus(kind: .error, message: "导出进行中，请等待完成后再修改扫描方式。")
            return
        }

        isRecursiveScan.toggle()
        if let sourceDirectory {
            scanDirectory(sourceDirectory)
        }
    }

    public func toggleAutoNumberDuplicateFiles() {
        guard !isExporting else {
            status = ExportStatus(kind: .error, message: "导出进行中，请等待完成后再修改重名处理方式。")
            return
        }

        autoNumberDuplicateFiles.toggle()
    }

    public func rescanSourceDirectory() {
        guard !isExporting else {
            status = ExportStatus(kind: .error, message: "导出进行中，请等待完成后再重新扫描。")
            return
        }

        guard let sourceDirectory else {
            status = ExportStatus(kind: .error, message: "请先选择扫描目录。")
            return
        }
        scanDirectory(sourceDirectory)
    }

    @discardableResult
    public func handleDroppedURLs(_ urls: [URL]) -> Bool {
        guard !isExporting else {
            status = ExportStatus(kind: .error, message: "导出进行中，请等待完成后再更换来源。")
            dragState = .rejected
            return false
        }

        guard urls.count == 1, let url = urls.first else {
            status = ExportStatus(kind: .error, message: "一次只能拖入一个目录或 .app 应用。")
            dragState = .rejected
            return false
        }

        if service.isDirectory(url), !service.isAppBundle(url) {
            mode = .batch
            scanDirectory(url)
            return true
        }

        guard service.isAppBundle(url) else {
            status = ExportStatus(kind: .error, message: "这里只接受目录或 .app 应用。")
            dragState = .rejected
            return false
        }

        mode = .single
        loadApp(at: url)
        return true
    }

    public func setDropTargetActive(_ isActive: Bool) {
        if isActive {
            dragState = .targeted
        } else if dragState != .rejected {
            dragState = .idle
        }
    }

    public func export() {
        guard let selectedApp, let previewImage else {
            status = ExportStatus(kind: .error, message: "请先选择一个应用。")
            return
        }

        if let defaultExportDirectory {
            let targetURL = service.buildExportURL(for: selectedApp, directory: defaultExportDirectory)
            guard service.confirmOverwrite(for: targetURL) else {
                status = ExportStatus(kind: .error, message: "已取消导出。")
                return
            }
            writeExport(image: previewImage, for: selectedApp, to: targetURL, updatesDefaultDirectory: false)
            return
        }

        savePanelExport(selectedApp: selectedApp, previewImage: previewImage)
    }

    public func saveAs() {
        guard let selectedApp, let previewImage else {
            status = ExportStatus(kind: .error, message: "请先选择一个应用。")
            return
        }

        savePanelExport(selectedApp: selectedApp, previewImage: previewImage)
    }

    @discardableResult
    public func exportAll() -> Task<Void, Never>? {
        guard !batchItems.isEmpty else {
            status = ExportStatus(kind: .error, message: "请先扫描一个包含 .app 的目录。")
            return nil
        }

        guard let defaultExportDirectory else {
            status = ExportStatus(kind: .error, message: "请先设置导出位置。")
            return nil
        }

        guard !isExporting else {
            return batchExportTask
        }

        isExporting = true
        currentExportIndex = 0
        status = nil

        let task = Task { [weak self] in
            guard let self else {
                return
            }
            await self.performBatchExport(to: defaultExportDirectory)
        }
        batchExportTask = task
        return task
    }

    private func performBatchExport(to defaultExportDirectory: URL) async {
        var usedFileNames = Set<String>()

        for index in batchItems.indices {
            guard !Task.isCancelled else {
                break
            }

            currentExportIndex = index + 1
            guard let icon = batchItems[index].icon else {
                if case .failed = batchItems[index].state {
                    continue
                }
                batchItems[index].state = .failed("无法读取图标。")
                continue
            }

            batchItems[index].state = .exporting

            guard let tiffData = icon.tiffRepresentation else {
                batchItems[index].state = .failed(AppIconServiceError.iconEncodingFailed.localizedDescription)
                await Task.yield()
                continue
            }

            let app = batchItems[index].selectedApp
            let reservedFileNames = usedFileNames
            let autoNumberDuplicateFiles = autoNumberDuplicateFiles
            let result = await Task.detached(priority: .userInitiated) {
                BatchIconExportWorker.export(
                    tiffData: tiffData,
                    app: app,
                    directory: defaultExportDirectory,
                    reservedFileNames: reservedFileNames,
                    autoNumberDuplicateFiles: autoNumberDuplicateFiles
                )
            }.value

            switch result {
            case let .success(targetURL):
                usedFileNames.insert(targetURL.lastPathComponent)
                batchItems[index].state = .exported(targetURL)
            case let .skipped(message):
                batchItems[index].state = .skipped(message)
            case let .failure(message):
                batchItems[index].state = .failed(message)
            }

            await Task.yield()
        }

        isExporting = false
        batchExportTask = nil
        let exportedCount = exportedCount
        let skippedCount = skippedCount
        let failedCount = failedCount
        if skippedCount == 0, failedCount == 0 {
            status = ExportStatus(kind: .success, message: "已导出 \(exportedCount) 个图标。")
        } else if failedCount == 0 {
            status = ExportStatus(kind: .success, message: "已导出 \(exportedCount) 个图标，跳过 \(skippedCount) 个重名文件。")
        } else {
            status = ExportStatus(kind: .error, message: "已导出 \(exportedCount) 个图标，跳过 \(skippedCount) 个，\(failedCount) 个失败。")
        }
    }

    private func savePanelExport(selectedApp: SelectedApp, previewImage: NSImage) {
        guard let saveURL = service.requestSaveLocation(
            suggestedFileName: selectedApp.exportFileName,
            defaultDirectory: defaultExportDirectory
        ) else {
            return
        }

        writeExport(image: previewImage, for: selectedApp, to: saveURL, updatesDefaultDirectory: true)
    }

    private func writeExport(image: NSImage, for app: SelectedApp, to url: URL, updatesDefaultDirectory: Bool) {
        isExporting = true
        defer { isExporting = false }

        do {
            let pngData = try service.pngData(for: image)
            try service.writePNGData(pngData, to: url)

            if updatesDefaultDirectory {
                let directory = url.deletingLastPathComponent()
                defaultExportDirectory = directory
                preferencesStore.saveDefaultDirectory(directory)
            }

            status = ExportStatus(kind: .success, message: "已导出到 \(url.path)")
            dragState = .idle
        } catch {
            status = ExportStatus(kind: .error, message: error.localizedDescription)
        }
    }

    private func scanDirectory(_ directory: URL) {
        do {
            let appURLs = try service.scanAppBundles(in: directory, recursive: isRecursiveScan)
            sourceDirectory = directory
            batchItems = appURLs.map { url in
                do {
                    let loadedApp = try service.loadSelectedApp(at: url)
                    return BatchExportItem(selectedApp: loadedApp.selectedApp, icon: loadedApp.icon)
                } catch {
                    return BatchExportItem(
                        selectedApp: SelectedApp(
                            url: url,
                            displayName: SelectedApp.fallbackDisplayName(for: url)
                        ),
                        icon: nil,
                        state: .failed(error.localizedDescription)
                    )
                }
            }
            status = appURLs.isEmpty
                ? ExportStatus(kind: .error, message: "该目录没有找到 .app 应用。")
                : ExportStatus(kind: .success, message: "已发现 \(appURLs.count) 个应用。")
            dragState = .idle
        } catch {
            status = ExportStatus(kind: .error, message: error.localizedDescription)
            dragState = .rejected
        }
    }

    private func loadApp(at url: URL) {
        do {
            let loadedApp = try service.loadSelectedApp(at: url)
            selectedApp = loadedApp.selectedApp
            previewImage = loadedApp.icon
            status = nil
            dragState = .idle
        } catch {
            status = ExportStatus(kind: .error, message: error.localizedDescription)
            dragState = .rejected
        }
    }

}
