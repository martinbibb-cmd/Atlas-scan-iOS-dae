#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

public struct VisitDashboardView: View {

    private let recentActivityLimit = 10

    @ObservedObject public var store: VisitStore

    @State private var visit: Visit
    @State private var showProgress = false
    @State private var showNudges = false
    @State private var showEvidence = false
    @State private var showCaptureOptions = false
    @State private var showPhotoCapture = false
    @State private var showVoiceCapture = false
    @State private var showManualCapture = false
    @State private var exportedPackageURL: URL?
    @State private var exportErrorMessage: String?
    @State private var captureInfoMessage: String?

    public init(visit: Visit, store: VisitStore) {
        _visit = State(initialValue: visit)
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroSection
                surveyHealthBanner
                twinSummarySection
                captureSection
                quickActionsSection
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle(visit.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncFromStore() }
        .sheet(isPresented: $showProgress) {
            VisitProgressView(
                store: store,
                visitId: visit.id,
                selectedTwinArea: .constant(.system)
            )
        }
        .sheet(isPresented: $showNudges) {
            NavigationStack {
                nudgeList
            }
        }
        .sheet(isPresented: $showEvidence) {
            NavigationStack {
                evidenceList
            }
        }
#if canImport(UIKit) && canImport(AVFoundation)
        .sheet(isPresented: $showPhotoCapture) {
            PhotoCaptureView(visit: visit, onCapture: { captureItem, evidenceRecord in
                upsertCaptureItem(captureItem)
                addEvidenceRecord(evidenceRecord)
            }, preferredTwinArea: .system)
        }
        .sheet(isPresented: $showVoiceCapture) {
            VoiceNoteCaptureView(visit: visit) { evidenceRecord in
                addEvidenceRecord(evidenceRecord)
            }
        }
#endif
        .sheet(isPresented: $showManualCapture) {
            ManualCaptureItemSheet(visitId: visit.id) {
                addCaptureItem($0)
            }
        }
        .confirmationDialog("Capture Evidence", isPresented: $showCaptureOptions, titleVisibility: .visible) {
#if canImport(UIKit) && canImport(AVFoundation)
            Button("Photo") { showPhotoCapture = true }
            Button("Voice") { showVoiceCapture = true }
#endif
            Button("Manual Tag") { showManualCapture = true }
            Button("Video") {
                captureInfoMessage = "Video capture is not available in this build."
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Export Failed", isPresented: exportErrorPresented, actions: {
            Button("OK", role: .cancel) { exportErrorMessage = nil }
        }, message: {
            Text(exportErrorMessage ?? "Unknown export error.")
        })
        .alert("Capture", isPresented: captureInfoPresented, actions: {
            Button("OK", role: .cancel) { captureInfoMessage = nil }
        }, message: {
            Text(captureInfoMessage ?? "")
        })
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(visit.title)
                .font(.title2)
                .fontWeight(.semibold)
            if let customerName = visit.customerName, !customerName.isEmpty {
                Text(customerName)
                    .font(.headline)
            }
            if let address = visit.addressSummary, !address.isEmpty {
                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(visit.status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var surveyHealthBanner: some View {
        let unresolvedCount = visit.progressSummary.totalUnresolvedCount
        let activeNudges = SurveyNudgeEngine.nudges(for: visit).filter(\.isActive)
        return VStack(alignment: .leading, spacing: 4) {
            Text(unresolvedCount == 1 ? "1 unresolved item" : "\(unresolvedCount) unresolved items")
                .font(.subheadline)
                .fontWeight(.semibold)
            if let firstNudge = activeNudges.first {
                Text(firstNudge.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(activeNudges.isEmpty ? "No active survey nudges" : "\(activeNudges.count) active survey nudges")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var twinSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Property Areas")
                .font(.headline)
            ForEach(TwinArea.allCases, id: \.self) { area in
                NavigationLink {
                    VisitDetailView(visit: visit, store: store, initialTwinArea: area)
                } label: {
                    TwinSummaryCard(area: area, summary: visit.twinAreaSummary(for: area))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var captureSection: some View {
        Button {
            showCaptureOptions = true
        } label: {
            Text("CAPTURE")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                quickActionButton("Progress", systemImage: "chart.bar.doc.horizontal") {
                    showProgress = true
                }
                quickActionButton("Nudges", systemImage: "lightbulb") {
                    showNudges = true
                }
                quickActionButton("Evidence", systemImage: "photo.on.rectangle") {
                    showEvidence = true
                }
                quickActionButton("Export", systemImage: "square.and.arrow.up") {
                    exportVisitPackage()
                }
            }
            if let exportedPackageURL {
                ShareLink(item: exportedPackageURL) {
                    Label("Share Exported Package", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline)
            if recentActivity.isEmpty {
                Text("No recent activity yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentActivity) { activity in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.title)
                            .font(.subheadline)
                        Text(activity.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var nudgeList: some View {
        let sections = SurveyNudgeEngine.moduleSections(for: visit)
        return List {
            if sections.isEmpty {
                Text("No survey nudges right now.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sections) { section in
                    Section(section.module.displayName) {
                        nudgeModuleSummaryRow(section)
                        ForEach(section.nudges) { nudge in
                            if nudge.isActive {
                                SurveyNudgeRow(
                                    nudge: nudge,
                                    onSetState: { updateSurveyNudgeState(nudge.id, state: $0) }
                                )
                            } else {
                                SurveyNudgeRow(
                                    nudge: nudge,
                                    onClearState: { clearSurveyNudgeState(nudge.id) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Nudges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { showNudges = false }
            }
        }

        private func nudgeModuleSummaryRow(_ section: SurveyModuleNudgeSection) -> some View {
            HStack(spacing: 12) {
                Text("\(section.resolvedCount) resolved")
                Text("\(section.missingCount) missing")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .textCase(nil)
        }
    }

    private var evidenceList: some View {
        List {
            if visit.evidenceRecords.isEmpty {
                Text("No evidence yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedEvidenceRecords) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recordTitle(record))
                            .font(.subheadline)
                        if let transcript = record.transcript, !transcript.isEmpty {
                            Text(transcript)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let localUri = record.localUri {
                            Text(localUri)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { showEvidence = false }
            }
        }
    }

    private var recentActivity: [RecentActivityItem] {
        let evidenceActivity = visit.evidenceRecords.map {
            RecentActivityItem(
                timestamp: $0.createdAt,
                title: recordTitle($0),
                subtitle: $0.captureItemId == nil ? "Visit note" : "Evidence record"
            )
        }
        let captureActivity = visit.captureItems.map {
            RecentActivityItem(
                timestamp: $0.updatedAt,
                title: "\($0.tag.displayName) capture item",
                subtitle: $0.status.rawValue.capitalized
            )
        }
        let sorted = (evidenceActivity + captureActivity).sorted { $0.timestamp > $1.timestamp }
        return Array(sorted.prefix(recentActivityLimit))
    }

    private func quickActionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
    }

    private var sortedEvidenceRecords: [EvidenceRecord] {
        visit.evidenceRecords.sorted { $0.createdAt > $1.createdAt }
    }

    private var statusColor: Color {
        switch visit.status {
        case .draft: return .orange
        case .active: return .green
        case .completed: return .blue
        case .exported: return .gray
        }
    }

    private func syncFromStore() {
        if let updated = store.visits.first(where: { $0.id == visit.id }) {
            visit = updated
        }
    }

    private func addCaptureItem(_ item: CaptureItem) {
        visit.captureItems.append(item)
        persistVisit()
    }

    private func upsertCaptureItem(_ item: CaptureItem) {
        if let index = visit.captureItems.firstIndex(where: { $0.id == item.id }) {
            visit.captureItems[index] = item
        } else {
            visit.captureItems.append(item)
        }
        persistVisit()
    }

    private func addEvidenceRecord(_ record: EvidenceRecord) {
        visit.evidenceRecords.append(record)
        persistVisit()
    }

    private func persistVisit() {
        visit.updatedAt = Date()
        store.update(visit)
        syncFromStore()
    }

    private func updateSurveyNudgeState(_ id: SurveyNudgeID, state: SurveyNudgeState) {
        visit.setSurveyNudgeState(state, for: id)
        persistVisit()
    }

    private func clearSurveyNudgeState(_ id: SurveyNudgeID) {
        visit.clearSurveyNudgeState(for: id)
        persistVisit()
    }

    private func exportVisitPackage() {
        do {
            let exporter = AtlasVisitPackageExporter()
            let result = try exporter.export(visit)
            exportedPackageURL = result.fileURL
            store.markExported(visit)
            syncFromStore()
        } catch {
            exportErrorMessage = "Unable to export visit package: \(error.localizedDescription)"
        }
    }

    private func recordTitle(_ record: EvidenceRecord) -> String {
        switch record.evidenceType {
        case .photo:
            return "Photo"
        case .voice:
            return "Voice Note"
        case .video:
            return "Video"
        case .manualNote:
            return "Manual Note"
        }
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    private var captureInfoPresented: Binding<Bool> {
        Binding(
            get: { captureInfoMessage != nil },
            set: { if !$0 { captureInfoMessage = nil } }
        )
    }
}

private struct TwinSummaryCard: View {
    let area: TwinArea
    let summary: TwinAreaSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(area.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
            Text("\(summary.captureItemCount) items")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(summary.evidenceRecordCount) evidence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(summary.needsReviewCount) review")
                .font(.subheadline)
                .foregroundStyle(summary.needsReviewCount > 0 ? .orange : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct RecentActivityItem: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let subtitle: String
}

private struct ManualCaptureItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    let visitId: UUID
    let onSave: (CaptureItem) -> Void

    @State private var tag: ObjectTag = .boiler
    @State private var twinArea: TwinArea = .system
    @State private var status: CaptureStatus = .unknown
    @State private var spaceLabel = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Manual Tag") {
                    Picker("Tag", selection: $tag) {
                        ForEach(ObjectTag.allCases, id: \.self) { tag in
                            Text(tag.displayName).tag(tag)
                        }
                    }
                    Picker("Twin Area", selection: $twinArea) {
                        ForEach(TwinArea.allCases, id: \.self) { area in
                            Text(area.displayName).tag(area)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(CaptureStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                    TextField("Space Label", text: $spaceLabel)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle("Manual Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            CaptureItem(
                                visitId: visitId,
                                twinArea: twinArea,
                                tag: tag,
                                status: status,
                                spaceLabel: spaceLabel.nilIfBlank,
                                notes: notes.nilIfBlank
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
#endif
