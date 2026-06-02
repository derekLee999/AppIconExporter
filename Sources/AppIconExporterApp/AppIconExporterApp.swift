import AppIconExporter
import AppKit
import SwiftUI

@main
struct AppIconExporterDesktopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel: ExportViewModel

    init() {
        let preferencesStore = UserDefaultsPreferencesStore()
        let service = SystemAppIconService()
        _viewModel = StateObject(
            wrappedValue: ExportViewModel(
                service: service,
                preferencesStore: preferencesStore
            )
        )
    }

    var body: some Scene {
        WindowGroup("应用图标导出器") {
            MainView(viewModel: viewModel)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("模式") {
                Button("切换批量/单个应用") {
                    viewModel.toggleMode()
                }
                .keyboardShortcut(.tab, modifiers: [])
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let windowCornerRadius: CGFloat = 30
    private var iconImage: NSImage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard
            let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let iconImage = NSImage(contentsOf: iconURL)
        else {
            return
        }

        self.iconImage = iconImage
        NSApplication.shared.applicationIconImage = iconImage
        configureWindows()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowBecameMain),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowDidResize),
            name: NSWindow.didResizeNotification,
            object: nil
        )
    }

    @objc
    private func handleWindowBecameMain(_ notification: Notification) {
        configureWindows()
    }

    @objc
    private func handleWindowDidResize(_ notification: Notification) {
        configureWindows()
    }

    private func configureWindows() {
        guard let iconImage else {
            return
        }

        for window in NSApplication.shared.windows {
            guard shouldApplyCustomChrome(to: window) else {
                continue
            }

            window.miniwindowImage = iconImage
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.remove(.titled)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = windowCornerRadius
            window.contentView?.layer?.cornerCurve = .continuous
            window.contentView?.layer?.masksToBounds = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }

    private func shouldApplyCustomChrome(to window: NSWindow) -> Bool {
        guard !(window is NSPanel) else {
            return false
        }

        return window.title == "应用图标导出器"
    }
}
