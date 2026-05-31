import Foundation

public struct AtlasVisitMediaManifestEntry: Codable, Sendable, Equatable {
    public let evidenceId: UUID
    public let relativePath: String
    public let evidenceType: EvidenceType
    public let captureItemId: UUID?
    public let fileSizeBytes: Int64?
    public let checksum: String?

    public init(
        evidenceId: UUID,
        relativePath: String,
        evidenceType: EvidenceType,
        captureItemId: UUID? = nil,
        fileSizeBytes: Int64? = nil,
        checksum: String? = nil
    ) {
        self.evidenceId = evidenceId
        self.relativePath = relativePath
        self.evidenceType = evidenceType
        self.captureItemId = captureItemId
        self.fileSizeBytes = fileSizeBytes
        self.checksum = checksum
    }
}

public struct AtlasVisitPackage: Codable, Sendable {
    public let packageId: UUID
    public let schemaVersion: String
    public let exportedAt: Date
    public let sourceApp: String

    public let visit: Visit
    public let captureItems: [CaptureItem]
    public let evidenceRecords: [EvidenceRecord]
    public let surveyNudgeStates: [String: SurveyNudgeState]
    public let progressSummary: VisitProgressSummary
    public let mediaManifest: [AtlasVisitMediaManifestEntry]

    public init(
        packageId: UUID = UUID(),
        schemaVersion: String = "1.0",
        exportedAt: Date = Date(),
        sourceApp: String = "atlas-scan-ios-dae",
        visit: Visit,
        captureItems: [CaptureItem],
        evidenceRecords: [EvidenceRecord],
        surveyNudgeStates: [String: SurveyNudgeState] = [:],
        progressSummary: VisitProgressSummary,
        mediaManifest: [AtlasVisitMediaManifestEntry]
    ) {
        self.packageId = packageId
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.sourceApp = sourceApp
        self.visit = visit
        self.captureItems = captureItems
        self.evidenceRecords = evidenceRecords
        self.surveyNudgeStates = surveyNudgeStates
        self.progressSummary = progressSummary
        self.mediaManifest = mediaManifest
    }
}
