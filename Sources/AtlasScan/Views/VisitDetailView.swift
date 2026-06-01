#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(AVKit)
import AVKit
#endif

/// Shows and edits a single visit's metadata and lets the user change its status.
public struct VisitDetailView: View {

    @ObservedObject public var store: VisitStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SurveyAssistanceLevel.storageKey) private var assistanceLevelRaw = SurveyAssistanceLevel.defaultLevel.rawValue

    @State private var visit: Visit
    @State private var isEditing = false
    @State private var selectedTwinArea: TwinArea = .system
    @State private var showAddCaptureItem = false
    @State private var editingCaptureItem: CaptureItem?
    @State private var showPhotoCapture = false
    @State private var showVoiceCapture = false
    @State private var showProgressDrawer = false
    @State private var playbackErrorMessage: String?
    @State private var exportErrorMessage: String?
    @State private var exportPreviewPackage: AtlasVisitPackage?
    @State private var exportedPackageURL: URL?
    @State private var activeAudioEvidenceId: UUID?
    @State private var selectedVideoEvidence: EvidenceRecord?
#if canImport(AVFoundation)
    @State private var audioPlayer: AVAudioPlayer?
#endif

    public init(visit: Visit, store: VisitStore, initialTwinArea: TwinArea = .system) {
        _visit = State(initialValue: visit)
        _selectedTwinArea = State(initialValue: initialTwinArea)
        self.store = store
    }

    public var body: some View {
        Form {
            detailSection
            statusSection
            twinAreaSection
            selectedAreaCountsSection
            selectedAreaActionsSection
            selectedAreaItemsSection
            visitNotesSection
            surveyNudgesSection
            resolvedSurveyNudgesSection
            actionSection
            deleteSection
        }
        .navigationTitle(visit.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") { toggleEdit() }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showProgressDrawer = true
                } label: {
                    Label("Progress", systemImage: "chart.bar.doc.horizontal")
                }
            }
        }
        .sheet(isPresented: $showAddCaptureItem) {
            CaptureItemEditor(
                visitId: visit.id,
                initialTag: selectedTwinArea.defaultObjectTag,
                initialTwinArea: selectedTwinArea,
                initialStatus: .unknown,
                initialSpaceLabel: nil,
                initialNotes: nil
            ) { newItem in
                addCaptureItem(newItem)
            }
        }
        .sheet(item: $editingCaptureItem) { item in
            CaptureItemEditor(
                visitId: visit.id,
                existingItem: item
            ) { updatedItem in
                updateCaptureItem(updatedItem)
            }
        }
#if canImport(UIKit) && canImport(AVFoundation)
        .sheet(isPresented: $showPhotoCapture) {
            PhotoCaptureView(visit: visit, onCapture: { captureItem, evidenceRecord in
                upsertCaptureItem(captureItem)
                addEvidenceRecord(evidenceRecord)
            }, preferredTwinArea: selectedTwinArea)
        }
        .sheet(isPresented: $showVoiceCapture) {
            VoiceNoteCaptureView(visit: visit) { evidenceRecord in
                addEvidenceRecord(evidenceRecord)
            }
        }
#endif
        .sheet(isPresented: $showProgressDrawer) {
            VisitProgressView(
                store: store,
                visitId: visit.id,
                selectedTwinArea: $selectedTwinArea
            )
        }
        .onChange(of: showProgressDrawer) { _, isShowing in
            if !isShowing { syncFromStore() }
        }
        .onAppear {
            resolveLastExportedPackageURL()
        }
        .onDisappear {
#if canImport(AVFoundation)
            audioPlayer?.stop()
            audioPlayer = nil
            activeAudioEvidenceId = nil
#endif
        }
        .alert("Playback Error", isPresented: playbackErrorPresented, actions: {
            Button("OK", role: .cancel) { playbackErrorMessage = nil }
        }, message: {
            Text(playbackErrorMessage ?? "Unknown playback error.")
        })
        .alert("Export Failed", isPresented: exportErrorPresented, actions: {
            Button("OK", role: .cancel) { exportErrorMessage = nil }
        }, message: {
            Text(exportErrorMessage ?? "Unknown export error.")
        })
        .sheet(item: $selectedVideoEvidence) { evidence in
#if canImport(AVKit)
            VideoEvidencePlaybackView(record: evidence)
#else
            VStack {
                Text("Video playback is not supported on this platform.")
            }
            .padding()
#endif
        }
        .sheet(item: $exportPreviewPackage) { package in
            VisitExportPreviewSheet(
                package: package,
                onConfirm: { confirmVisitPackageExport() },
                onCancel: { exportPreviewPackage = nil }
            )
        }
    }

    private var selectedTwinSummary: TwinAreaSummary {
        visit.twinAreaSummary(for: selectedTwinArea)
    }

    private var surveyNudges: [SurveyNudge] {
        SurveyNudgeEngine.nudges(for: visit)
    }

    private var assistanceLevel: SurveyAssistanceLevel {
        SurveyAssistanceLevel(storageValue: assistanceLevelRaw)
    }

    private var activeSurveyNudges: [SurveyNudge] {
        surveyNudges.filter(\.isActive)
    }

    private var resolvedSurveyNudges: [SurveyNudge] {
        surveyNudges.filter { !$0.isActive }
    }

    // MARK: - Sections

    private var detailSection: some View {
        Section("Details") {
            if isEditing {
                TextField("Title", text: $visit.title)
                TextField("Customer Name", text: optionalBinding(\.customerName))
                TextField("Address", text: optionalBinding(\.addressSummary))
            } else {
                LabeledContent("Title", value: visit.title)
                if let name = visit.customerName {
                    LabeledContent("Customer", value: name)
                }
                if let address = visit.addressSummary {
                    LabeledContent("Address", value: address)
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent("Status") {
                Text(visit.status.rawValue.capitalized)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var twinAreaSection: some View {
        Section("Twin View") {
            Picker("Twin Area", selection: $selectedTwinArea) {
                ForEach(TwinArea.allCases, id: \.self) { area in
                    Text(area.displayName).tag(area)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var selectedAreaCountsSection: some View {
        Section("\(selectedTwinArea.displayName) Counts") {
            LabeledContent("Capture Items", value: "\(selectedTwinSummary.captureItemCount)")
            LabeledContent("Evidence Records", value: "\(selectedTwinSummary.evidenceRecordCount)")
            LabeledContent("Needs Review", value: "\(selectedTwinSummary.needsReviewCount)")
        }
    }

    private var selectedAreaActionsSection: some View {
        Section("\(selectedTwinArea.displayName) Actions") {
            Button("Add Capture Item to \(selectedTwinArea.displayName)") {
                showAddCaptureItem = true
            }
#if canImport(UIKit) && canImport(AVFoundation)
            Button("Capture Photo or Video") {
                showPhotoCapture = true
            }
            Button("Record Voice Note") {
                showVoiceCapture = true
            }
#endif
        }
    }

    private var selectedAreaItemsSection: some View {
        Section("\(selectedTwinArea.displayName) Items") {
            if selectedTwinSummary.captureItemGroups.isEmpty {
                Text("No capture items in \(selectedTwinArea.displayName.lowercased()) yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(selectedTwinSummary.captureItemGroups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            editingCaptureItem = group.captureItem
                        } label: {
                            CaptureItemRow(
                                item: group.captureItem,
                                linkedEvidenceCount: group.evidenceRecords.count
                            )
                        }
                        .buttonStyle(.plain)

                        if group.evidenceRecords.isEmpty {
                            Text("No linked evidence yet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(group.evidenceRecords) { record in
                                EvidenceRow(
                                    record: record,
                                    captureItems: visit.captureItems,
                                    showsCaptureItemName: false,
                                    isPlaying: activeAudioEvidenceId == record.id,
                                    onTogglePlayback: { toggleVoicePlayback(for: record) },
                                    onOpenVideo: { selectedVideoEvidence = record }
                                )
                                .padding(.leading, 12)
                                .swipeActions {
                                    Button("Delete", role: .destructive) {
                                        deleteEvidenceRecord(id: record.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            deleteCaptureItem(id: group.captureItem.id)
                        }
                    }
                }
            }
        }
    }

    private var visitNotesSection: some View {
        Section("Visit Notes") {
            LabeledContent("Evidence Records", value: "\(visit.visitLevelEvidenceRecords.count)")

            if visit.visitLevelEvidenceRecords.isEmpty {
                Text("No visit-level notes yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visit.visitLevelEvidenceRecords) { record in
                    EvidenceRow(
                        record: record,
                        captureItems: visit.captureItems,
                        showsCaptureItemName: false,
                        isPlaying: activeAudioEvidenceId == record.id,
                        onTogglePlayback: { toggleVoicePlayback(for: record) },
                        onOpenVideo: { selectedVideoEvidence = record }
                    )
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            deleteEvidenceRecord(id: record.id)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var surveyNudgesSection: some View {
        Section("Survey Nudges") {
            if activeSurveyNudges.isEmpty {
                Text("No active nudges right now.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeSurveyNudges) { nudge in
                    SurveyNudgeRow(
                        nudge: nudge,
                        assistanceLevel: assistanceLevel,
                        onSetState: { updateSurveyNudgeState(nudge.id, state: $0) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var resolvedSurveyNudgesSection: some View {
        if !resolvedSurveyNudges.isEmpty {
            Section("Resolved Nudges") {
                ForEach(resolvedSurveyNudges) { nudge in
                    SurveyNudgeRow(
                        nudge: nudge,
                        assistanceLevel: assistanceLevel,
                        onClearState: {
                            clearSurveyNudgeState(nudge.id)
                        }
                    )
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            statusToggleButton
            Button("Export Visit Package") {
                previewVisitPackageExport()
            }
            .accessibilityLabel("Export visit package")
            .accessibilityHint("Previews the export package before creating it and marks it as exported once confirmed.")
            if let exportedPackageURL {
                ShareLink(item: exportedPackageURL) {
                    Label("Share Exported Package", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Visit", role: .destructive) {
                store.delete(visit)
                dismiss()
            }
        }
    }

    // MARK: - Status toggle

    @ViewBuilder
    private var statusToggleButton: some View {
        switch visit.status {
        case .draft, .active:
            Button("Mark Completed") {
                store.markCompleted(visit)
                syncFromStore()
            }
        case .completed:
            Button("Reopen Visit") {
                store.markActive(visit)
                syncFromStore()
            }
        case .exported:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private func toggleEdit() {
        if isEditing {
            persistVisit()
        }
        isEditing.toggle()
    }

    private func syncFromStore() {
        if let updated = store.visits.first(where: { $0.id == visit.id }) {
            visit = updated
        }
    }

    private func optionalBinding(_ keyPath: WritableKeyPath<Visit, String?>) -> Binding<String> {
        Binding(
            get: { visit[keyPath: keyPath] ?? "" },
            set: { visit[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private func addCaptureItem(_ newItem: CaptureItem) {
        visit.captureItems.append(newItem)
        persistVisit()
    }

    private func updateCaptureItem(_ updatedItem: CaptureItem) {
        guard let index = visit.captureItems.firstIndex(where: { $0.id == updatedItem.id }) else {
            return
        }
        visit.captureItems[index] = updatedItem
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

    private func deleteEvidenceRecord(id: UUID) {
        visit.evidenceRecords.removeAll { $0.id == id }
        persistVisit()
    }

    private func deleteCaptureItem(id: UUID) {
        visit.captureItems.removeAll { $0.id == id }
        visit.evidenceRecords.removeAll { $0.captureItemId == id }
        persistVisit()
    }

    private func persistVisit() {
        visit.updatedAt = Date()
        store.update(visit)
        syncFromStore()
    }

    private func previewVisitPackageExport() {
        let exporter = AtlasVisitPackageExporter()
        exportPreviewPackage = exporter.buildPackage(for: visit)
    }

    private func confirmVisitPackageExport() {
        do {
            let exporter = AtlasVisitPackageExporter()
            let result = try exporter.export(visit)
            exportPreviewPackage = nil
            exportedPackageURL = result.fileURL
            store.markExported(visit)
            syncFromStore()
        } catch {
            exportErrorMessage = "Unable to export visit package: \(error.localizedDescription)"
        }
    }

    /// Looks for the most recent exported package file for this visit on disk.
    /// Called on view appear so the share link is available after an app restart.
    private func resolveLastExportedPackageURL() {
        guard exportedPackageURL == nil else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportDir = docs.appendingPathComponent(AtlasVisitPackageExporter.exportsDirectoryName)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: exportDir,
            includingPropertiesForKeys: nil
        ) else { return }
        let prefix = "atlas-visit-\(visit.id.uuidString)-"
        exportedPackageURL = files
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
    }

    private func updateSurveyNudgeState(_ id: SurveyNudgeID, state: SurveyNudgeState) {
        visit.setSurveyNudgeState(state, for: id)
        persistVisit()
    }

    private func clearSurveyNudgeState(_ id: SurveyNudgeID) {
        visit.clearSurveyNudgeState(for: id)
        persistVisit()
    }

    private func toggleVoicePlayback(for record: EvidenceRecord) {
#if canImport(AVFoundation)
        guard record.evidenceType == .voice,
              let localUri = record.localUri else { return }

        if activeAudioEvidenceId == record.id {
            audioPlayer?.stop()
            audioPlayer = nil
            activeAudioEvidenceId = nil
            return
        }

        do {
            let url = EvidenceMediaStore.resolveURL(for: localUri)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            activeAudioEvidenceId = record.id
        } catch {
            audioPlayer = nil
            activeAudioEvidenceId = nil
            playbackErrorMessage = "Unable to play voice note: \(error.localizedDescription)"
        }
#endif
    }

    private var playbackErrorPresented: Binding<Bool> {
        Binding(
            get: { playbackErrorMessage != nil },
            set: { if !$0 { playbackErrorMessage = nil } }
        )
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }
}

private struct CaptureItemRow: View {

    let item: CaptureItem
    let linkedEvidenceCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.tag.displayName)
                .font(.headline)
            Text(item.status.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(linkedEvidenceCount) evidence record\(linkedEvidenceCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let space = item.spaceLabel, !space.isEmpty {
                Text(space)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct EvidenceRow: View {

    let record: EvidenceRecord
    let captureItems: [CaptureItem]
    let showsCaptureItemName: Bool
    let isPlaying: Bool
    let onTogglePlayback: () -> Void
    let onOpenVideo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
#if canImport(UIKit)
            if record.evidenceType == .photo, let image = imageForRecord {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                placeholder
            }
#else
            placeholder
#endif

            VStack(alignment: .leading, spacing: 4) {
                Text(evidenceTitle)
                    .font(.headline)
                if showsCaptureItemName, let captureItemName = captureItemDisplayName {
                    Text("Capture Item: \(captureItemName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
                if record.evidenceType == .voice,
                   let duration = record.voiceDurationSeconds {
                    Text("Duration: \(formattedDuration(duration))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if record.evidenceType == .voice {
                Button(isPlaying ? "Stop" : "Play") { onTogglePlayback() }
            }

            if record.evidenceType == .video {
                Button("Play") { onOpenVideo() }
            }
        }
        .padding(.vertical, 2)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: iconName)
                    .foregroundStyle(.secondary)
            }
    }

    private var iconName: String {
        switch record.evidenceType {
        case .photo:
            return "photo"
        case .voice:
            return "waveform"
        case .video:
            return "video"
        case .manualNote:
            return "doc.text"
        }
    }

#if canImport(UIKit)
    private var imageForRecord: UIImage? {
        guard record.evidenceType == .photo,
              let localUri = record.localUri else { return nil }
        let url = EvidenceMediaStore.resolveURL(for: localUri)
        return UIImage(contentsOfFile: url.path)
    }
#endif

    private var evidenceTitle: String {
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

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration.rounded(.down))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private var captureItemDisplayName: String? {
        guard let captureItemId = record.captureItemId,
              let item = captureItems.first(where: { $0.id == captureItemId }) else {
            return nil
        }
        if let space = item.spaceLabel, !space.isEmpty {
            return "\(item.tag.displayName) • \(space)"
        }
        return item.tag.displayName
    }
}

#if canImport(AVKit)
private struct VideoEvidencePlaybackView: View {
    let record: EvidenceRecord

    var body: some View {
        NavigationStack {
            if let localUri = record.localUri {
                let url = EvidenceMediaStore.resolveURL(for: localUri)
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(minHeight: 280)
                    .navigationTitle("Video Evidence")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Video file is unavailable.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}
#endif

private struct CaptureItemEditor: View {

    @Environment(\.dismiss) private var dismiss

    let visitId: UUID
    let existingItem: CaptureItem?
    let onSave: (CaptureItem) -> Void

    @State private var tag: ObjectTag
    @State private var twinArea: TwinArea
    @State private var status: CaptureStatus
    @State private var spaceLabel: String
    @State private var notes: String
    @State private var hasManualTwinAreaOverride: Bool

    init(
        visitId: UUID,
        initialTag: ObjectTag,
        initialTwinArea: TwinArea,
        initialStatus: CaptureStatus,
        initialSpaceLabel: String?,
        initialNotes: String?,
        onSave: @escaping (CaptureItem) -> Void
    ) {
        self.visitId = visitId
        self.existingItem = nil
        self.onSave = onSave
        _tag = State(initialValue: initialTag)
        _twinArea = State(initialValue: initialTwinArea)
        _status = State(initialValue: initialStatus)
        _spaceLabel = State(initialValue: initialSpaceLabel ?? "")
        _notes = State(initialValue: initialNotes ?? "")
        _hasManualTwinAreaOverride = State(initialValue: initialTwinArea != initialTag.defaultTwinArea)
    }

    init(
        visitId: UUID,
        existingItem: CaptureItem,
        onSave: @escaping (CaptureItem) -> Void
    ) {
        self.visitId = visitId
        self.existingItem = existingItem
        self.onSave = onSave
        _tag = State(initialValue: existingItem.tag)
        _twinArea = State(initialValue: existingItem.twinArea)
        _status = State(initialValue: existingItem.status)
        _spaceLabel = State(initialValue: existingItem.spaceLabel ?? "")
        _notes = State(initialValue: existingItem.notes ?? "")
        _hasManualTwinAreaOverride = State(initialValue: existingItem.twinArea != existingItem.tag.defaultTwinArea)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Object") {
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
                            Text(status.displayName).tag(status)
                        }
                    }
                }
                Section("Optional") {
                    TextField("Space Label", text: $spaceLabel)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle(existingItem == nil ? "New Capture Item" : "Edit Capture Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
        .onChange(of: tag) { _, newTag in
            if !hasManualTwinAreaOverride {
                twinArea = newTag.defaultTwinArea
            }
        }
        .onChange(of: twinArea) { _, newTwinArea in
            hasManualTwinAreaOverride = newTwinArea != tag.defaultTwinArea
        }
    }

    private func save() {
        let item: CaptureItem
        if var existingItem {
            existingItem.visitId = visitId
            existingItem.tag = tag
            existingItem.twinArea = twinArea
            existingItem.status = status
            existingItem.spaceLabel = spaceLabel.nilIfBlank
            existingItem.notes = notes.nilIfBlank
            existingItem.updatedAt = Date()
            item = existingItem
        } else {
            item = CaptureItem(
                visitId: visitId,
                twinArea: twinArea,
                tag: tag,
                status: status,
                spaceLabel: spaceLabel.nilIfBlank,
                notes: notes.nilIfBlank
            )
        }
        onSave(item)
        dismiss()
    }
}

private extension CaptureStatus {
    var displayName: String {
        switch self {
        case .complete:
            return "Complete"
        case .needsReview:
            return "Needs Review"
        case .unknown:
            return "Unknown"
        case .notRequired:
            return "Not Required"
        case .assumed:
            return "Assumed"
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
