import Foundation

public struct SelectedApp: Equatable, Sendable {
    public let url: URL
    public let displayName: String

    public init(url: URL, displayName: String) {
        self.url = url
        self.displayName = displayName
    }

    public var exportFileName: String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        let parts = displayName.components(separatedBy: invalidCharacters)
        let sanitized = parts.joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = sanitized.isEmpty ? url.deletingPathExtension().lastPathComponent : sanitized
        return "\(baseName).png"
    }

    public static func fallbackDisplayName(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }
}
