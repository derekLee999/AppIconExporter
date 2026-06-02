import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject private var viewModel: ExportViewModel

    public init(viewModel: ExportViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().opacity(0.35)
            workspace
        }
        .background {
            panelBackground
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .frame(minWidth: 1180, minHeight: 760)
        .background(Color.clear)
        .background(TabKeyShortcutHandler {
            viewModel.toggleMode()
        })
    }

    private var panelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.96, blue: 1.0),
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.88, green: 0.94, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.17, green: 0.82, blue: 1.0).opacity(0.26))
                .frame(width: 420, height: 420)
                .blur(radius: 40)
                .offset(x: -430, y: -280)

            Circle()
                .fill(Color(red: 1.0, green: 0.66, blue: 0.12).opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .offset(x: 500, y: -310)

            GridPattern()
                .stroke(Color.black.opacity(0.035), lineWidth: 1)
                .mask(
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                )
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            draggableHeader
            modePicker
            dropPanel
            pathCard(title: "扫描来源", value: viewModel.sourceDirectory?.path ?? "未选择", buttonTitle: "更换") {
                viewModel.chooseSourceDirectory()
            }
            pathCard(
                title: "导出位置",
                value: viewModel.defaultExportDirectory?.path ?? "未设置",
                leadingButtonTitle: "打开",
                leadingAction: {
                    viewModel.openDefaultExportDirectory()
                },
                buttonTitle: "设置"
            ) {
                viewModel.chooseDefaultExportDirectory()
            }
            Spacer(minLength: 8)
            optionRows
        }
        .padding(24)
        .frame(width: 330)
        .background(Color.white.opacity(0.30))
    }

    private var draggableHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            trafficLights
            brand
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WindowDragArea())
    }

    private var trafficLights: some View {
        HStack(spacing: 4) {
            WindowControlButton(
                label: "关闭",
                symbolName: "xmark",
                color: Color(red: 1.0, green: 0.37, blue: 0.34)
            ) {
                closeActiveWindow()
            }
            WindowControlButton(
                label: "最小化",
                symbolName: "minus",
                color: Color(red: 1.0, green: 0.74, blue: 0.18)
            ) {
                activeWindow?.miniaturize(nil)
            }
            WindowControlButton(
                label: "全屏",
                symbolName: "arrow.up.left.and.arrow.down.right",
                color: Color(red: 0.16, green: 0.78, blue: 0.25)
            ) {
                activeWindow?.toggleFullScreen(nil)
            }
        }
    }

    private var activeWindow: NSWindow? {
        NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow ?? NSApplication.shared.windows.first
    }

    private func closeActiveWindow() {
        if let activeWindow {
            activeWindow.close()
        } else {
            NSApplication.shared.terminate(nil)
        }
    }

    private var brand: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.17, green: 0.82, blue: 1.0),
                            Color(red: 0.09, green: 0.47, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: Color.blue.opacity(0.24), radius: 16, y: 8)
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("应用图标导出器")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("批量提取 macOS .app 图标")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            modeButton("批量目录", mode: .batch)
            modeButton("单个应用", mode: .single)
        }
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(Color.black.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func modeButton(_ title: String, mode: ExportMode) -> some View {
        Button {
            viewModel.setMode(mode)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(viewModel.mode == mode ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.vertical, 9)
                .background(
                    Group {
                        if viewModel.mode == mode {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                        }
                    }
                )
                .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

    private var dropPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.blue.opacity(0.12), radius: 14, y: 7)
                Image(systemName: viewModel.mode == .batch ? "folder.badge.plus" : "app.dashed")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.blue)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.mode == .batch ? "拖入目录或选择文件夹" : "拖入单个 .app")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .lineLimit(2)
                Text(viewModel.mode == .batch
                    ? "扫描目录中的 .app，生成应用清单后可一次性导出全部图标。"
                    : "预览单个应用图标，并导出为 PNG。"
                )
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
            }

            Button {
                if viewModel.mode == .batch {
                    viewModel.chooseSourceDirectory()
                } else {
                    viewModel.chooseApp()
                }
            } label: {
                Text(viewModel.mode == .batch ? "选择目录" : "选择 .app")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.09, green: 0.13, blue: 0.21))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
        .background(dropBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(dropStroke, style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
        )
        .dropDestination(for: URL.self) { items, _ in
            viewModel.handleDroppedURLs(items)
        } isTargeted: { isTargeted in
            viewModel.setDropTargetActive(isTargeted)
        }
    }

    private func pathCard(
        title: String,
        value: String,
        leadingButtonTitle: String? = nil,
        leadingAction: (() -> Void)? = nil,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if let leadingButtonTitle, let leadingAction {
                    Button(leadingButtonTitle, action: leadingAction)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Button(buttonTitle, action: action)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(14)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
    }

    private var optionRows: some View {
        VStack(spacing: 12) {
            optionRow(title: "递归扫描子目录", isOn: viewModel.isRecursiveScan) {
                viewModel.toggleRecursiveScan()
            }
            optionRow(title: "重名时自动加序号（关闭则跳过）", isOn: viewModel.autoNumberDuplicateFiles) {
                viewModel.toggleAutoNumberDuplicateFiles()
            }
        }
    }

    private func optionRow(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                TogglePill(isOn: isOn)
            }
        }
        .buttonStyle(.plain)
    }

    private var workspace: some View {
        VStack(spacing: 18) {
            topbar
            statsGrid

            if viewModel.mode == .batch {
                batchTable
                progressFooter
            } else {
                singlePreview
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var topbar: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.mode == .batch
                    ? "准备导出 \(viewModel.discoveredAppCount) 个图标"
                    : "单个应用导出"
                )
                .font(.system(size: 30, weight: .bold, design: .rounded))

                Text(viewModel.mode == .batch
                    ? "先预览扫描结果，再执行批量导出；失败项会保留在列表中方便处理。"
                    : "选择或拖入一个 .app，确认预览后导出为 PNG。"
                )
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                if viewModel.mode == .batch {
                    Button("重新扫描") {
                        viewModel.rescanSourceDirectory()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isExporting)

                    Button(viewModel.isExporting ? "导出中..." : "导出全部") {
                        viewModel.exportAll()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.09, green: 0.47, blue: 1.0))
                    .disabled(viewModel.batchItems.isEmpty || viewModel.isExporting)
                } else {
                    Button("另存为...") {
                        viewModel.saveAs()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isExporting)

                    Button(viewModel.isExporting ? "导出中..." : "导出") {
                        viewModel.export()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.09, green: 0.47, blue: 1.0))
                    .disabled(viewModel.isExporting)
                }
            }
            .controlSize(.large)
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(value: "\(viewModel.discoveredAppCount)", label: "发现应用")
            statCard(value: "\(viewModel.pendingExportCount)", label: "等待导出")
            statCard(value: "\(viewModel.exportedCount)", label: "已完成")
            statCard(value: "\(viewModel.failedCount)", label: "需处理")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.70), lineWidth: 1)
        )
    }

    private var batchTable: some View {
        VStack(spacing: 0) {
            HStack {
                tableHeader("应用", width: nil)
                tableHeader("来源目录", width: nil)
                tableHeader("文件名", width: 138)
                tableHeader("状态", width: 96)
            }
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(Color.black.opacity(0.04))

            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.batchItems.isEmpty {
                        emptyBatchState
                    } else {
                        ForEach(viewModel.batchItems) { item in
                            BatchRow(item: item)
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func tableHeader(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private var emptyBatchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(Color.blue.opacity(0.62))
            Text("选择一个目录开始扫描")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text("扫描完成后，这里会显示所有可导出的 .app 图标。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var progressFooter: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.currentExportSummary)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                ProgressView(value: viewModel.exportProgressFraction)
                    .tint(Color(red: 0.18, green: 0.86, blue: 1.0))
            }
            Spacer()
            Text("\(viewModel.exportedCount + viewModel.skippedCount + viewModel.failedCount) / \(viewModel.discoveredAppCount) 完成")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color(red: 0.09, green: 0.13, blue: 0.21).opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            if let status = viewModel.status {
                statusChip(status)
                    .offset(y: -42)
            }
        }
    }

    private var singlePreview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                VStack(spacing: 18) {
                    if let previewImage = viewModel.previewImage {
                        Image(nsImage: previewImage)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .shadow(color: Color.black.opacity(0.12), radius: 20, y: 12)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 82, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 220, height: 220)
                    }

                    Text(viewModel.selectedApp?.displayName ?? "请选择或拖入一个 .app 应用")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.selectedApp == nil ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .background(Color.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                Spacer()
            }

            pathCard(title: "导出文件名", value: viewModel.exportFileNamePreview, buttonTitle: "选择应用") {
                viewModel.chooseApp()
            }

            if let status = viewModel.status {
                statusBanner(status)
            }

            Spacer()
        }
    }

    private func statusChip(_ status: ExportStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: status.kind == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            Text(status.message)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(status.kind == .success ? Color(red: 0.02, green: 0.46, blue: 0.26) : Color(red: 0.70, green: 0.14, blue: 0.10))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.92), in: Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
    }

    private func statusBanner(_ status: ExportStatus) -> some View {
        HStack(spacing: 10) {
            Image(systemName: status.kind == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(status.kind == .success ? .green : .orange)
            Text(status.message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .textSelection(.enabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dropBackground: some ShapeStyle {
        switch viewModel.dragState {
        case .idle:
            return AnyShapeStyle(LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.cyan.opacity(0.08), Color.white.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case .targeted:
            return AnyShapeStyle(Color.blue.opacity(0.15))
        case .rejected:
            return AnyShapeStyle(Color.orange.opacity(0.14))
        }
    }

    private var dropStroke: Color {
        switch viewModel.dragState {
        case .idle:
            return Color.blue.opacity(0.48)
        case .targeted:
            return Color.blue
        case .rejected:
            return Color.orange
        }
    }
}

private struct BatchRow: View {
    let item: BatchExportItem

    var body: some View {
        HStack(spacing: 14) {
            appCell
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.selectedApp.url.deletingLastPathComponent().path)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.exportFileName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 138, alignment: .leading)
            badge
                .frame(width: 96, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 70)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
        }
    }

    private var appCell: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                if let icon = item.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(4)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.selectedApp.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(item.selectedApp.url.path)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var badge: some View {
        Text(item.state.displayText)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(badgeForeground)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(badgeBackground, in: Capsule())
    }

    private var badgeForeground: Color {
        switch item.state {
        case .pending:
            return Color(red: 0.55, green: 0.35, blue: 0.0)
        case .exporting:
            return Color.blue
        case .exported:
            return Color(red: 0.02, green: 0.46, blue: 0.26)
        case .skipped:
            return Color(red: 0.45, green: 0.45, blue: 0.50)
        case .failed:
            return Color(red: 0.70, green: 0.14, blue: 0.10)
        }
    }

    private var badgeBackground: Color {
        switch item.state {
        case .pending:
            return Color.orange.opacity(0.16)
        case .exporting:
            return Color.blue.opacity(0.14)
        case .exported:
            return Color.green.opacity(0.12)
        case .skipped:
            return Color.gray.opacity(0.14)
        case .failed:
            return Color.red.opacity(0.14)
        }
    }
}

private struct TogglePill: View {
    let isOn: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 99, style: .continuous)
            .fill(isOn ? Color.blue : Color.black.opacity(0.12))
            .frame(width: 42, height: 24)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(3)
                    .shadow(color: Color.black.opacity(0.22), radius: 4, y: 2)
            }
    }
}

private struct WindowControlButton: View {
    let label: String
    let symbolName: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)

                Image(systemName: symbolName)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.black.opacity(0.58))
                    .scaleEffect(isHovered ? 1 : 0.4)
                    .opacity(isHovered ? 1 : 0)
            }
            .frame(width: 16, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .onHover { isHovered = $0 }
    }
}

private struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool {
            true
        }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 48
        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }

        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }
        return path
    }
}

private struct TabKeyShortcutHandler: NSViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.installMonitor()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.action = action
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        var action: () -> Void
        private var monitor: Any?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        func installMonitor() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard
                    event.keyCode == 48,
                    event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
                else {
                    return event
                }

                self?.action()
                return nil
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }
    }
}
