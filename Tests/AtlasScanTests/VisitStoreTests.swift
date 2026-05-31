import XCTest
@testable import AtlasScan

final class VisitStoreTests: XCTestCase {

    // Each test gets its own isolated JSON file so nothing leaks between runs.
    var fileURL: URL!

    override func setUpWithError() throws {
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Initial state

    func testEmptyStoreWhenNoFileExists() {
        let store = VisitStore(fileURL: fileURL)
        XCTAssertTrue(store.visits.isEmpty)
    }

    // MARK: - Add

    func testAddVisitAppearsInMemory() {
        let store = VisitStore(fileURL: fileURL)
        store.add(Visit(title: "Survey A"))
        XCTAssertEqual(store.visits.count, 1)
        XCTAssertEqual(store.visits[0].title, "Survey A")
    }

    func testAddVisitPersistsToDisk() {
        let visit = Visit(title: "Persist Me", status: .active, customerName: "Alice",
                          addressSummary: "1 Test Lane")
        VisitStore(fileURL: fileURL).add(visit)

        let reloaded = VisitStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.visits.count, 1)
        XCTAssertEqual(reloaded.visits[0].id, visit.id)
        XCTAssertEqual(reloaded.visits[0].title, "Persist Me")
        XCTAssertEqual(reloaded.visits[0].customerName, "Alice")
        XCTAssertEqual(reloaded.visits[0].addressSummary, "1 Test Lane")
        XCTAssertEqual(reloaded.visits[0].status, .active)
    }

    func testCaptureItemsPersistWithVisitRoundTrip() {
        let visitId = UUID()
        let boiler = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            status: .complete,
            spaceLabel: "Kitchen",
            notes: "Combi"
        )
        let sink = CaptureItem(
            visitId: visitId,
            twinArea: .house,
            tag: .sink,
            status: .needsReview
        )

        let visit = Visit(
            id: visitId,
            title: "Tagged Survey",
            status: .active,
            captureItems: [boiler, sink]
        )

        VisitStore(fileURL: fileURL).add(visit)
        let reloaded = VisitStore(fileURL: fileURL)

        XCTAssertEqual(reloaded.visits.count, 1)
        XCTAssertEqual(reloaded.visits[0].captureItems.count, 2)
        XCTAssertEqual(reloaded.visits[0].captureItems.map(\.tag), [.boiler, .sink])
        XCTAssertEqual(reloaded.visits[0].captureItems[0].spaceLabel, "Kitchen")
        XCTAssertEqual(reloaded.visits[0].captureItems[0].notes, "Combi")
        XCTAssertEqual(reloaded.visits[0].captureItems[1].status, .needsReview)
    }

    func testEvidenceRecordsPersistMetadataRoundTrip() {
        let visitId = UUID()
        let captureItem = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            status: .complete
        )
        let evidence = EvidenceRecord(
            visitId: visitId,
            captureItemId: captureItem.id,
            evidenceType: .photo,
            localUri: "VisitMedia/\(visitId.uuidString)/evidence-1.jpg",
            provenanceLevel: .surveyor
        )

        let visit = Visit(
            id: visitId,
            title: "Photo Survey",
            status: .active,
            captureItems: [captureItem],
            evidenceRecords: [evidence]
        )

        VisitStore(fileURL: fileURL).add(visit)
        let reloaded = VisitStore(fileURL: fileURL)

        XCTAssertEqual(reloaded.visits.count, 1)
        XCTAssertEqual(reloaded.visits[0].evidenceRecords.count, 1)
        XCTAssertEqual(reloaded.visits[0].evidenceRecords[0].evidenceType, .photo)
        XCTAssertEqual(reloaded.visits[0].evidenceRecords[0].captureItemId, captureItem.id)
        XCTAssertEqual(reloaded.visits[0].evidenceRecords[0].localUri, evidence.localUri)
    }

    func testMultipleVisitsPersistInOrder() {
        let store = VisitStore(fileURL: fileURL)
        store.add(Visit(title: "First"))
        store.add(Visit(title: "Second"))
        store.add(Visit(title: "Third"))

        let reloaded = VisitStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.visits.map(\.title), ["First", "Second", "Third"])
    }

    // MARK: - Update

    func testUpdateVisitChangesTitle() {
        let store = VisitStore(fileURL: fileURL)
        var visit = Visit(title: "Original")
        store.add(visit)
        visit.title = "Updated"
        store.update(visit)

        XCTAssertEqual(store.visits[0].title, "Updated")
    }

    func testUpdateVisitPersistsToDisk() {
        let store = VisitStore(fileURL: fileURL)
        var visit = Visit(title: "Before")
        store.add(visit)
        visit.title = "After"
        visit.customerName = "Bob"
        store.update(visit)

        let reloaded = VisitStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.visits[0].title, "After")
        XCTAssertEqual(reloaded.visits[0].customerName, "Bob")
    }

    func testUpdateUnknownIdIsNoOp() {
        let store = VisitStore(fileURL: fileURL)
        store.add(Visit(title: "Real"))
        let ghost = Visit(title: "Ghost")
        store.update(ghost) // different id — should do nothing
        XCTAssertEqual(store.visits.count, 1)
        XCTAssertEqual(store.visits[0].title, "Real")
    }

    // MARK: - Delete

    func testDeleteVisitRemovesFromMemory() {
        let store = VisitStore(fileURL: fileURL)
        let v1 = Visit(title: "Keep")
        let v2 = Visit(title: "Remove")
        store.add(v1)
        store.add(v2)
        store.delete(v2)

        XCTAssertEqual(store.visits.count, 1)
        XCTAssertEqual(store.visits[0].title, "Keep")
    }

    func testDeleteVisitPersistsToDisk() {
        let store = VisitStore(fileURL: fileURL)
        let keep = Visit(title: "Keep")
        let drop = Visit(title: "Drop")
        store.add(keep)
        store.add(drop)
        store.delete(drop)

        let reloaded = VisitStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.visits.count, 1)
        XCTAssertEqual(reloaded.visits[0].id, keep.id)
    }

    // MARK: - Status transitions

    func testMarkCompletedUpdatesStatus() {
        let store = VisitStore(fileURL: fileURL)
        let visit = Visit(title: "Active Survey", status: .active)
        store.add(visit)
        store.markCompleted(visit)

        XCTAssertEqual(store.visits[0].status, .completed)
    }

    func testMarkActiveSetsActiveStatus() {
        let store = VisitStore(fileURL: fileURL)
        let visit = Visit(title: "Done Survey", status: .completed)
        store.add(visit)
        store.markActive(visit)

        XCTAssertEqual(store.visits[0].status, .active)
    }

    func testMarkCompletedUpdatesUpdatedAt() throws {
        let before = Date()
        let store = VisitStore(fileURL: fileURL)
        let visit = Visit(title: "Timing Test", status: .active)
        store.add(visit)
        store.markCompleted(visit)
        let after = Date()

        let updatedAt = store.visits[0].updatedAt
        XCTAssertGreaterThanOrEqual(updatedAt, before)
        XCTAssertLessThanOrEqual(updatedAt, after)
    }

    func testStatusTransitionsPersistToDisk() {
        let store = VisitStore(fileURL: fileURL)
        let visit = Visit(title: "Status Round-Trip", status: .active)
        store.add(visit)
        store.markCompleted(visit)

        let reloaded = VisitStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.visits[0].status, .completed)
    }

    // MARK: - Persistence round-trip with optional fields nil

    func testNilOptionalFieldsRoundTrip() {
        let visit = Visit(title: "Minimal")
        VisitStore(fileURL: fileURL).add(visit)

        let reloaded = VisitStore(fileURL: fileURL)
        XCTAssertNil(reloaded.visits[0].customerName)
        XCTAssertNil(reloaded.visits[0].addressSummary)
    }
}
