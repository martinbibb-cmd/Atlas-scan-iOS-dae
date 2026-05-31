import XCTest
@testable import AtlasScanTests

fileprivate extension AtlasVisitPackageExporterTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__AtlasVisitPackageExporterTests = [
        ("testAtlasVisitPackageEncodeDecodeRoundTrip", testAtlasVisitPackageEncodeDecodeRoundTrip),
        ("testBuildPackageIncludesVisitDataAndProgressSummary", testBuildPackageIncludesVisitDataAndProgressSummary),
        ("testExportWritesJSONThatRoundTrips", testExportWritesJSONThatRoundTrips)
    ]
}

fileprivate extension EvidenceMediaStoreTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__EvidenceMediaStoreTests = [
        ("testResolveURLReturnsAbsoluteFileURLWhenProvided", testResolveURLReturnsAbsoluteFileURLWhenProvided),
        ("testResolveURLUsesBaseDirectoryForRelativePath", testResolveURLUsesBaseDirectoryForRelativePath),
        ("testSaveAudioDataCreatesDirectoryAndWritesFile", testSaveAudioDataCreatesDirectoryAndWritesFile),
        ("testSaveAudioDataReusesExistingVisitDirectory", testSaveAudioDataReusesExistingVisitDirectory),
        ("testSaveAudioDataThrowsWhenBaseDirectoryIsAFile", testSaveAudioDataThrowsWhenBaseDirectoryIsAFile),
        ("testSavePhotoDataCreatesDirectoryAndWritesFile", testSavePhotoDataCreatesDirectoryAndWritesFile),
        ("testSavePhotoDataThrowsWhenBaseDirectoryIsAFile", testSavePhotoDataThrowsWhenBaseDirectoryIsAFile),
        ("testSaveVideoFileCopiesMOVIntoVisitDirectory", testSaveVideoFileCopiesMOVIntoVisitDirectory),
        ("testSaveVideoFileNormalizesUnsupportedExtensionsToMOV", testSaveVideoFileNormalizesUnsupportedExtensionsToMOV),
        ("testSaveVideoFilePreservesMP4Extension", testSaveVideoFilePreservesMP4Extension),
        ("testSaveVideoFileThrowsWhenBaseDirectoryIsAFile", testSaveVideoFileThrowsWhenBaseDirectoryIsAFile)
    ]
}

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
        ("testRecentObjectTagsMovesMostRecentToFrontWithoutDuplicates", testRecentObjectTagsMovesMostRecentToFrontWithoutDuplicates),
        ("testRecentObjectTagsRespectsMaximumCount", testRecentObjectTagsRespectsMaximumCount),
        ("testSurveyAssistanceLevelStorageFallbackDefaultsToExperienced", testSurveyAssistanceLevelStorageFallbackDefaultsToExperienced),
        ("testSurveyNudgeEngineAssignsModulesToGeneratedNudges", testSurveyNudgeEngineAssignsModulesToGeneratedNudges),
        ("testSurveyNudgeEngineBuildsOrderedModuleSectionsWithResolvedAndMissingCounts", testSurveyNudgeEngineBuildsOrderedModuleSectionsWithResolvedAndMissingCounts),
        ("testSurveyNudgeEngineFlagsNeedsReviewRiskAsPriority", testSurveyNudgeEngineFlagsNeedsReviewRiskAsPriority),
        ("testSurveyNudgeEngineFulfilsTargetsAndRemovesIgnoredAndNotRequiredFromActiveList", testSurveyNudgeEngineFulfilsTargetsAndRemovesIgnoredAndNotRequiredFromActiveList),
        ("testSurveyNudgeEngineGeneratesBoilerAndGoalPromptsWhenTargetsAreMissing", testSurveyNudgeEngineGeneratesBoilerAndGoalPromptsWhenTargetsAreMissing),
        ("testSurveyNudgeGuidanceAdaptsToAssistanceLevels", testSurveyNudgeGuidanceAdaptsToAssistanceLevels),
        ("testSystemTagsMapToSystemTwinArea", testSystemTagsMapToSystemTwinArea),
        ("testSystemTwinDraftEncodeDecode", testSystemTwinDraftEncodeDecode),
        ("testTwinAreaAllCasesEncodeDecode", testTwinAreaAllCasesEncodeDecode),
        ("testTwinAreaSummaryGroupsCaptureItemsEvidenceAndNeedsReview", testTwinAreaSummaryGroupsCaptureItemsEvidenceAndNeedsReview),
        ("testTwinAreaSummaryUnknownAndAssumedCounts", testTwinAreaSummaryUnknownAndAssumedCounts),
        ("testTwinAreaSummaryUnresolvedCountIsZeroWhenAllComplete", testTwinAreaSummaryUnresolvedCountIsZeroWhenAllComplete),
        ("testTwinDraftEmptyCaptureItemIds", testTwinDraftEmptyCaptureItemIds),
        ("testVisitDecodeWithoutSurveyNudgeStatesDefaultsToEmpty", testVisitDecodeWithoutSurveyNudgeStatesDefaultsToEmpty),
        ("testVisitEncodeDecode", testVisitEncodeDecode),
        ("testVisitLevelEvidenceRecordsIncludeOnlyVisitNotes", testVisitLevelEvidenceRecordsIncludeOnlyVisitNotes),
        ("testVisitOptionalFieldsNil", testVisitOptionalFieldsNil),
        ("testVisitProgressSummaryAggregates", testVisitProgressSummaryAggregates),
        ("testVisitProgressSummaryEmptyVisit", testVisitProgressSummaryEmptyVisit),
        ("testVisitProgressSummaryVisitNoteCountExcludesLinkedEvidence", testVisitProgressSummaryVisitNoteCountExcludesLinkedEvidence),
        ("testVisitStatusAllCasesEncodeDecode", testVisitStatusAllCasesEncodeDecode),
        ("testVisitValidation_blankTitle", testVisitValidation_blankTitle),
        ("testVisitValidation_validTitle", testVisitValidation_validTitle),
        ("testVoiceEvidenceRecordEncodeDecodeWithDuration", testVoiceEvidenceRecordEncodeDecodeWithDuration)
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
        ("testEvidenceRecordsPersistMetadataRoundTrip", testEvidenceRecordsPersistMetadataRoundTrip),
        ("testMarkActiveSetsActiveStatus", testMarkActiveSetsActiveStatus),
        ("testMarkCompletedUpdatesStatus", testMarkCompletedUpdatesStatus),
        ("testMarkCompletedUpdatesUpdatedAt", testMarkCompletedUpdatesUpdatedAt),
        ("testMarkExportedSetsExportedStatusAndPersists", testMarkExportedSetsExportedStatusAndPersists),
        ("testMultipleVisitsPersistInOrder", testMultipleVisitsPersistInOrder),
        ("testNilOptionalFieldsRoundTrip", testNilOptionalFieldsRoundTrip),
        ("testStatusTransitionsPersistToDisk", testStatusTransitionsPersistToDisk),
        ("testSurveyNudgeStatesPersistRoundTrip", testSurveyNudgeStatesPersistRoundTrip),
        ("testUpdateUnknownIdIsNoOp", testUpdateUnknownIdIsNoOp),
        ("testUpdateVisitChangesTitle", testUpdateVisitChangesTitle),
        ("testUpdateVisitPersistsToDisk", testUpdateVisitPersistsToDisk),
        ("testVoiceEvidenceMetadataPersistsRoundTrip", testVoiceEvidenceMetadataPersistsRoundTrip)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __AtlasScanTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AtlasVisitPackageExporterTests.__allTests__AtlasVisitPackageExporterTests),
        testCase(EvidenceMediaStoreTests.__allTests__EvidenceMediaStoreTests),
        testCase(ModelTests.__allTests__ModelTests),
        testCase(VisitStoreTests.__allTests__VisitStoreTests)
    ]
}