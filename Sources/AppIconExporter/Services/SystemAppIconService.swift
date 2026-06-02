import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
public final class SystemAppIconService: AppIconService {
    public init() {}

    public func chooseApp() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择应用程序"
        panel.prompt = "选择"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]
        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseSourceDirectory(current: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择扫描目录"
        panel.prompt = "扫描"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = current
        return panel.runModal() == .OK ? panel.url : nil
    }

    public func chooseDefaultDirectory(current: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择默认导出位置"
        panel.prompt = "选择文件夹"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = current
        return panel.runModal() == .OK ? panel.url : nil
    }

    public func requestSaveLocation(suggestedFileName: String, defaultDirectory: URL?) -> URL? {
        let panel = NSSavePanel()
        panel.title = "导出应用图标"
        panel.prompt = "导出"
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedFileName
        panel.directoryURL = defaultDirectory
        return panel.runModal() == .OK ? panel.url : nil
    }

    public func isAppBundle(_ url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "app" else {
            return false
        }

        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    public func isDirectory(_ url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    public func scanAppBundles(in directory: URL, recursive: Bool) throws -> [URL] {
        guard isDirectory(directory) else {
            throw AppIconServiceError.invalidAppBundle
        }

        if recursive {
            let keys: Set<URLResourceKey> = [.isDirectoryKey, .isPackageKey]
            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else {
                throw AppIconServiceError.unreadableBundle
            }

            var appURLs: [URL] = []
            for case let url as URL in enumerator {
                if isAppBundle(url) {
                    appURLs.append(url)
                    enumerator.skipDescendants()
                }
            }
            return appURLs.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return contents
            .filter { isAppBundle($0) }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }

    public func loadSelectedApp(at url: URL) throws -> LoadedApp {
        guard isAppBundle(url) else {
            throw AppIconServiceError.invalidAppBundle
        }

        let displayName = resolveDisplayName(for: url)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 512, height: 512)
        return LoadedApp(selectedApp: SelectedApp(url: url, displayName: displayName), icon: icon)
    }

    public func pngData(for image: NSImage) throws -> Data {
        guard
            let tiffRepresentation = image.tiffRepresentation,
            let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation),
            let pngData = bitmapImageRep.representation(using: .png, properties: [:])
        else {
            throw AppIconServiceError.iconEncodingFailed
        }

        return pngData
    }

    public func buildExportURL(for app: SelectedApp, directory: URL) -> URL {
        directory.appendingPathComponent(app.exportFileName, conformingTo: .png)
    }

    public func confirmOverwrite(for url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "要替换现有文件吗？"
        alert.informativeText = "“\(url.lastPathComponent)”已存在于该文件夹中。"
        alert.addButton(withTitle: "替换")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    public func writePNGData(_ data: Data, to url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: directoryURL.path) else {
            throw AppIconServiceError.directoryNotWritable
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw AppIconServiceError.fileWriteFailed
        }
    }

    private func resolveDisplayName(for url: URL) -> String {
        guard let bundle = Bundle(url: url) else {
            return SelectedApp.fallbackDisplayName(for: url)
        }

        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !displayName.isEmpty {
            return displayName
        }

        if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String, !bundleName.isEmpty {
            return bundleName
        }

        return SelectedApp.fallbackDisplayName(for: url)
    }
}
