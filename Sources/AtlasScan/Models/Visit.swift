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
    public var captureItems: [CaptureItem]
    public var evidenceRecords: [EvidenceRecord]
    public var surveyNudgeStates: [PersistedSurveyNudgeState]

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        status: VisitStatus = .draft,
        customerName: String? = nil,
        addressSummary: String? = nil,
        captureItems: [CaptureItem] = [],
        evidenceRecords: [EvidenceRecord] = [],
        surveyNudgeStates: [PersistedSurveyNudgeState] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.customerName = customerName
        self.addressSummary = addressSummary
        self.captureItems = captureItems
        self.evidenceRecords = evidenceRecords
        self.surveyNudgeStates = surveyNudgeStates
    }

    /// Returns `true` when the visit has a non-blank title.
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
        case updatedAt
        case status
        case customerName
        case addressSummary
        case captureItems
        case evidenceRecords
        case surveyNudgeStates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        status = try container.decode(VisitStatus.self, forKey: .status)
        customerName = try container.decodeIfPresent(String.self, forKey: .customerName)
        addressSummary = try container.decodeIfPresent(String.self, forKey: .addressSummary)
        captureItems = try container.decodeIfPresent([CaptureItem].self, forKey: .captureItems) ?? []
        evidenceRecords = try container.decodeIfPresent([EvidenceRecord].self, forKey: .evidenceRecords) ?? []
        surveyNudgeStates = try container.decodeIfPresent([PersistedSurveyNudgeState].self, forKey: .surveyNudgeStates) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(customerName, forKey: .customerName)
        try container.encodeIfPresent(addressSummary, forKey: .addressSummary)
        try container.encode(captureItems, forKey: .captureItems)
        try container.encode(evidenceRecords, forKey: .evidenceRecords)
        try container.encode(surveyNudgeStates, forKey: .surveyNudgeStates)
    }
}
