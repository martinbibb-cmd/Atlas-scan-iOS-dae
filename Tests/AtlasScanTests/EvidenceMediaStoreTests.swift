import XCTest
@testable import AtlasScan

final class EvidenceMediaStoreTests: XCTestCase {

    private var baseDirectory: URL!

    override func setUpWithError() throws {
        baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: baseDirectory)
    }

    func testSavePhotoDataCreatesDirectoryAndWritesFile() throws {
        let visitId = UUID()
        let evidenceId = UUID()
        let data = Data([0x01, 0x02, 0x03])

        let relativePath = try EvidenceMediaStore.savePhotoData(
            data,
            visitId: visitId,
            evidenceId: evidenceId,
            baseDirectory: baseDirectory
        )

        XCTAssertEqual(relativePath, "VisitMedia/\(visitId.uuidString)/\(evidenceId.uuidString).jpg")

        let expectedURL = baseDirectory.appendingPathComponent(relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path))
        XCTAssertEqual(try Data(contentsOf: expectedURL), data)
    }

    func testSavePhotoDataThrowsWhenBaseDirectoryIsAFile() throws {
        let nonDirectoryURL = baseDirectory.appendingPathComponent("not-a-directory")
        try Data("x".utf8).write(to: nonDirectoryURL, options: .atomic)

        XCTAssertThrowsError(
            try EvidenceMediaStore.savePhotoData(
                Data([0xAA]),
                visitId: UUID(),
                evidenceId: UUID(),
                baseDirectory: nonDirectoryURL
            )
        )
    }

    func testSaveAudioDataCreatesDirectoryAndWritesFile() throws {
        let visitId = UUID()
        let evidenceId = UUID()
        let data = Data([0x10, 0x11, 0x12])

        let relativePath = try EvidenceMediaStore.saveAudioData(
            data,
            visitId: visitId,
            evidenceId: evidenceId,
            baseDirectory: baseDirectory
        )

        XCTAssertEqual(relativePath, "VisitMedia/\(visitId.uuidString)/\(evidenceId.uuidString).m4a")

        let expectedURL = baseDirectory.appendingPathComponent(relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path))
        XCTAssertEqual(try Data(contentsOf: expectedURL), data)
    }

    func testSaveAudioDataThrowsWhenBaseDirectoryIsAFile() throws {
        let nonDirectoryURL = baseDirectory.appendingPathComponent("not-a-directory")
        try Data("x".utf8).write(to: nonDirectoryURL, options: .atomic)

        XCTAssertThrowsError(
            try EvidenceMediaStore.saveAudioData(
                Data([0xAA]),
                visitId: UUID(),
                evidenceId: UUID(),
                baseDirectory: nonDirectoryURL
            )
        )
    }

    func testSaveAudioDataReusesExistingVisitDirectory() throws {
        let visitId = UUID()
        let existingVisitDirectory = baseDirectory
            .appendingPathComponent(EvidenceMediaStore.mediaRootDirectoryName, isDirectory: true)
            .appendingPathComponent(visitId.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: existingVisitDirectory, withIntermediateDirectories: true)

        let relativePath = try EvidenceMediaStore.saveAudioData(
            Data([0x20, 0x21]),
            visitId: visitId,
            evidenceId: UUID(),
            baseDirectory: baseDirectory
        )

        let expectedURL = baseDirectory.appendingPathComponent(relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedURL.path))
    }

    func testResolveURLUsesBaseDirectoryForRelativePath() {
        let resolved = EvidenceMediaStore.resolveURL(
            for: "VisitMedia/visit-a/evidence.jpg",
            baseDirectory: baseDirectory
        )

        XCTAssertEqual(
            resolved.path,
            baseDirectory.appendingPathComponent("VisitMedia/visit-a/evidence.jpg").path
        )
    }

    func testResolveURLReturnsAbsoluteFileURLWhenProvided() {
        let absolute = URL(fileURLWithPath: "/tmp/absolute/photo.jpg")

        let resolved = EvidenceMediaStore.resolveURL(
            for: absolute.absoluteString,
            baseDirectory: baseDirectory
        )

        XCTAssertEqual(resolved, absolute)
    }
}
