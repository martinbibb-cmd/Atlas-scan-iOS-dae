import XCTest
@testable import AtlasScan

final class ModelTests: XCTestCase {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Visit

    func testVisitEncodeDecode() throws {
        let visitId = UUID()
        let boiler = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            status: .complete,
            spaceLabel: "Utility",
            notes: "Main boiler"
        )
        let photoEvidence = EvidenceRecord(
            visitId: visitId,
            captureItemId: boiler.id,
            evidenceType: .photo,
            localUri: "VisitMedia/\(visitId.uuidString)/photo.jpg",
            provenanceLevel: .surveyor
        )
        let visit = Visit(
            id: visitId,
            title: "Survey — 12 Elm Close",
            status: .active,
            customerName: "Jane Doe",
            addressSummary: "12 Elm Close, Sheffield, S1 1AA",
            captureItems: [boiler],
            evidenceRecords: [photoEvidence]
        )
        let data = try encoder.encode(visit)
        let decoded = try decoder.decode(Visit.self, from: data)

        XCTAssertEqual(decoded.id, visit.id)
        XCTAssertEqual(decoded.title, visit.title)
        XCTAssertEqual(decoded.status, visit.status)
        XCTAssertEqual(decoded.customerName, visit.customerName)
        XCTAssertEqual(decoded.addressSummary, visit.addressSummary)
        XCTAssertEqual(decoded.captureItems.count, 1)
        XCTAssertEqual(decoded.captureItems[0].tag, .boiler)
        XCTAssertEqual(decoded.captureItems[0].status, .complete)
        XCTAssertEqual(decoded.captureItems[0].spaceLabel, "Utility")
        XCTAssertEqual(decoded.captureItems[0].notes, "Main boiler")
        XCTAssertEqual(decoded.evidenceRecords.count, 1)
        XCTAssertEqual(decoded.evidenceRecords[0].evidenceType, .photo)
        XCTAssertEqual(decoded.evidenceRecords[0].localUri, photoEvidence.localUri)
    }

    func testVisitOptionalFieldsNil() throws {
        let visit = Visit(title: "Draft Survey")
        let data = try encoder.encode(visit)
        let decoded = try decoder.decode(Visit.self, from: data)

        XCTAssertNil(decoded.customerName)
        XCTAssertNil(decoded.addressSummary)
        XCTAssertTrue(decoded.captureItems.isEmpty)
        XCTAssertTrue(decoded.evidenceRecords.isEmpty)
    }

    func testVisitValidation_validTitle() {
        XCTAssertTrue(Visit(title: "Survey 1").isValid)
    }

    func testVisitValidation_blankTitle() {
        XCTAssertFalse(Visit(title: "   ").isValid)
    }

    func testTwinAreaSummaryGroupsCaptureItemsEvidenceAndNeedsReview() {
        let visitId = UUID()
        let baseDate = Date(timeIntervalSince1970: 1_000)
        let boiler = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            status: .complete,
            createdAt: baseDate,
            updatedAt: baseDate,
            spaceLabel: "Utility"
        )
        let radiator = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .radiator,
            status: .needsReview,
            createdAt: baseDate.addingTimeInterval(10),
            updatedAt: baseDate.addingTimeInterval(10),
            spaceLabel: "Lounge"
        )
        let sink = CaptureItem(
            visitId: visitId,
            twinArea: .house,
            tag: .sink,
            status: .unknown,
            createdAt: baseDate.addingTimeInterval(20),
            updatedAt: baseDate.addingTimeInterval(20),
            spaceLabel: "Kitchen"
        )

        let boilerPhoto = EvidenceRecord(
            visitId: visitId,
            captureItemId: boiler.id,
            evidenceType: .photo,
            createdAt: baseDate.addingTimeInterval(30),
            localUri: "VisitMedia/\(visitId.uuidString)/boiler.jpg",
            provenanceLevel: .surveyor
        )
        let radiatorVoice = EvidenceRecord(
            visitId: visitId,
            captureItemId: radiator.id,
            evidenceType: .voice,
            createdAt: baseDate.addingTimeInterval(40),
            localUri: "VisitMedia/\(visitId.uuidString)/radiator.m4a",
            voiceDurationSeconds: 8.2,
            provenanceLevel: .surveyor
        )
        let sinkPhoto = EvidenceRecord(
            visitId: visitId,
            captureItemId: sink.id,
            evidenceType: .photo,
            createdAt: baseDate.addingTimeInterval(50),
            localUri: "VisitMedia/\(visitId.uuidString)/sink.jpg",
            provenanceLevel: .surveyor
        )
        let visitNote = EvidenceRecord(
            visitId: visitId,
            evidenceType: .manualNote,
            createdAt: baseDate.addingTimeInterval(60),
            transcript: "Customer wants a warmer bathroom.",
            provenanceLevel: .customerStated
        )

        let visit = Visit(
            id: visitId,
            title: "Grouped Survey",
            captureItems: [boiler, radiator, sink],
            evidenceRecords: [boilerPhoto, radiatorVoice, sinkPhoto, visitNote]
        )

        let summary = visit.twinAreaSummary(for: .system)

        XCTAssertEqual(summary.captureItems.map(\.id), [boiler.id, radiator.id])
        XCTAssertEqual(summary.evidenceRecords.map(\.id), [radiatorVoice.id, boilerPhoto.id])
        XCTAssertEqual(summary.captureItemCount, 2)
        XCTAssertEqual(summary.evidenceRecordCount, 2)
        XCTAssertEqual(summary.needsReviewCount, 1)
        XCTAssertEqual(summary.captureItemGroups.map(\.captureItem.id), [boiler.id, radiator.id])
        XCTAssertEqual(summary.captureItemGroups[0].evidenceRecords.map(\.id), [boilerPhoto.id])
        XCTAssertEqual(summary.captureItemGroups[1].evidenceRecords.map(\.id), [radiatorVoice.id])
    }

    func testVisitLevelEvidenceRecordsIncludeOnlyVisitNotes() {
        let visitId = UUID()
        let baseDate = Date(timeIntervalSince1970: 2_000)
        let boiler = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            createdAt: baseDate,
            updatedAt: baseDate
        )
        let linkedEvidence = EvidenceRecord(
            visitId: visitId,
            captureItemId: boiler.id,
            evidenceType: .photo,
            createdAt: baseDate.addingTimeInterval(10),
            localUri: "VisitMedia/\(visitId.uuidString)/linked.jpg",
            provenanceLevel: .surveyor
        )
        let firstVisitNote = EvidenceRecord(
            visitId: visitId,
            evidenceType: .voice,
            createdAt: baseDate.addingTimeInterval(20),
            localUri: "VisitMedia/\(visitId.uuidString)/visit-note-1.m4a",
            voiceDurationSeconds: 4.5,
            provenanceLevel: .surveyor
        )
        let secondVisitNote = EvidenceRecord(
            visitId: visitId,
            evidenceType: .manualNote,
            createdAt: baseDate.addingTimeInterval(30),
            transcript: "Customer wants lower running costs.",
            provenanceLevel: .customerStated
        )

        let visit = Visit(
            id: visitId,
            title: "Visit Notes Survey",
            captureItems: [boiler],
            evidenceRecords: [linkedEvidence, firstVisitNote, secondVisitNote]
        )

        XCTAssertEqual(visit.visitLevelEvidenceRecords.map(\.id), [secondVisitNote.id, firstVisitNote.id])
    }

    func testVisitStatusAllCasesEncodeDecode() throws {
        for status in VisitStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(VisitStatus.self, from: data)
            XCTAssertEqual(decoded, status, "Round-trip failed for VisitStatus.\(status)")
        }
    }

    // MARK: - CaptureItem

    func testCaptureItemEncodeDecode() throws {
        let visitId = UUID()
        let item = CaptureItem(
            visitId: visitId,
            twinArea: .system,
            tag: .boiler,
            status: .complete,
            spaceLabel: "Utility Room",
            notes: "Worcester Bosch 30i"
        )
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(CaptureItem.self, from: data)

        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.visitId, visitId)
        XCTAssertEqual(decoded.twinArea, .system)
        XCTAssertEqual(decoded.tag, .boiler)
        XCTAssertEqual(decoded.status, .complete)
        XCTAssertEqual(decoded.spaceLabel, "Utility Room")
        XCTAssertEqual(decoded.notes, "Worcester Bosch 30i")
    }

    func testCaptureItemOptionalFieldsNil() throws {
        let item = CaptureItem(visitId: UUID(), twinArea: .house, tag: .shower)
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(CaptureItem.self, from: data)

        XCTAssertNil(decoded.spaceLabel)
        XCTAssertNil(decoded.notes)
    }

    func testCaptureStatusAllCasesEncodeDecode() throws {
        for status in CaptureStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(CaptureStatus.self, from: data)
            XCTAssertEqual(decoded, status, "Round-trip failed for CaptureStatus.\(status)")
        }
    }

    // MARK: - EvidenceRecord

    func testEvidenceRecordEncodeDecode() throws {
        let visitId = UUID()
        let captureItemId = UUID()
        let record = EvidenceRecord(
            visitId: visitId,
            captureItemId: captureItemId,
            evidenceType: .photo,
            localUri: "file:///surveys/img001.jpg",
            provenanceLevel: .surveyor
        )
        let data = try encoder.encode(record)
        let decoded = try decoder.decode(EvidenceRecord.self, from: data)

        XCTAssertEqual(decoded.id, record.id)
        XCTAssertEqual(decoded.visitId, visitId)
        XCTAssertEqual(decoded.captureItemId, captureItemId)
        XCTAssertEqual(decoded.evidenceType, .photo)
        XCTAssertEqual(decoded.localUri, "file:///surveys/img001.jpg")
        XCTAssertEqual(decoded.provenanceLevel, .surveyor)
    }

    func testVoiceEvidenceRecordEncodeDecodeWithDuration() throws {
        let visitId = UUID()
        let record = EvidenceRecord(
            visitId: visitId,
            evidenceType: .voice,
            localUri: "file:///surveys/note001.m4a",
            voiceDurationSeconds: 12.3,
            provenanceLevel: .surveyor
        )
        let data = try encoder.encode(record)
        let decoded = try decoder.decode(EvidenceRecord.self, from: data)

        XCTAssertEqual(decoded.evidenceType, .voice)
        XCTAssertEqual(decoded.localUri, "file:///surveys/note001.m4a")
        XCTAssertEqual(decoded.voiceDurationSeconds, 12.3)
    }

    func testEvidenceRecordOptionalCaptureItemId() throws {
        let record = EvidenceRecord(
            visitId: UUID(),
            evidenceType: .manualNote,
            transcript: "Boiler is approximately 8 years old."
        )
        let data = try encoder.encode(record)
        let decoded = try decoder.decode(EvidenceRecord.self, from: data)
        XCTAssertNil(decoded.captureItemId)
    }

    func testEvidenceRecordValidation_photoWithUri() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .photo,
                                    localUri: "file:///img.jpg")
        XCTAssertTrue(record.isValid)
    }

    func testEvidenceRecordValidation_photoWithoutUri() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .photo)
        XCTAssertFalse(record.isValid)
    }

    func testEvidenceRecordValidation_videoWithUri() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .video,
                                    localUri: "file:///clip.mov")
        XCTAssertTrue(record.isValid)
    }

    func testEvidenceRecordValidation_voiceWithUri() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .voice,
                                    localUri: "file:///note.m4a")
        XCTAssertTrue(record.isValid)
    }

    func testEvidenceRecordValidation_manualNoteWithTranscript() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .manualNote,
                                    transcript: "Customer mentioned a leak last winter.")
        XCTAssertTrue(record.isValid)
    }

    func testEvidenceRecordValidation_manualNoteBlankTranscript() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .manualNote,
                                    transcript: "   ")
        XCTAssertFalse(record.isValid)
    }

    func testEvidenceRecordValidation_manualNoteNilTranscript() {
        let record = EvidenceRecord(visitId: UUID(), evidenceType: .manualNote)
        XCTAssertFalse(record.isValid)
    }

    func testEvidenceTypeAllCasesEncodeDecode() throws {
        for type_ in EvidenceType.allCases {
            let data = try encoder.encode(type_)
            let decoded = try decoder.decode(EvidenceType.self, from: data)
            XCTAssertEqual(decoded, type_, "Round-trip failed for EvidenceType.\(type_)")
        }
    }

    func testProvenanceLevelAllCasesEncodeDecode() throws {
        for level in ProvenanceLevel.allCases {
            let data = try encoder.encode(level)
            let decoded = try decoder.decode(ProvenanceLevel.self, from: data)
            XCTAssertEqual(decoded, level, "Round-trip failed for ProvenanceLevel.\(level)")
        }
    }

    // MARK: - ObjectTag encode/decode

    func testObjectTagAllCasesEncodeDecode() throws {
        for tag in ObjectTag.allCases {
            let data = try encoder.encode(tag)
            let decoded = try decoder.decode(ObjectTag.self, from: data)
            XCTAssertEqual(decoded, tag, "Round-trip encode/decode failed for ObjectTag.\(tag)")
        }
    }

    // MARK: - ObjectTag → TwinArea mapping

    func testEveryObjectTagMapsToADefinedTwinArea() {
        for tag in ObjectTag.allCases {
            let area = tag.defaultTwinArea
            XCTAssertTrue(
                TwinArea.allCases.contains(area),
                "ObjectTag.\(tag) maps to an unrecognised TwinArea"
            )
        }
    }

    func testSystemTagsMapToSystemTwinArea() {
        let systemTags: [ObjectTag] = [
            .boiler, .cylinder, .thermalStore, .radiator, .ufhManifold,
            .pump, .filter, .tank, .programmer, .thermostat, .trv,
            .consumerUnit, .gasMeter, .electricMeter, .stopcock, .flue, .condensate,
        ]
        for tag in systemTags {
            XCTAssertEqual(tag.defaultTwinArea, .system,
                           "Expected ObjectTag.\(tag) → .system")
        }
    }

    func testHouseTagsMapToHouseTwinArea() {
        let houseTags: [ObjectTag] = [.shower, .bath, .sink]
        for tag in houseTags {
            XCTAssertEqual(tag.defaultTwinArea, .house,
                           "Expected ObjectTag.\(tag) → .house")
        }
    }

    func testHomeTagsMapToHomeTwinArea() {
        let homeTags: [ObjectTag] = [.risk, .customerGoal]
        for tag in homeTags {
            XCTAssertEqual(tag.defaultTwinArea, .home,
                           "Expected ObjectTag.\(tag) → .home")
        }
    }

    func testObjectTagCountMatchesAllCases() {
        // Sanity check: if a new tag is added it must be covered by the switch in defaultTwinArea.
        // All 22 V0.1 tags must be present.
        XCTAssertEqual(ObjectTag.allCases.count, 22)
    }

    // MARK: - TwinDrafts

    func testSystemTwinDraftEncodeDecode() throws {
        let visitId = UUID()
        let ids = [UUID(), UUID(), UUID()]
        let draft = SystemTwinDraft(visitId: visitId, captureItemIds: ids)

        let data = try encoder.encode(draft)
        let decoded = try decoder.decode(SystemTwinDraft.self, from: data)

        XCTAssertEqual(decoded.id, draft.id)
        XCTAssertEqual(decoded.visitId, visitId)
        XCTAssertEqual(decoded.captureItemIds, ids)
    }

    func testHouseTwinDraftEncodeDecode() throws {
        let visitId = UUID()
        let ids = [UUID(), UUID()]
        let draft = HouseTwinDraft(visitId: visitId, captureItemIds: ids)

        let data = try encoder.encode(draft)
        let decoded = try decoder.decode(HouseTwinDraft.self, from: data)

        XCTAssertEqual(decoded.id, draft.id)
        XCTAssertEqual(decoded.visitId, visitId)
        XCTAssertEqual(decoded.captureItemIds, ids)
    }

    func testHomeTwinDraftEncodeDecode() throws {
        let visitId = UUID()
        let ids = [UUID()]
        let draft = HomeTwinDraft(visitId: visitId, captureItemIds: ids)

        let data = try encoder.encode(draft)
        let decoded = try decoder.decode(HomeTwinDraft.self, from: data)

        XCTAssertEqual(decoded.id, draft.id)
        XCTAssertEqual(decoded.visitId, visitId)
        XCTAssertEqual(decoded.captureItemIds, ids)
    }

    func testTwinDraftEmptyCaptureItemIds() throws {
        let visitId = UUID()
        let draft = SystemTwinDraft(visitId: visitId)

        let data = try encoder.encode(draft)
        let decoded = try decoder.decode(SystemTwinDraft.self, from: data)

        XCTAssertTrue(decoded.captureItemIds.isEmpty)
    }

    // MARK: - VisitProgressSummary

    func testTwinAreaSummaryUnknownAndAssumedCounts() {
        let visitId = UUID()
        let baseDate = Date(timeIntervalSince1970: 3_000)

        let items: [CaptureItem] = [
            CaptureItem(visitId: visitId, twinArea: .system, tag: .boiler,
                        status: .complete,    createdAt: baseDate, updatedAt: baseDate),
            CaptureItem(visitId: visitId, twinArea: .system, tag: .radiator,
                        status: .needsReview, createdAt: baseDate, updatedAt: baseDate),
            CaptureItem(visitId: visitId, twinArea: .system, tag: .thermostat,
                        status: .unknown,     createdAt: baseDate, updatedAt: baseDate),
            CaptureItem(visitId: visitId, twinArea: .system, tag: .pump,
                        status: .assumed,     createdAt: baseDate, updatedAt: baseDate),
            CaptureItem(visitId: visitId, twinArea: .system, tag: .filter,
                        status: .assumed,     createdAt: baseDate, updatedAt: baseDate),
        ]
        let visit = Visit(id: visitId, title: "Progress Test", captureItems: items)
        let summary = visit.twinAreaSummary(for: .system)

        XCTAssertEqual(summary.captureItemCount, 5)
        XCTAssertEqual(summary.needsReviewCount, 1)
        XCTAssertEqual(summary.unknownCount, 1)
        XCTAssertEqual(summary.assumedCount, 2)
        XCTAssertEqual(summary.unresolvedCount, 4)
    }

    func testTwinAreaSummaryUnresolvedCountIsZeroWhenAllComplete() {
        let visitId = UUID()
        let items: [CaptureItem] = [
            CaptureItem(visitId: visitId, twinArea: .system, tag: .boiler, status: .complete),
            CaptureItem(visitId: visitId, twinArea: .system, tag: .radiator, status: .notRequired),
        ]
        let visit = Visit(id: visitId, title: "Clean Survey", captureItems: items)
        let summary = visit.twinAreaSummary(for: .system)

        XCTAssertEqual(summary.needsReviewCount, 0)
        XCTAssertEqual(summary.unknownCount, 0)
        XCTAssertEqual(summary.assumedCount, 0)
        XCTAssertEqual(summary.unresolvedCount, 0)
    }

    func testVisitProgressSummaryAggregates() {
        let visitId = UUID()
        let baseDate = Date(timeIntervalSince1970: 4_000)

        let systemItems: [CaptureItem] = [
            CaptureItem(visitId: visitId, twinArea: .system, tag: .boiler,
                        status: .needsReview, createdAt: baseDate, updatedAt: baseDate),
            CaptureItem(visitId: visitId, twinArea: .system, tag: .radiator,
                        status: .complete,    createdAt: baseDate, updatedAt: baseDate),
        ]
        let houseItems: [CaptureItem] = [
            CaptureItem(visitId: visitId, twinArea: .house, tag: .shower,
                        status: .unknown,     createdAt: baseDate, updatedAt: baseDate),
        ]
        let homeItems: [CaptureItem] = [
            CaptureItem(visitId: visitId, twinArea: .home, tag: .risk,
                        status: .assumed,     createdAt: baseDate, updatedAt: baseDate),
        ]
        let visitNote = EvidenceRecord(
            visitId: visitId,
            evidenceType: .manualNote,
            createdAt: baseDate,
            transcript: "Boiler needs service.",
            provenanceLevel: .surveyor
        )
        let linkedEvidence = EvidenceRecord(
            visitId: visitId,
            captureItemId: systemItems[0].id,
            evidenceType: .photo,
            createdAt: baseDate,
            localUri: "VisitMedia/\(visitId.uuidString)/boiler.jpg",
            provenanceLevel: .surveyor
        )

        let visit = Visit(
            id: visitId,
            title: "Full Progress Survey",
            captureItems: systemItems + houseItems + homeItems,
            evidenceRecords: [visitNote, linkedEvidence]
        )

        let progress = visit.progressSummary

        XCTAssertEqual(progress.system.captureItemCount, 2)
        XCTAssertEqual(progress.house.captureItemCount, 1)
        XCTAssertEqual(progress.home.captureItemCount, 1)
        XCTAssertEqual(progress.totalCapturedCount, 4)

        XCTAssertEqual(progress.totalNeedsReviewCount, 1)
        XCTAssertEqual(progress.totalUnknownCount, 1)
        XCTAssertEqual(progress.totalAssumedCount, 1)
        XCTAssertEqual(progress.totalUnresolvedCount, 3)

        XCTAssertEqual(progress.visitNoteCount, 1)

        XCTAssertEqual(progress.areaSummary(for: .system).captureItemCount, 2)
        XCTAssertEqual(progress.areaSummary(for: .house).captureItemCount, 1)
        XCTAssertEqual(progress.areaSummary(for: .home).captureItemCount, 1)
    }

    func testVisitProgressSummaryEmptyVisit() {
        let visit = Visit(id: UUID(), title: "Empty Survey")
        let progress = visit.progressSummary

        XCTAssertEqual(progress.totalCapturedCount, 0)
        XCTAssertEqual(progress.totalUnresolvedCount, 0)
        XCTAssertEqual(progress.visitNoteCount, 0)
    }

    func testVisitProgressSummaryVisitNoteCountExcludesLinkedEvidence() {
        let visitId = UUID()
        let boiler = CaptureItem(visitId: visitId, twinArea: .system, tag: .boiler)
        let linked = EvidenceRecord(
            visitId: visitId, captureItemId: boiler.id, evidenceType: .photo,
            localUri: "VisitMedia/\(visitId.uuidString)/boiler.jpg", provenanceLevel: .surveyor
        )
        let visitNote = EvidenceRecord(
            visitId: visitId, evidenceType: .manualNote,
            transcript: "Site is safe to access.", provenanceLevel: .surveyor
        )
        let visit = Visit(
            id: visitId, title: "Note Count Survey",
            captureItems: [boiler], evidenceRecords: [linked, visitNote]
        )

        XCTAssertEqual(visit.progressSummary.visitNoteCount, 1)
    }



    func testTwinAreaAllCasesEncodeDecode() throws {
        for area in TwinArea.allCases {
            let data = try encoder.encode(area)
            let decoded = try decoder.decode(TwinArea.self, from: data)
            XCTAssertEqual(decoded, area, "Round-trip failed for TwinArea.\(area)")
        }
    }
}
