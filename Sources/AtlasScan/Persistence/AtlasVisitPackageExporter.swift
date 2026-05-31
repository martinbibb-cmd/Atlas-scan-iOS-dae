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
        AtlasVisitPackage(
            exportedAt: exportedAt,
            visit: visit,
            captureItems: visit.captureItems,
            evidenceRecords: visit.evidenceRecords,
            surveyNudgeStates: [:],
            progressSummary: visit.progressSummary,
            mediaManifest: mediaManifest(for: visit)
        )
    }

    private func mediaManifest(for visit: Visit) -> [AtlasVisitMediaManifestEntry] {
        visit.evidenceRecords.compactMap { record in
            guard let localUri = record.localUri else { return nil }
            return AtlasVisitMediaManifestEntry(
                evidenceId: record.id,
                relativePath: localUri,
                evidenceType: record.evidenceType,
                captureItemId: record.captureItemId,
                fileSizeBytes: fileSize(for: localUri),
                checksum: nil
            )
        }
    }

    private func exportDirectory() throws -> URL {
        let directory = documentsDirectory()
            .appendingPathComponent(Self.exportsDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func fileSize(for localUri: String) -> Int64? {
        let resolvedURL = EvidenceMediaStore.resolveURL(
            for: localUri,
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )
        guard let attributes = try? fileManager.attributesOfItem(atPath: resolvedURL.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return nil
        }
        return fileSize.int64Value
    }

    private func documentsDirectory() -> URL {
        if let baseDirectory {
            return baseDirectory
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
