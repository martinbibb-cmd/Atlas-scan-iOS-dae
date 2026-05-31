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
    private static let checksumChunkSize = 64 * 1024
    private static let fnv1a64OffsetBasis: UInt64 = 14_695_981_039_346_656_037
    private static let fnv1a64Prime: UInt64 = 1_099_511_628_211

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
        return AtlasVisitPackage(
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
            fieldTestNotes: visit.fieldTestNotes,
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
        var manifest: [AtlasVisitMediaManifestEntry] = []

        for record in visit.evidenceRecords {
            guard let localUri = record.localUri else { continue }
            let metadata = mediaMetadata(for: localUri)
            if !metadata.exists {
                missingWarnings.append(
                    "Missing \(record.evidenceType.rawValue) media for evidence \(record.id.uuidString) at \(localUri)."
                )
            }
            manifest.append(AtlasVisitMediaManifestEntry(
                evidenceId: record.id,
                relativePath: localUri,
                evidenceType: record.evidenceType,
                captureItemId: record.captureItemId,
                fileSizeBytes: metadata.fileSizeBytes,
                checksum: metadata.checksum
            ))
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
        let attributes = try? fileManager.attributesOfItem(atPath: resolvedURL.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value
        return (true, fileSize, checksum(for: resolvedURL))
    }

    private func checksum(for fileURL: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            return nil
        }
        defer { try? handle.close() }

        var hash = Self.fnv1a64OffsetBasis
        while true {
            let chunk = handle.readData(ofLength: Self.checksumChunkSize)
            guard !chunk.isEmpty else { break }
            for byte in chunk {
                hash ^= UInt64(byte)
                hash = hash &* Self.fnv1a64Prime
            }
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
