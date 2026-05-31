import Foundation

public struct AtlasVisitPackageExportResult: Sendable {
    public let package: AtlasVisitPackage
    public let fileURL: URL

    public init(package: AtlasVisitPackage, fileURL: URL) {
        self.package = package
        self.fileURL = fileURL
    }
}

public struct AtlasVisitPackageExporter {

    public static let exportsDirectoryName = "VisitExports"

    private let fileManager: FileManager
    private let baseDirectory: URL?
    private let encoder: JSONEncoder

    public init(fileManager: FileManager = .default, baseDirectory: URL? = nil) {
        self.fileManager = fileManager
        self.baseDirectory = baseDirectory

        let configuredEncoder = JSONEncoder()
        configuredEncoder.dateEncodingStrategy = .iso8601
        configuredEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder = configuredEncoder
    }

    public func export(_ visit: Visit) throws -> AtlasVisitPackageExportResult {
        let exportedAt = Date()
        let package = buildPackage(for: visit, exportedAt: exportedAt)
        let data = try encoder.encode(package)

        let directory = try exportDirectory()
        let fileName = "atlas-visit-\(visit.id.uuidString)-\(Int(exportedAt.timeIntervalSince1970)).json"
        let fileURL = directory.appendingPathComponent(fileName, isDirectory: false)
        try data.write(to: fileURL, options: .atomic)

        return AtlasVisitPackageExportResult(package: package, fileURL: fileURL)
    }

    public func buildPackage(for visit: Visit, exportedAt: Date = Date()) -> AtlasVisitPackage {
        let mediaInspection = inspectMedia(for: visit)
        AtlasVisitPackage(
            exportedAt: exportedAt,
            visit: visit,
            captureItems: visit.captureItems,
            evidenceRecords: visit.evidenceRecords,
            surveyNudgeStates: Dictionary(
                uniqueKeysWithValues: visit.surveyNudgeStates.map {
                    ($0.nudgeID.rawValue, $0.state)
                }
            ),
            progressSummary: visit.progressSummary,
            mediaManifest: mediaInspection.manifest,
            missingMediaWarnings: mediaInspection.missingWarnings,
            exportSummary: AtlasVisitPackageExportSummary(
                captureItemCount: visit.captureItems.count,
                evidenceCount: visit.evidenceRecords.count,
                mediaCount: mediaInspection.manifest.count,
                missingMediaCount: mediaInspection.missingWarnings.count,
                unresolvedCount: visit.progressSummary.totalUnresolvedCount
            )
        )
    }

    private func inspectMedia(for visit: Visit) -> (manifest: [AtlasVisitMediaManifestEntry], missingWarnings: [String]) {
        var missingWarnings: [String] = []
        let manifest = visit.evidenceRecords.compactMap { record in
            guard let localUri = record.localUri else { return nil }
            let metadata = mediaMetadata(for: localUri)
            if !metadata.exists {
                missingWarnings.append(
                    "Missing \(record.evidenceType.rawValue) media for evidence \(record.id.uuidString) at \(localUri)."
                )
            }
            return AtlasVisitMediaManifestEntry(
                evidenceId: record.id,
                relativePath: localUri,
                evidenceType: record.evidenceType,
                captureItemId: record.captureItemId,
                fileSizeBytes: metadata.fileSizeBytes,
                checksum: metadata.checksum
            )
        }
        return (manifest, missingWarnings)
    }

    private func exportDirectory() throws -> URL {
        let directory = documentsDirectory()
            .appendingPathComponent(Self.exportsDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func mediaMetadata(for localUri: String) -> (exists: Bool, fileSizeBytes: Int64?, checksum: String?) {
        let resolvedURL = EvidenceMediaStore.resolveURL(
            for: localUri,
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )
        guard fileManager.fileExists(atPath: resolvedURL.path) else {
            return (false, nil, nil)
        }
        guard let data = try? Data(contentsOf: resolvedURL, options: [.mappedIfSafe]) else {
            return (true, nil, nil)
        }
        return (true, Int64(data.count), checksum(for: data))
    }

    private func checksum(for data: Data) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "fnv1a64:%016llx", hash)
    }

    private func documentsDirectory() -> URL {
        if let baseDirectory {
            return baseDirectory
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
