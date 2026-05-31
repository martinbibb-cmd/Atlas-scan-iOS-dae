#if canImport(SwiftUI)
import SwiftUI

// MARK: - VisitProgressView

/// A sheet that summarises survey progress across System, House, and Home
/// for the given visit. Unresolved items (needsReview / unknown / assumed)
/// are surfaced prominently so the surveyor can spot gaps before leaving site.
public struct VisitProgressView: View {

    @ObservedObject public var store: VisitStore
    public let visitId: UUID
    @Binding public var selectedTwinArea: TwinArea
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SurveyAssistanceLevel.storageKey) private var assistanceLevelRaw = SurveyAssistanceLevel.defaultLevel.rawValue

    public init(store: VisitStore, visitId: UUID, selectedTwinArea: Binding<TwinArea>) {
        self.store = store
        self.visitId = visitId
        self._selectedTwinArea = selectedTwinArea
    }

    private var visit: Visit? {
        store.visits.first { $0.id == visitId }
    }

    private var assistanceLevel: SurveyAssistanceLevel {
        SurveyAssistanceLevel(storageValue: assistanceLevelRaw)
    }

    public var body: some View {
        NavigationStack {
            if let visit {
                progressList(for: visit)
            } else {
                ContentUnavailableView(
                    "Visit not found",
                    systemImage: "exclamationmark.circle"
                )
            }
        }
    }

    // MARK: - Main list

    private func progressList(for visit: Visit) -> some View {
        let summary = visit.progressSummary
        let moduleSections = SurveyNudgeEngine.moduleSections(for: visit)
        return List {
            Section("Survey Modules") {
                if moduleSections.isEmpty {
                    Text("No survey nudges right now.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(moduleSections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.module.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(section.resolvedCount) resolved • \(section.missingCount) missing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(section.nudges) { nudge in
                                if nudge.isActive {
                                    SurveyNudgeRow(
                                        nudge: nudge,
                                        assistanceLevel: assistanceLevel,
                                        onSetState: { updateSurveyNudgeState(nudge.id, state: $0) }
                                    )
                                } else {
                                    SurveyNudgeRow(
                                        nudge: nudge,
                                        assistanceLevel: assistanceLevel
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            ForEach(TwinArea.allCases, id: \.self) { area in
                areaSectionView(summary.areaSummary(for: area), area: area)
            }

            Section("Visit Notes") {
                LabeledContent("Evidence", value: "\(summary.visitNoteCount)")
            }
        }
        .navigationTitle("Survey Progress")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Area section

    @ViewBuilder
    private func areaSectionView(_ areaSummary: TwinAreaSummary, area: TwinArea) -> some View {
        Section {
            countRow(label: "Captured", count: areaSummary.captureItemCount, highlighted: false)
            countRow(label: "Evidence", count: areaSummary.evidenceRecordCount, highlighted: false)
            if areaSummary.needsReviewCount > 0 {
                countRow(label: "Needs Review", count: areaSummary.needsReviewCount, highlighted: true)
            }
            if areaSummary.unknownCount > 0 {
                countRow(label: "Unknown", count: areaSummary.unknownCount, highlighted: true)
            }
            if areaSummary.assumedCount > 0 {
                countRow(label: "Assumed", count: areaSummary.assumedCount, highlighted: true)
            }

            let unresolved = areaSummary.captureItems.filter {
                $0.status == .needsReview || $0.status == .unknown || $0.status == .assumed
            }
            ForEach(unresolved) { item in
                unresolvedItemRow(item)
            }

            Button {
                selectedTwinArea = area
                dismiss()
            } label: {
                Label("Jump to \(area.displayName)", systemImage: "arrow.right.circle")
                    .font(.subheadline)
            }
        } header: {
            Text(area.displayName)
        }
    }

    // MARK: - Rows

    private func countRow(label: String, count: Int, highlighted: Bool) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(highlighted ? Color.orange : Color.primary)
            Spacer()
            Text("\(count)")
                .foregroundStyle(highlighted ? Color.orange : Color.secondary)
                .fontWeight(highlighted ? .semibold : .regular)
        }
    }

    private func unresolvedItemRow(_ item: CaptureItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.tag.displayName)
                    .font(.subheadline)
                Text(item.status.progressLabel)
                    .font(.caption)
                    .foregroundStyle(item.status.progressColor)
                if let space = item.spaceLabel, !space.isEmpty {
                    Text(space)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Mark Captured") {
                markItemComplete(item.id)
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func markItemComplete(_ itemId: UUID) {
        guard var updated = store.visits.first(where: { $0.id == visitId }) else { return }
        guard let index = updated.captureItems.firstIndex(where: { $0.id == itemId }) else { return }
        updated.captureItems[index].status = .complete
        updated.captureItems[index].updatedAt = Date()
        updated.updatedAt = Date()
        store.update(updated)
    }

    private func updateSurveyNudgeState(_ id: SurveyNudgeID, state: SurveyNudgeState) {
        guard var updated = store.visits.first(where: { $0.id == visitId }) else { return }
        updated.setSurveyNudgeState(state, for: id)
        updated.updatedAt = Date()
        store.update(updated)
    }
}

// MARK: - CaptureStatus helpers (private)

private extension CaptureStatus {
    var progressLabel: String {
        switch self {
        case .complete:     return "Captured"
        case .needsReview:  return "Needs Review"
        case .unknown:      return "Unknown"
        case .notRequired:  return "Not Required"
        case .assumed:      return "Assumed"
        }
    }

    var progressColor: Color {
        switch self {
        case .needsReview:  return .orange
        case .unknown:      return .orange
        case .assumed:      return .yellow
        case .complete, .notRequired:
            return .secondary
        }
    }
}
#endif
