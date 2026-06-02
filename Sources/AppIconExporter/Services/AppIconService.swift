import AppKit
import Foundation

public struct LoadedApp {
    public let selectedApp: SelectedApp
    public let icon: NSImage

    public init(selectedApp: SelectedApp, icon: NSImage) {
        self.selectedApp = selectedApp
        self.icon = icon
    }
}

public enum AppIconServiceError: LocalizedError {
    case invalidAppBundle
    case unreadableBundle
    case iconEncodingFailed
    case directoryNotWritable
    case fileWriteFailed
    case exportCancelled

    public var errorDescription: String? {
        switch self {
        case .invalidAppBundle:
            return "仅支持 .app 应用程序。"
        case .unreadableBundle:
            return "无法读取所选应用。"
        case .iconEncodingFailed:
            return "无法将图标转换为 PNG 数据。"
        case .directoryNotWritable:
            return "目标文件夹不可写。"
        case .fileWriteFailed:
            return "写入导出文件失败。"
        case .exportCancelled:
            return "已取消导出。"
        }
    }
}

@MainActor
public protocol AppIconService: AnyObject {
    func chooseApp() -> URL?
    func chooseSourceDirectory(current: URL?) -> URL?
    func chooseDefaultDirectory(current: URL?) -> URL?
    func requestSaveLocation(suggestedFileName: String, defaultDirectory: URL?) -> URL?
    func isAppBundle(_ url: URL) -> Bool
    func isDirectory(_ url: URL) -> Bool
    func scanAppBundles(in directory: URL, recursive: Bool) throws -> [URL]
    func loadSelectedApp(at url: URL) throws -> LoadedApp
    func pngData(for image: NSImage) throws -> Data
    func buildExportURL(for app: SelectedApp, directory: URL) -> URL
    func confirmOverwrite(for url: URL) -> Bool
    func writePNGData(_ data: Data, to url: URL) throws
}
