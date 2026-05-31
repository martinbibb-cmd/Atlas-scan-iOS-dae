import Foundation

public enum FieldTestIssueCategory: String, Codable, CaseIterable, Sendable {
    case captureFriction = "capture friction"
    case missingObjectTag = "missing object tag"
    case confusingNudge = "confusing nudge"
    case mediaProblem = "media problem"
    case exportProblem = "export problem"
    case uiReachProblem = "UI reach/problem"
    case other

    public var displayName: String {
        switch self {
        case .captureFriction: return "Capture Friction"
        case .missingObjectTag: return "Missing Object Tag"
        case .confusingNudge: return "Confusing Nudge"
        case .mediaProblem: return "Media Problem"
        case .exportProblem: return "Export Problem"
        case .uiReachProblem: return "UI Reach/Problem"
        case .other: return "Other"
        }
    }
}

public struct FieldTestNote: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let createdAt: Date
    public var category: FieldTestIssueCategory
    public var details: String
    public var photoLocalUri: String?
    public var voiceLocalUri: String?
    public var voiceDurationSeconds: TimeInterval?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        category: FieldTestIssueCategory,
        details: String,
        photoLocalUri: String? = nil,
        voiceLocalUri: String? = nil,
        voiceDurationSeconds: TimeInterval? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.category = category
        self.details = details
        self.photoLocalUri = photoLocalUri
        self.voiceLocalUri = voiceLocalUri
        self.voiceDurationSeconds = voiceDurationSeconds
    }
}
