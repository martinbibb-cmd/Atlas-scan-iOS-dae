import Foundation

// MARK: - TwinArea

public enum TwinArea: String, Codable, CaseIterable, Sendable {
    case system
    case house
    case home
}

// MARK: - CaptureStatus

public enum CaptureStatus: String, Codable, CaseIterable, Sendable {
    case complete
    case needsReview
    case unknown
    case notRequired
    case assumed
}

// MARK: - CaptureItem

/// A single tagged item captured during a survey visit.
public struct CaptureItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public var visitId: UUID
    public var twinArea: TwinArea
    public var tag: ObjectTag
    public var status: CaptureStatus
    public let createdAt: Date
    public var updatedAt: Date
    public var spaceLabel: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        visitId: UUID,
        twinArea: TwinArea,
        tag: ObjectTag,
        status: CaptureStatus = .unknown,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        spaceLabel: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.visitId = visitId
        self.twinArea = twinArea
        self.tag = tag
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.spaceLabel = spaceLabel
        self.notes = notes
    }
}
