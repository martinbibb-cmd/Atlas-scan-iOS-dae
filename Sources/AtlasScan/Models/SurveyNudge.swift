import Foundation

public enum SurveyNudgeState: String, Codable, CaseIterable, Sendable {
    case suggested
    case ignored
    case fulfilled
    case notRequired
}

public enum SurveyModule: String, Codable, CaseIterable, Sendable {
    case heatSource
    case hotWater
    case distribution
    case emitters
    case controls
    case gas
    case water
    case electrical
    case exhaust
    case risks
    case home

    public var displayName: String {
        switch self {
        case .heatSource:
            return "Heat Source"
        case .hotWater:
            return "Hot Water"
        case .distribution:
            return "Distribution"
        case .emitters:
            return "Emitters"
        case .controls:
            return "Controls"
        case .gas:
            return "Gas"
        case .water:
            return "Water"
        case .electrical:
            return "Electrical"
        case .exhaust:
            return "Exhaust"
        case .risks:
            return "Risks"
        case .home:
            return "Home"
        }
    }
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
    public let module: SurveyModule
    public let twinArea: TwinArea
    public let title: String
    public let detail: String
    public let state: SurveyNudgeState
    public let isPriority: Bool
    public let allowsDismissal: Bool

    public init(
        id: SurveyNudgeID,
        module: SurveyModule,
        twinArea: TwinArea,
        title: String,
        detail: String,
        state: SurveyNudgeState,
        isPriority: Bool = false,
        allowsDismissal: Bool = true
    ) {
        self.id = id
        self.module = module
        self.twinArea = twinArea
        self.title = title
        self.detail = detail
        self.state = state
        self.isPriority = isPriority
        self.allowsDismissal = allowsDismissal
    }

    public var isActive: Bool { state == .suggested }
}

public struct SurveyModuleNudgeSection: Identifiable, Sendable {
    public let module: SurveyModule
    public let nudges: [SurveyNudge]

    public init(module: SurveyModule, nudges: [SurveyNudge]) {
        self.module = module
        self.nudges = nudges
    }

    public var id: SurveyModule { module }
    public var resolvedCount: Int { nudges.filter { !$0.isActive }.count }
    public var missingCount: Int { nudges.filter(\.isActive).count }
}

public enum SurveyNudgeEngine {
    public static func nudges(for visit: Visit) -> [SurveyNudge] {
        var nudges: [SurveyNudge] = []

        if hasCaptured(.boiler, in: visit) {
            nudges.append(makeTagNudge(
                id: .boilerFlue,
                module: .heatSource,
                twinArea: .system,
                title: "Capture the flue",
                detail: "Boiler captured. Add the flue if it has not been captured yet.",
                target: .single(.flue),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .boilerControls,
                module: .controls,
                twinArea: .system,
                title: "Capture the controls",
                detail: "Boiler captured. Add programmer or thermostat controls if they are still missing.",
                target: .any([.programmer, .thermostat]),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .boilerGasMeter,
                module: .gas,
                twinArea: .system,
                title: "Capture the gas meter",
                detail: "Boiler captured. Add the gas meter if it has not been captured yet.",
                target: .single(.gasMeter),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .boilerCondensate,
                module: .heatSource,
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
                module: .hotWater,
                twinArea: .system,
                title: "Add the cylinder stat",
                detail: "Cylinder captured. Add a cylinder stat note when present.",
                noteTag: .cylinder,
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .cylinderControls,
                module: .controls,
                twinArea: .system,
                title: "Capture the controls",
                detail: "Cylinder captured. Add programmer or thermostat controls if they are still missing.",
                target: .any([.programmer, .thermostat]),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .cylinderStopcock,
                module: .hotWater,
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
                module: .heatSource,
                twinArea: .system,
                title: "Note connected heat sources",
                detail: "Thermal store captured. Add a note for connected heat sources if needed.",
                noteTag: .thermalStore,
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .thermalStorePump,
                module: .distribution,
                twinArea: .system,
                title: "Capture the pump",
                detail: "Thermal store captured. Add the pump if it has not been captured yet.",
                target: .single(.pump),
                visit: visit
            ))
            nudges.append(makeTagNudge(
                id: .thermalStoreControls,
                module: .controls,
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
                module: .emitters,
                twinArea: .system,
                title: "Capture the TRV",
                detail: "Radiator captured. Add the TRV if it has not been captured yet.",
                target: .single(.trv),
                visit: visit
            ))
            nudges.append(makeNoteNudge(
                id: .radiatorEmitterCondition,
                module: .emitters,
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
                module: .electrical,
                twinArea: .system,
                title: "Capture the electric meter",
                detail: "Consumer unit captured. Add the electric meter if it has not been captured yet.",
                target: .single(.electricMeter),
                visit: visit
            ))
            nudges.append(makeNoteNudge(
                id: .consumerUnitEarthingNote,
                module: .electrical,
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
                module: .gas,
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
                    module: .risks,
                    twinArea: .home,
                    title: "Resolve priority risk capture",
                    detail: unresolvedRiskCount == 1
                        ? "A captured risk still needs review."
                        : "\(unresolvedRiskCount) captured risks still need review.",
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

    public static func moduleSections(for visit: Visit) -> [SurveyModuleNudgeSection] {
        moduleSections(from: nudges(for: visit))
    }

    public static func moduleSections(from nudges: [SurveyNudge]) -> [SurveyModuleNudgeSection] {
        SurveyModule.allCases.compactMap { module in
            let moduleNudges = nudges.filter { $0.module == module }
            guard !moduleNudges.isEmpty else { return nil }
            return SurveyModuleNudgeSection(module: module, nudges: moduleNudges)
        }
    }

    private enum TagTarget {
        case single(ObjectTag)
        case any([ObjectTag])
    }

    private static func makeTagNudge(
        id: SurveyNudgeID,
        module: SurveyModule,
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
            module: module,
            twinArea: twinArea,
            title: title,
            detail: detail,
            state: state(for: id, visit: visit, fulfilled: fulfilled)
        )
    }

    private static func makeNoteNudge(
        id: SurveyNudgeID,
        module: SurveyModule,
        twinArea: TwinArea,
        title: String,
        detail: String,
        noteTag: ObjectTag,
        visit: Visit
    ) -> SurveyNudge {
        SurveyNudge(
            id: id,
            module: module,
            twinArea: twinArea,
            title: title,
            detail: detail,
            state: state(for: id, visit: visit, fulfilled: hasNote(on: noteTag, in: visit))
        )
    }

    private static func makeVoiceNudge(for visit: Visit) -> SurveyNudge {
        SurveyNudge(
            id: .customerGoalVoiceNote,
            module: .home,
            twinArea: .home,
            title: "Record a visit voice note",
            detail: "Customer goal captured. Add a visit-level voice note if none exists yet.",
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
