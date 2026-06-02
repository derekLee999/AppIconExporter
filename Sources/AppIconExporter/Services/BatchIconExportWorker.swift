import Foundation
import ImageIO
import UniformTypeIdentifiers

enum BatchIconExportResult: Sendable {
    case success(URL)
    case skipped(String)
    case failure(String)
}

enum BatchIconExportWorker {
    static func export(
        tiffData: Data,
        app: SelectedApp,
        directory: URL,
        reservedFileNames: Set<String>,
        autoNumberDuplicateFiles: Bool
    ) -> BatchIconExportResult {
        do {
            let initialURL = directory.appendingPathComponent(app.exportFileName, conformingTo: .png)
            let targetURL: URL
            if autoNumberDuplicateFiles {
                targetURL = uniqueExportURL(
                    initialURL: initialURL,
                    reservedFileNames: reservedFileNames
                )
            } else {
                guard !reservedFileNames.contains(initialURL.lastPathComponent),
                      !FileManager.default.fileExists(atPath: initialURL.path)
                else {
                    return .skipped("文件已存在：\(initialURL.lastPathComponent)")
                }
                targetURL = initialURL
            }

            let pngData = try pngData(fromTIFFData: tiffData)
            try writePNGData(pngData, to: targetURL)
            return .success(targetURL)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private static func pngData(fromTIFFData data: Data) throws -> Data {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw AppIconServiceError.iconEncodingFailed
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw AppIconServiceError.iconEncodingFailed
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw AppIconServiceError.iconEncodingFailed
        }

        return output as Data
    }

    private static func uniqueExportURL(
        initialURL: URL,
        reservedFileNames: Set<String>
    ) -> URL {
        let baseName = initialURL.deletingPathExtension().lastPathComponent
        let fileExtension = initialURL.pathExtension.isEmpty ? "png" : initialURL.pathExtension
        let directory = initialURL.deletingLastPathComponent()
        var candidate = initialURL
        var index = 2

        while reservedFileNames.contains(candidate.lastPathComponent)
            || FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) \(index).\(fileExtension)")
            index += 1
        }

        return candidate
    }

    private static func writePNGData(_ data: Data, to url: URL) throws {
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
}
