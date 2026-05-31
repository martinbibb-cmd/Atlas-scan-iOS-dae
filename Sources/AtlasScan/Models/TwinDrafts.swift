import Foundation

// MARK: - SystemTwinDraft

/// Lightweight container for the System Twin draft.
///
/// Holds the IDs of `CaptureItem` records assigned to the system twin area.
/// Full twin assembly is deferred to a later PR.
public struct SystemTwinDraft: Identifiable, Codable, Sendable {
    public let id: UUID
    public var visitId: UUID
    public var captureItemIds: [UUID]

    public init(
        id: UUID = UUID(),
        visitId: UUID,
        captureItemIds: [UUID] = []
    ) {
        self.id = id
        self.visitId = visitId
        self.captureItemIds = captureItemIds
    }
}

// MARK: - HouseTwinDraft

/// Lightweight container for the House Twin draft.
///
/// Holds the IDs of `CaptureItem` records assigned to the house twin area.
public struct HouseTwinDraft: Identifiable, Codable, Sendable {
    public let id: UUID
    public var visitId: UUID
    public var captureItemIds: [UUID]

    public init(
        id: UUID = UUID(),
        visitId: UUID,
        captureItemIds: [UUID] = []
    ) {
        self.id = id
        self.visitId = visitId
        self.captureItemIds = captureItemIds
    }
}

// MARK: - HomeTwinDraft

/// Lightweight container for the Home Twin draft.
///
/// Holds the IDs of `CaptureItem` records assigned to the home twin area.
public struct HomeTwinDraft: Identifiable, Codable, Sendable {
    public let id: UUID
    public var visitId: UUID
    public var captureItemIds: [UUID]

    public init(
        id: UUID = UUID(),
        visitId: UUID,
        captureItemIds: [UUID] = []
    ) {
        self.id = id
        self.visitId = visitId
        self.captureItemIds = captureItemIds
    }
}
