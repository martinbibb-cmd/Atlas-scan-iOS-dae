import Foundation

// MARK: - EvidenceType

public enum EvidenceType: String, Codable, CaseIterable, Sendable {
    case photo
    case video
    case voice
    case manualNote
}

// MARK: - ProvenanceLevel

public enum ProvenanceLevel: String, Codable, CaseIterable, Sendable {
    /// Directly captured by the surveyor on site.
    case surveyor
    /// Inferred from other captured evidence.
    case inferred
    /// Assumed based on survey defaults or prior knowledge.
    case assumed
    /// Stated verbally or in writing by the customer.
    case customerStated
}

// MARK: - EvidenceRecord

/// A single piece of evidence attached to a visit or capture item.
public struct EvidenceRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public var visitId: UUID
    public var captureItemId: UUID?
    public var evidenceType: EvidenceType
    public let createdAt: Date
    public var localUri: String?
    public var voiceDurationSeconds: TimeInterval?
    public var transcript: String?
    public var provenanceLevel: ProvenanceLevel

    public init(
        id: UUID = UUID(),
        visitId: UUID,
        captureItemId: UUID? = nil,
        evidenceType: EvidenceType,
        createdAt: Date = Date(),
        localUri: String? = nil,
        voiceDurationSeconds: TimeInterval? = nil,
        transcript: String? = nil,
        provenanceLevel: ProvenanceLevel = .surveyor
    ) {
        self.id = id
        self.visitId = visitId
        self.captureItemId = captureItemId
        self.evidenceType = evidenceType
        self.createdAt = createdAt
        self.localUri = localUri
        self.voiceDurationSeconds = voiceDurationSeconds
        self.transcript = transcript
        self.provenanceLevel = provenanceLevel
    }

    /// Returns `true` when the record contains its required payload.
    ///
    /// - Photo, video and voice records require a `localUri`.
    /// - Manual note records require a non-blank `transcript`.
    public var isValid: Bool {
        switch evidenceType {
        case .photo, .video, .voice:
            return localUri != nil
        case .manualNote:
            guard let t = transcript else { return false }
            return !t.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
}
