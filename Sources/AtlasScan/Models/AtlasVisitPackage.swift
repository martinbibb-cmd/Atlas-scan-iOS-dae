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

public struct AtlasVisitPackageExportSummary: Codable, Sendable, Equatable {
    public let captureItemCount: Int
    public let evidenceCount: Int
    public let mediaCount: Int
    public let missingMediaCount: Int
    public let unresolvedCount: Int

    public init(
        captureItemCount: Int,
        evidenceCount: Int,
        mediaCount: Int,
        missingMediaCount: Int,
        unresolvedCount: Int
    ) {
        self.captureItemCount = captureItemCount
        self.evidenceCount = evidenceCount
        self.mediaCount = mediaCount
        self.missingMediaCount = missingMediaCount
        self.unresolvedCount = unresolvedCount
    }
}

public struct AtlasVisitPackage: Codable, Sendable, Identifiable {
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
    public let missingMediaWarnings: [String]
    public let fieldTestNotes: [FieldTestNote]
    public let exportSummary: AtlasVisitPackageExportSummary

    public init(
        packageId: UUID = UUID(),
        schemaVersion: String = "1.1",
        exportedAt: Date = Date(),
        sourceApp: String = "atlas-scan-ios-dae",
        visit: Visit,
        captureItems: [CaptureItem],
        evidenceRecords: [EvidenceRecord],
        surveyNudgeStates: [String: SurveyNudgeState] = [:],
        progressSummary: VisitProgressSummary,
        mediaManifest: [AtlasVisitMediaManifestEntry],
        missingMediaWarnings: [String] = [],
        fieldTestNotes: [FieldTestNote] = [],
        exportSummary: AtlasVisitPackageExportSummary? = nil
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
        self.missingMediaWarnings = missingMediaWarnings
        self.fieldTestNotes = fieldTestNotes
        self.exportSummary = exportSummary ?? AtlasVisitPackageExportSummary(
            captureItemCount: captureItems.count,
            evidenceCount: evidenceRecords.count,
            mediaCount: mediaManifest.count,
            missingMediaCount: missingMediaWarnings.count,
            unresolvedCount: progressSummary.totalUnresolvedCount
        )
    }

    public var id: UUID { packageId }

    enum CodingKeys: String, CodingKey {
        case packageId
        case schemaVersion
        case exportedAt
        case sourceApp
        case visit
        case captureItems
        case evidenceRecords
        case surveyNudgeStates
        case progressSummary
        case mediaManifest
        case missingMediaWarnings
        case fieldTestNotes
        case exportSummary
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let packageId = try container.decode(UUID.self, forKey: .packageId)
        let schemaVersion = try container.decode(String.self, forKey: .schemaVersion)
        let exportedAt = try container.decode(Date.self, forKey: .exportedAt)
        let sourceApp = try container.decode(String.self, forKey: .sourceApp)
        let visit = try container.decode(Visit.self, forKey: .visit)
        let captureItems = try container.decode([CaptureItem].self, forKey: .captureItems)
        let evidenceRecords = try container.decode([EvidenceRecord].self, forKey: .evidenceRecords)
        let surveyNudgeStates = try container.decodeIfPresent([String: SurveyNudgeState].self, forKey: .surveyNudgeStates) ?? [:]
        let progressSummary = try container.decode(VisitProgressSummary.self, forKey: .progressSummary)
        let mediaManifest = try container.decode([AtlasVisitMediaManifestEntry].self, forKey: .mediaManifest)
        let missingMediaWarnings = try container.decodeIfPresent([String].self, forKey: .missingMediaWarnings) ?? []
        let fieldTestNotes = try container.decodeIfPresent([FieldTestNote].self, forKey: .fieldTestNotes) ?? []
        let exportSummary = try container.decodeIfPresent(AtlasVisitPackageExportSummary.self, forKey: .exportSummary)

        self.init(
            packageId: packageId,
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            sourceApp: sourceApp,
            visit: visit,
            captureItems: captureItems,
            evidenceRecords: evidenceRecords,
            surveyNudgeStates: surveyNudgeStates,
            progressSummary: progressSummary,
            mediaManifest: mediaManifest,
            missingMediaWarnings: missingMediaWarnings,
            fieldTestNotes: fieldTestNotes,
            exportSummary: exportSummary
        )
    }
}
