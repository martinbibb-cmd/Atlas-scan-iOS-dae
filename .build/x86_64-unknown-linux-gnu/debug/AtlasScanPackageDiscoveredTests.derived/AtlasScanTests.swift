import XCTest
@testable import AtlasScanTests

fileprivate extension ModelTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ModelTests = [
        ("testCaptureItemEncodeDecode", testCaptureItemEncodeDecode),
        ("testCaptureItemOptionalFieldsNil", testCaptureItemOptionalFieldsNil),
        ("testCaptureStatusAllCasesEncodeDecode", testCaptureStatusAllCasesEncodeDecode),
        ("testEveryObjectTagMapsToADefinedTwinArea", testEveryObjectTagMapsToADefinedTwinArea),
        ("testEvidenceRecordEncodeDecode", testEvidenceRecordEncodeDecode),
        ("testEvidenceRecordOptionalCaptureItemId", testEvidenceRecordOptionalCaptureItemId),
        ("testEvidenceRecordValidation_manualNoteBlankTranscript", testEvidenceRecordValidation_manualNoteBlankTranscript),
        ("testEvidenceRecordValidation_manualNoteNilTranscript", testEvidenceRecordValidation_manualNoteNilTranscript),
        ("testEvidenceRecordValidation_manualNoteWithTranscript", testEvidenceRecordValidation_manualNoteWithTranscript),
        ("testEvidenceRecordValidation_photoWithUri", testEvidenceRecordValidation_photoWithUri),
        ("testEvidenceRecordValidation_photoWithoutUri", testEvidenceRecordValidation_photoWithoutUri),
        ("testEvidenceRecordValidation_videoWithUri", testEvidenceRecordValidation_videoWithUri),
        ("testEvidenceRecordValidation_voiceWithUri", testEvidenceRecordValidation_voiceWithUri),
        ("testEvidenceTypeAllCasesEncodeDecode", testEvidenceTypeAllCasesEncodeDecode),
        ("testHomeTagsMapToHomeTwinArea", testHomeTagsMapToHomeTwinArea),
        ("testHomeTwinDraftEncodeDecode", testHomeTwinDraftEncodeDecode),
        ("testHouseTagsMapToHouseTwinArea", testHouseTagsMapToHouseTwinArea),
        ("testHouseTwinDraftEncodeDecode", testHouseTwinDraftEncodeDecode),
        ("testObjectTagAllCasesEncodeDecode", testObjectTagAllCasesEncodeDecode),
        ("testObjectTagCountMatchesAllCases", testObjectTagCountMatchesAllCases),
        ("testProvenanceLevelAllCasesEncodeDecode", testProvenanceLevelAllCasesEncodeDecode),
        ("testSystemTagsMapToSystemTwinArea", testSystemTagsMapToSystemTwinArea),
        ("testSystemTwinDraftEncodeDecode", testSystemTwinDraftEncodeDecode),
        ("testTwinAreaAllCasesEncodeDecode", testTwinAreaAllCasesEncodeDecode),
        ("testTwinDraftEmptyCaptureItemIds", testTwinDraftEmptyCaptureItemIds),
        ("testVisitEncodeDecode", testVisitEncodeDecode),
        ("testVisitOptionalFieldsNil", testVisitOptionalFieldsNil),
        ("testVisitStatusAllCasesEncodeDecode", testVisitStatusAllCasesEncodeDecode),
        ("testVisitValidation_blankTitle", testVisitValidation_blankTitle),
        ("testVisitValidation_validTitle", testVisitValidation_validTitle)
    ]
}

fileprivate extension VisitStoreTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__VisitStoreTests = [
        ("testAddVisitAppearsInMemory", testAddVisitAppearsInMemory),
        ("testAddVisitPersistsToDisk", testAddVisitPersistsToDisk),
        ("testCaptureItemsPersistWithVisitRoundTrip", testCaptureItemsPersistWithVisitRoundTrip),
        ("testDeleteVisitPersistsToDisk", testDeleteVisitPersistsToDisk),
        ("testDeleteVisitRemovesFromMemory", testDeleteVisitRemovesFromMemory),
        ("testEmptyStoreWhenNoFileExists", testEmptyStoreWhenNoFileExists),
        ("testMarkActiveSetsActiveStatus", testMarkActiveSetsActiveStatus),
        ("testMarkCompletedUpdatesStatus", testMarkCompletedUpdatesStatus),
        ("testMarkCompletedUpdatesUpdatedAt", testMarkCompletedUpdatesUpdatedAt),
        ("testMultipleVisitsPersistInOrder", testMultipleVisitsPersistInOrder),
        ("testNilOptionalFieldsRoundTrip", testNilOptionalFieldsRoundTrip),
        ("testStatusTransitionsPersistToDisk", testStatusTransitionsPersistToDisk),
        ("testUpdateUnknownIdIsNoOp", testUpdateUnknownIdIsNoOp),
        ("testUpdateVisitChangesTitle", testUpdateVisitChangesTitle),
        ("testUpdateVisitPersistsToDisk", testUpdateVisitPersistsToDisk)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __AtlasScanTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ModelTests.__allTests__ModelTests),
        testCase(VisitStoreTests.__allTests__VisitStoreTests)
    ]
}