import Foundation

public enum ExportStatusKind: Equatable, Sendable {
    case success
    case error
}

public struct ExportStatus: Equatable, Sendable {
    public let kind: ExportStatusKind
    public let message: String

    public init(kind: ExportStatusKind, message: String) {
        self.kind = kind
        self.message = message
    }
}

public enum DragValidationState: Equatable, Sendable {
    case idle
    case targeted
    case rejected
}
