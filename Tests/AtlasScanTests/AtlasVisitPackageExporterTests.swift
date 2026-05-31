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

        XCTAssertEqual(package.schemaVersion, "1.1")
        XCTAssertEqual(package.sourceApp, "atlas-scan-ios-dae")
        XCTAssertEqual(package.visit.id, visit.id)
        XCTAssertEqual(package.captureItems.map(\.id), visit.captureItems.map(\.id))
        XCTAssertEqual(package.evidenceRecords.map(\.id), visit.evidenceRecords.map(\.id))
        XCTAssertEqual(package.surveyNudgeStates[SurveyNudgeID.boilerGasMeter.rawValue], .ignored)
        XCTAssertEqual(package.surveyNudgeStates[SurveyNudgeID.boilerCondensate.rawValue], .notRequired)
        XCTAssertEqual(package.progressSummary.totalCapturedCount, visit.progressSummary.totalCapturedCount)
        XCTAssertEqual(package.progressSummary.totalUnresolvedCount, visit.progressSummary.totalUnresolvedCount)
        XCTAssertTrue(package.missingMediaWarnings.isEmpty)
        XCTAssertEqual(package.fieldTestNotes, visit.fieldTestNotes)
        XCTAssertEqual(package.exportSummary.captureItemCount, visit.captureItems.count)
        XCTAssertEqual(package.exportSummary.evidenceCount, visit.evidenceRecords.count)
        XCTAssertEqual(package.exportSummary.mediaCount, 3)
        XCTAssertEqual(package.exportSummary.missingMediaCount, 0)
        XCTAssertEqual(package.exportSummary.unresolvedCount, visit.progressSummary.totalUnresolvedCount)
        XCTAssertEqual(package.mediaManifest.count, 3)

        let photoEntry = try XCTUnwrap(package.mediaManifest.first { $0.evidenceType == .photo })
        XCTAssertEqual(photoEntry.relativePath, visit.evidenceRecords[0].localUri)
        XCTAssertEqual(photoEntry.captureItemId, visit.captureItems[0].id)
        XCTAssertNotNil(photoEntry.fileSizeBytes)
        XCTAssertNotNil(photoEntry.checksum)

        let videoEntry = try XCTUnwrap(package.mediaManifest.first { $0.evidenceType == .video })
        XCTAssertEqual(videoEntry.relativePath, visit.evidenceRecords[1].localUri)
        XCTAssertEqual(videoEntry.captureItemId, visit.captureItems[0].id)
        XCTAssertNotNil(videoEntry.fileSizeBytes)
        XCTAssertNotNil(videoEntry.checksum)
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
        XCTAssertEqual(decoded.surveyNudgeStates, result.package.surveyNudgeStates)
        XCTAssertEqual(decoded.mediaManifest.map(\.relativePath), visit.evidenceRecords.compactMap(\.localUri))
        XCTAssertEqual(decoded.progressSummary.totalCapturedCount, visit.progressSummary.totalCapturedCount)
        XCTAssertEqual(decoded.exportSummary, result.package.exportSummary)
        XCTAssertEqual(decoded.missingMediaWarnings, result.package.missingMediaWarnings)
        XCTAssertEqual(decoded.fieldTestNotes, result.package.fieldTestNotes)
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
        XCTAssertEqual(decoded.surveyNudgeStates, package.surveyNudgeStates)
        XCTAssertEqual(decoded.mediaManifest.map(\.relativePath), package.mediaManifest.map(\.relativePath))
        XCTAssertEqual(decoded.exportSummary, package.exportSummary)
        XCTAssertEqual(decoded.missingMediaWarnings, package.missingMediaWarnings)
        XCTAssertEqual(decoded.fieldTestNotes, package.fieldTestNotes)
    }

    func testBuildPackageWarnsWhenMediaIsMissing() throws {
        var visit = try makeVisitWithMedia()
        let missingPath = "VisitMedia/\(visit.id.uuidString)/missing-video.mov"
        visit.evidenceRecords[1].localUri = missingPath

        let exporter = AtlasVisitPackageExporter(fileManager: fileManager, baseDirectory: baseDirectory)
        let package = exporter.buildPackage(for: visit)

        XCTAssertEqual(package.exportSummary.mediaCount, 3)
        XCTAssertEqual(package.exportSummary.missingMediaCount, 1)
        XCTAssertEqual(package.missingMediaWarnings.count, 1)
        XCTAssertTrue(package.missingMediaWarnings[0].contains(missingPath))

        let missingEntry = try XCTUnwrap(package.mediaManifest.first { $0.relativePath == missingPath })
        XCTAssertNil(missingEntry.fileSizeBytes)
        XCTAssertNil(missingEntry.checksum)
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
        let videoEvidenceId = UUID()
        let sourceVideoURL = baseDirectory.appendingPathComponent("source-video.mov")
        try Data([0x90, 0x91, 0x92]).write(to: sourceVideoURL, options: .atomic)
        let videoPath = try EvidenceMediaStore.saveVideoFile(
            from: sourceVideoURL,
            visitId: visitId,
            evidenceId: videoEvidenceId,
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
        let videoEvidence = EvidenceRecord(
            id: videoEvidenceId,
            visitId: visitId,
            captureItemId: captureItem.id,
            evidenceType: .video,
            createdAt: baseDate.addingTimeInterval(30),
            localUri: videoPath,
            provenanceLevel: .surveyor
        )
        let noteEvidence = EvidenceRecord(
            visitId: visitId,
            evidenceType: .manualNote,
            createdAt: baseDate.addingTimeInterval(40),
            transcript: "Customer notes colder upstairs rooms.",
            provenanceLevel: .customerStated
        )

        return Visit(
            id: visitId,
            title: "Export Candidate",
            status: .completed,
            captureItems: [captureItem],
            evidenceRecords: [photoEvidence, videoEvidence, voiceEvidence, noteEvidence],
            surveyNudgeStates: [
                PersistedSurveyNudgeState(nudgeID: .boilerGasMeter, state: .ignored),
                PersistedSurveyNudgeState(nudgeID: .boilerCondensate, state: .notRequired)
            ],
            fieldTestModeEnabled: true,
            fieldTestNotes: [
                FieldTestNote(
                    category: .mediaProblem,
                    details: "Voice note clipping on playback.",
                    photoLocalUri: photoPath,
                    voiceLocalUri: voicePath,
                    voiceDurationSeconds: 5.0
                )
            ]
        )
    }
}
