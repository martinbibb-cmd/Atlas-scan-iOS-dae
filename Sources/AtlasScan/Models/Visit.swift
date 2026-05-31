import Foundation

// MARK: - VisitStatus

public enum VisitStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case completed
    case exported
}

// MARK: - Visit

/// Represents a single survey visit to a property.
public struct Visit: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public let createdAt: Date
    public var updatedAt: Date
    public var status: VisitStatus
    public var customerName: String?
    public var addressSummary: String?

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: VisitStatus = .draft,
        customerName: String? = nil,
        addressSummary: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.customerName = customerName
        self.addressSummary = addressSummary
    }

    /// Returns `true` when the visit has a non-blank title.
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
