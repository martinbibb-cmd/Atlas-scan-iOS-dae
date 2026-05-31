import XCTest
@testable import AtlasScan

final class AtlasVisitPackageExporterTests: XCTestCase {

    private var baseDirectory: URL!
    private let fileManager = FileManager.default
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    override func setUpWithError() throws {
        baseDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: baseDirectory)
    }

    func testBuildPackageIncludesVisitDataAndProgressSummary() throws {
        let visit = try makeVisitWithMedia()
        let exporter = AtlasVisitPackageExporter(fileManager: fileManager, baseDirectory: baseDirectory)

        let package = exporter.buildPackage(for: visit)

        XCTAssertEqual(package.schemaVersion, "1.0")
        XCTAssertEqual(package.sourceApp, "atlas-scan-ios-dae")
        XCTAssertEqual(package.visit.id, visit.id)
        XCTAssertEqual(package.captureItems.map(\.id), visit.captureItems.map(\.id))
        XCTAssertEqual(package.evidenceRecords.map(\.id), visit.evidenceRecords.map(\.id))
        XCTAssertEqual(package.progressSummary.totalCapturedCount, visit.progressSummary.totalCapturedCount)
        XCTAssertEqual(package.progressSummary.totalUnresolvedCount, visit.progressSummary.totalUnresolvedCount)
        XCTAssertEqual(package.mediaManifest.count, 2)

        let photoEntry = try XCTUnwrap(package.mediaManifest.first { $0.evidenceType == .photo })
        XCTAssertEqual(photoEntry.relativePath, visit.evidenceRecords[0].localUri)
        XCTAssertEqual(photoEntry.captureItemId, visit.captureItems[0].id)
        XCTAssertNotNil(photoEntry.fileSizeBytes)
    }

    func testExportWritesJSONThatRoundTrips() throws {
        let visit = try makeVisitWithMedia()
        let exporter = AtlasVisitPackageExporter(fileManager: fileManager, baseDirectory: baseDirectory)

        let result = try exporter.export(visit)
        XCTAssertTrue(fileManager.fileExists(atPath: result.fileURL.path))

        let data = try Data(contentsOf: result.fileURL)
        let decoded = try decoder.decode(AtlasVisitPackage.self, from: data)

        XCTAssertEqual(decoded.packageId, result.package.packageId)
        XCTAssertEqual(decoded.visit.id, visit.id)
        XCTAssertEqual(decoded.captureItems.count, visit.captureItems.count)
        XCTAssertEqual(decoded.evidenceRecords.count, visit.evidenceRecords.count)
        XCTAssertEqual(decoded.mediaManifest.map(\.relativePath), visit.evidenceRecords.compactMap(\.localUri))
        XCTAssertEqual(decoded.progressSummary.totalCapturedCount, visit.progressSummary.totalCapturedCount)
    }

    func testAtlasVisitPackageEncodeDecodeRoundTrip() throws {
        let visit = try makeVisitWithMedia()
        let exporter = AtlasVisitPackageExporter(fileManager: fileManager, baseDirectory: baseDirectory)
        let package = exporter.buildPackage(for: visit)

        let data = try encoder.encode(package)
        let decoded = try decoder.decode(AtlasVisitPackage.self, from: data)

        XCTAssertEqual(decoded.packageId, package.packageId)
        XCTAssertEqual(decoded.schemaVersion, package.schemaVersion)
        XCTAssertEqual(decoded.sourceApp, package.sourceApp)
        XCTAssertEqual(decoded.visit.id, package.visit.id)
        XCTAssertEqual(decoded.captureItems.map(\.id), package.captureItems.map(\.id))
        XCTAssertEqual(decoded.evidenceRecords.map(\.id), package.evidenceRecords.map(\.id))
        XCTAssertEqual(decoded.mediaManifest.map(\.relativePath), package.mediaManifest.map(\.relativePath))
    }

    private func makeVisitWithMedia() throws -> Visit {
        let visitId = UUID()
        let baseDate = Date(timeIntervalSince1970: 2_000)
        let captureItem = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            status: .complete,
            createdAt: baseDate,
            updatedAt: baseDate
        )

        let photoEvidenceId = UUID()
        let photoPath = try EvidenceMediaStore.savePhotoData(
            Data([0xFF, 0xD8, 0xFF]),
            visitId: visitId,
            evidenceId: photoEvidenceId,
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )
        let voiceEvidenceId = UUID()
        let voicePath = try EvidenceMediaStore.saveAudioData(
            Data([0x01, 0x02, 0x03, 0x04]),
            visitId: visitId,
            evidenceId: voiceEvidenceId,
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )

        let photoEvidence = EvidenceRecord(
            id: photoEvidenceId,
            visitId: visitId,
            captureItemId: captureItem.id,
            evidenceType: .photo,
            createdAt: baseDate.addingTimeInterval(10),
            localUri: photoPath,
            provenanceLevel: .surveyor
        )
        let voiceEvidence = EvidenceRecord(
            id: voiceEvidenceId,
            visitId: visitId,
            evidenceType: .voice,
            createdAt: baseDate.addingTimeInterval(20),
            localUri: voicePath,
            voiceDurationSeconds: 5.0,
            provenanceLevel: .surveyor
        )
        let noteEvidence = EvidenceRecord(
            visitId: visitId,
            evidenceType: .manualNote,
            createdAt: baseDate.addingTimeInterval(30),
            transcript: "Customer notes colder upstairs rooms.",
            provenanceLevel: .customerStated
        )

        return Visit(
            id: visitId,
            title: "Export Candidate",
            status: .completed,
            captureItems: [captureItem],
            evidenceRecords: [photoEvidence, voiceEvidence, noteEvidence]
        )
    }
}
