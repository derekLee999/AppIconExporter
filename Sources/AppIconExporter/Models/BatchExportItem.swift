import AppKit
import Foundation

public enum BatchExportState: Equatable, Sendable {
    case pending
    case exporting
    case exported(URL)
    case skipped(String)
    case failed(String)

    public var displayText: String {
        switch self {
        case .pending:
            return "等待"
        case .exporting:
            return "导出中"
        case .exported:
            return "已导出"
        case .skipped:
            return "已跳过"
        case .failed:
            return "无法读取"
        }
    }
}

public struct BatchExportItem: Identifiable {
    public let selectedApp: SelectedApp
    public let icon: NSImage?
    public var state: BatchExportState

    public init(selectedApp: SelectedApp, icon: NSImage?, state: BatchExportState = .pending) {
        self.selectedApp = selectedApp
        self.icon = icon
        self.state = state
    }

    public var id: String {
        selectedApp.url.path
    }

    public var exportFileName: String {
        selectedApp.exportFileName
    }

    public var canExport: Bool {
        icon != nil
    }
}
