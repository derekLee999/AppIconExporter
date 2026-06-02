// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppIconExporter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AppIconExporter",
            targets: ["AppIconExporter"]
        ),
        .executable(
            name: "AppIconExporterApp",
            targets: ["AppIconExporterApp"]
        )
    ],
    targets: [
        .target(
            name: "AppIconExporter"
        ),
        .executableTarget(
            name: "AppIconExporterApp",
            dependencies: ["AppIconExporter"]
        ),
        .testTarget(
            name: "AppIconExporterTests",
            dependencies: ["AppIconExporter"]
        )
    ]
)
