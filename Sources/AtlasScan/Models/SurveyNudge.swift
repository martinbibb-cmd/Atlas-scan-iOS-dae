import Foundation

public enum SurveyAssistanceLevel: String, Codable, CaseIterable, Sendable {
    case expert
    case experienced
    case guided
    case training

    public static let storageKey = "surveyAssistanceLevel"
    public static let defaultLevel: SurveyAssistanceLevel = .experienced

    public init(storageValue: String?) {
        self = SurveyAssistanceLevel(rawValue: storageValue ?? "") ?? .experienced
    }

    public var displayName: String {
        switch self {
        case .expert:
            return "Expert"
        case .experienced:
            return "Experienced"
        case .guided:
            return "Guided"
        case .training:
            return "Training"
        }
    }
}

public enum SurveyNudgeState: String, Codable, CaseIterable, Sendable {
    case suggested
    case ignored
    case fulfilled
    case notRequired
}

public enum SurveyNudgeID: String, Codable, CaseIterable, Sendable {
    case boilerFlue
    case boilerControls
    case boilerGasMeter
    case boilerCondensate
    case cylinderStat
    case cylinderControls
    case cylinderStopcock
    case thermalStoreHeatSources
    case thermalStorePump
    case thermalStoreControls
    case radiatorTRV
    case radiatorEmitterCondition
    case consumerUnitElectricMeter
    case consumerUnitEarthingNote
    case gasMeterPipeSizeNote
    case customerGoalVoiceNote
    case riskNeedsReviewPriority
}

public struct PersistedSurveyNudgeState: Identifiable, Codable, Sendable {
    public let nudgeID: SurveyNudgeID
    public var state: SurveyNudgeState

    public init(nudgeID: SurveyNudgeID, state: SurveyNudgeState) {
        self.nudgeID = nudgeID
        self.state = state
    }

    public var id: SurveyNudgeID { nudgeID }
}

public struct SurveyNudge: Identifiable, Sendable {
    public let id: SurveyNudgeID
    public let twinArea: TwinArea
    public let title: String
    public let detail: String
    public let guidance: [SurveyAssistanceLevel: [String]]
    public let state: SurveyNudgeState
    public let isPriority: Bool
    public let allowsDismissal: Bool

    public init(
        id: SurveyNudgeID,
        twinArea: TwinArea,
        title: String,
        detail: String,
        guidance: [SurveyAssistanceLevel: [String]] = [:],
        state: SurveyNudgeState,
        isPriority: Bool = false,
        allowsDismissal: Bool = true
    ) {
        self.id = id
        self.twinArea = twinArea
        self.title = title
        self.detail = detail
        self.guidance = guidance
        self.state = state
        self.isPriority = isPriority
        self.allowsDismissal = allowsDismissal
    }

    public var isActive: Bool { state == .suggested }

    public func guidanceItems(for level: SurveyAssistanceLevel) -> [String] {
        guidance[level] ?? []
    }
}

public enum SurveyNudgeEngine {
    public static func nudges(for visit: Visit) -> [SurveyNudge] {
        var nudges: [SurveyNudge] = []

        if hasCaptured(.boiler, in: visit) {
            nudges.append(makeTagNudge(
                id: .boilerFlue,
                twinArea: .system,
                title: "Capture the flue",
                detail: "Boiler captured. Add the flue if it has not been captured yet.",
                target: .single(.flue),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .boilerControls,
                twinArea: .system,
                title: "Capture the controls",
                detail: "Boiler captured. Add programmer or thermostat controls if they are still missing.",
                target: .any([.programmer, .thermostat]),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .boilerGasMeter,
                twinArea: .system,
                title: "Capture the gas meter",
                detail: "Boiler captured. Add the gas meter if it has not been captured yet.",
                target: .single(.gasMeter),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .boilerCondensate,
                twinArea: .system,
                title: "Capture the condensate",
                detail: "Boiler captured. Add the condensate route if it is still missing.",
                target: .single(.condensate),
                visit: visit
            ))
        }

        if hasCaptured(.cylinder, in: visit) {
            nudges.append(makeNoteNudge(
                id: .cylinderStat,
                twinArea: .system,
                title: "Add the cylinder stat",
                detail: "Cylinder captured. Add a cylinder stat note when present.",
                noteTag: .cylinder,
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .cylinderControls,
                twinArea: .system,
                title: "Capture the controls",
                detail: "Cylinder captured. Add programmer or thermostat controls if they are still missing.",
                target: .any([.programmer, .thermostat]),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .cylinderStopcock,
                twinArea: .system,
                title: "Capture the water supply",
                detail: "Cylinder captured. Add the water stopcock if it is still missing.",
                target: .single(.stopcock),
                visit: visit
            ))
        }

        if hasCaptured(.thermalStore, in: visit) {
            nudges.append(makeNoteNudge(
                id: .thermalStoreHeatSources,
                twinArea: .system,
                title: "Note connected heat sources",
                detail: "Thermal store captured. Add a note for connected heat sources if needed.",
                noteTag: .thermalStore,
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .thermalStorePump,
                twinArea: .system,
                title: "Capture the pump",
                detail: "Thermal store captured. Add the pump if it has not been captured yet.",
                target: .single(.pump),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .thermalStoreControls,
                twinArea: .system,
                title: "Capture the controls",
                detail: "Thermal store captured. Add programmer or thermostat controls if they are still missing.",
                target: .any([.programmer, .thermostat]),
                visit: visit
            ))
        }

        if hasCaptured(.radiator, in: visit) {
            nudges.append(makeTagNudge(
                id: .radiatorTRV,
                twinArea: .system,
                title: "Capture the TRV",
                detail: "Radiator captured. Add the TRV if it has not been captured yet.",
                target: .single(.trv),
                visit: visit
            ))
            nudges.append(makeNoteNudge(
                id: .radiatorEmitterCondition,
                twinArea: .system,
                title: "Note emitter condition",
                detail: "Radiator captured. Add an emitter condition note if needed.",
                noteTag: .radiator,
                visit: visit
            ))
        }

        if hasCaptured(.consumerUnit, in: visit) {
            nudges.append(makeTagNudge(
                id: .consumerUnitElectricMeter,
                twinArea: .system,
                title: "Capture the electric meter",
                detail: "Consumer unit captured. Add the electric meter if it has not been captured yet.",
                target: .single(.electricMeter),
                visit: visit
            ))
            nudges.append(makeNoteNudge(
                id: .consumerUnitEarthingNote,
                twinArea: .system,
                title: "Add an earthing note",
                detail: "Consumer unit captured. Add an earthing note if needed.",
                noteTag: .consumerUnit,
                visit: visit
            ))
        }

        if hasCaptured(.gasMeter, in: visit) {
            nudges.append(makeNoteNudge(
                id: .gasMeterPipeSizeNote,
                twinArea: .system,
                title: "Add a gas pipe size note",
                detail: "Gas meter captured. Add a gas pipe size note if needed.",
                noteTag: .gasMeter,
                visit: visit
            ))
        }

        if hasCaptured(.customerGoal, in: visit) {
            nudges.append(makeVoiceNudge(for: visit))
        }

        let unresolvedRiskCount = visit.captureItems.filter {
            $0.tag == .risk && $0.status == .needsReview
        }.count
        if unresolvedRiskCount > 0 {
            nudges.append(
                SurveyNudge(
                    id: .riskNeedsReviewPriority,
                    twinArea: .home,
                    title: "Resolve priority risk capture",
                    detail: unresolvedRiskCount == 1
                        ? "A captured risk still needs review."
                        : "\(unresolvedRiskCount) captured risks still need review.",
                    guidance: riskGuidance(),
                    state: .suggested,
                    isPriority: true,
                    allowsDismissal: false
                )
            )
        }

        return nudges
    }

    public static func activeNudges(for visit: Visit) -> [SurveyNudge] {
        nudges(for: visit).filter(\.isActive)
    }

    private enum TagTarget {
        case single(ObjectTag)
        case any([ObjectTag])
    }

    private static func makeTagNudge(
        id: SurveyNudgeID,
        twinArea: TwinArea,
        title: String,
        detail: String,
        target: TagTarget,
        visit: Visit
    ) -> SurveyNudge {
        let fulfilled: Bool
        switch target {
        case let .single(tag):
            fulfilled = hasCaptured(tag, in: visit)
        case let .any(tags):
            fulfilled = tags.contains { hasCaptured($0, in: visit) }
        }

        return SurveyNudge(
            id: id,
            twinArea: twinArea,
            title: title,
            detail: detail,
            guidance: guidanceForTagTarget(target),
            state: state(for: id, visit: visit, fulfilled: fulfilled)
        )
    }

    private static func makeNoteNudge(
        id: SurveyNudgeID,
        twinArea: TwinArea,
        title: String,
        detail: String,
        noteTag: ObjectTag,
        visit: Visit
    ) -> SurveyNudge {
        SurveyNudge(
            id: id,
            twinArea: twinArea,
            title: title,
            detail: detail,
            guidance: guidanceForNoteTarget(noteTag),
            state: state(for: id, visit: visit, fulfilled: hasNote(on: noteTag, in: visit))
        )
    }

    private static func makeVoiceNudge(for visit: Visit) -> SurveyNudge {
        SurveyNudge(
            id: .customerGoalVoiceNote,
            twinArea: .home,
            title: "Record a visit voice note",
            detail: "Customer goal captured. Add a visit-level voice note if none exists yet.",
            guidance: voiceGuidance(),
            state: state(
                for: .customerGoalVoiceNote,
                visit: visit,
                fulfilled: visit.visitLevelEvidenceRecords.contains { $0.evidenceType == .voice }
            )
        )
    }

    private static func state(for id: SurveyNudgeID, visit: Visit, fulfilled: Bool) -> SurveyNudgeState {
        if fulfilled {
            return .fulfilled
        }

        if let persisted = visit.surveyNudgeStates.first(where: { $0.nudgeID == id }),
           persisted.state == .ignored || persisted.state == .notRequired {
            return persisted.state
        }

        return .suggested
    }

    private static func hasCaptured(_ tag: ObjectTag, in visit: Visit) -> Bool {
        visit.captureItems.contains { $0.tag == tag && $0.status != .notRequired }
    }

    private static func hasNote(on tag: ObjectTag, in visit: Visit) -> Bool {
        visit.captureItems.contains {
            $0.tag == tag && !($0.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
    }

    private static func guidanceForTagTarget(_ target: TagTarget) -> [SurveyAssistanceLevel: [String]] {
        let targetLabel: String
        switch target {
        case let .single(tag):
            targetLabel = tag.displayName.lowercased()
        case let .any(tags):
            targetLabel = tags.map { $0.displayName.lowercased() }.joined(separator: " or ")
        }

        return [
            .experienced: [
                "Check for \(targetLabel) before moving on."
            ],
            .guided: [
                "Locate the \(targetLabel).",
                "Capture clear evidence.",
                "If not visible, add a note."
            ],
            .training: [
                "Locate the \(targetLabel).",
                "Capture clear evidence from more than one angle.",
                "Record key condition and accessibility in a note.",
                "If not visible, record why and next best evidence."
            ]
        ]
    }

    private static func guidanceForNoteTarget(_ tag: ObjectTag) -> [SurveyAssistanceLevel: [String]] {
        let label = tag.displayName.lowercased()
        return [
            .experienced: [
                "Add the key \(label) note if relevant."
            ],
            .guided: [
                "Confirm the \(label) is present.",
                "Record the important detail in notes.",
                "Use evidence capture if the note needs visual proof."
            ],
            .training: [
                "Confirm whether the \(label) is present and accessible.",
                "Record what was observed and any uncertainty.",
                "Capture supporting evidence when available.",
                "If missing, record next action for follow-up."
            ]
        ]
    }

    private static func voiceGuidance() -> [SurveyAssistanceLevel: [String]] {
        [
            .experienced: [
                "Capture one short summary voice note for the visit."
            ],
            .guided: [
                "Summarise customer goals.",
                "Include major system observations.",
                "Mention any unresolved risks."
            ],
            .training: [
                "State customer goals in plain language.",
                "Summarise key captures already completed.",
                "Call out unresolved items needing follow-up.",
                "Keep it concise and review for clarity."
            ]
        ]
    }

    private static func riskGuidance() -> [SurveyAssistanceLevel: [String]] {
        [
            .experienced: [
                "Review and resolve each risk capture before leaving site."
            ],
            .guided: [
                "Open the risk capture item.",
                "Confirm severity and context.",
                "Update status to resolved when complete."
            ],
            .training: [
                "Open each unresolved risk capture item.",
                "Confirm evidence quality and risk context.",
                "Document the decision and next action clearly.",
                "Escalate unresolved high-risk findings."
            ]
        ]
    }
}

public extension Visit {
    mutating func setSurveyNudgeState(_ state: SurveyNudgeState, for id: SurveyNudgeID) {
        guard state == .ignored || state == .notRequired else {
            clearSurveyNudgeState(for: id)
            return
        }

        if let index = surveyNudgeStates.firstIndex(where: { $0.nudgeID == id }) {
            surveyNudgeStates[index].state = state
        } else {
            surveyNudgeStates.append(PersistedSurveyNudgeState(nudgeID: id, state: state))
        }
    }

    mutating func clearSurveyNudgeState(for id: SurveyNudgeID) {
        surveyNudgeStates.removeAll { $0.nudgeID == id }
    }
}
