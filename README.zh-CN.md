<div align="center">
  <img src="Assets/app-icon-compact.png" alt="App Icon Exporter 图标" width="120" height="120">

  # 应用图标导出器

  从 macOS `.app` 应用包中提取图标，并导出为干净可复用的 PNG 文件。

  [English](README.md) · 简体中文 · [功能特性](#功能特性) · [快速开始](#快速开始) · [签名说明](#developer-id-signing)
</div>

## 概述

应用图标导出器是一个基于 macOS SwiftUI 的桌面工具，用于浏览应用包、预览应用图标，并将图标导出为 PNG 文件。

它同时支持单个应用导出和批量目录扫描导出，并附带用于生成签名 `.app` 与 `.dmg` 的发布打包脚本。

## 功能特性

- 导出单个已选择或拖入的 `.app` 应用图标。
- 批量扫描目录中的 `.app` 应用并一次性导出全部图标。
- 导出前预览应用图标。
- 选择并持久化默认导出目录。
- 直接在应用内打开导出目录。
- 当输出文件重名时，可自动追加序号或跳过重复文件。
- 可选递归扫描子目录。
- 提供定制化的 macOS 无边框窗口界面。

## 快速开始

### 环境要求

- macOS 14 或更高版本
- 带 Swift 6 工具链的 Xcode
- Swift Package Manager

### 构建

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

### 运行

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run AppIconExporterApp
```

### 测试

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## 构建、运行与打包

生成发布用 `.app` 应用包和 `.dmg`：

```bash
./scripts/build-dmg.sh
```

打包产物会输出到 `dist/` 目录。

## 打包说明

打包脚本会生成以下内容：

- `dist/应用图标导出器.app`
- `dist/应用图标导出器.dmg`

同时它还会根据 `Assets/` 中的源 PNG 自动生成应用使用的 `.icns` 图标资源。

<a id="developer-id-signing"></a>

## Developer ID 签名

`./scripts/build-dmg.sh` 的签名优先级如下：

1. 如果当前钥匙串里存在可用的 `Developer ID Application` 身份，优先使用它。
2. 如果没有 Apple 签发的证书，则回退到项目本地的测试签名身份。

如果你需要手动初始化本地测试签名：

```bash
./scripts/ensure-local-signing.sh
```

如果你想强制使用 ad-hoc 签名进行单次打包：

```bash
SIGN_IDENTITY=- ./scripts/build-dmg.sh
```

如果你想显式指定签名身份：

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-dmg.sh
```

如果你的钥匙串中只有一个有效的 `Developer ID Application` 身份，打包脚本会自动选中它。

需要注意的是，`Developer ID` 签名并不等于完整对外分发。若要让 Gatekeeper 在其他 Mac 上正常放行，通常还需要额外完成 notarization（公证）。

## 项目结构

- `Package.swift` — Swift 包定义。
- `Sources/AppIconExporter` — 模型、服务、ViewModel 与 SwiftUI 视图。
- `Sources/AppIconExporterApp` — macOS 应用入口与窗口配置。
- `Tests/AppIconExporterTests` — 单元测试。
- `Assets` — 应用图标生成所需的源素材。
- `scripts/build-dmg.sh` — 发布打包脚本。
- `scripts/ensure-local-signing.sh` — 本地测试签名初始化脚本。
- `docs` — 方案与规划文档。
- `mockups` — 设计阶段使用的界面草图。
