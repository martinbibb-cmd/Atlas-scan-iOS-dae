#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Shows and edits a single visit's metadata and lets the user change its status.
public struct VisitDetailView: View {

    @ObservedObject public var store: VisitStore
    @Environment(\.dismiss) private var dismiss

    @State private var visit: Visit
    @State private var isEditing = false
    @State private var showAddCaptureItem = false
    @State private var editingCaptureItem: CaptureItem?
    @State private var showPhotoCapture = false

    public init(visit: Visit, store: VisitStore) {
        _visit = State(initialValue: visit)
        self.store = store
    }

    public var body: some View {
        Form {
            detailSection
            statusSection
            captureActionsSection
            captureItemSections
            evidenceSection
            actionSection
            deleteSection
        }
        .navigationTitle(visit.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") { toggleEdit() }
            }
        }
        .sheet(isPresented: $showAddCaptureItem) {
            CaptureItemEditor(
                visitId: visit.id,
                initialTag: .boiler,
                initialTwinArea: .system,
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
            PhotoCaptureView(visit: visit) { captureItem, evidenceRecord in
                upsertCaptureItem(captureItem)
                addEvidenceRecord(evidenceRecord)
            }
        }
#endif
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

    private var captureActionsSection: some View {
        Section("Capture Items") {
            Button("Add Capture Item") {
                showAddCaptureItem = true
            }
#if canImport(UIKit) && canImport(AVFoundation)
            Button("Capture Photo") {
                showPhotoCapture = true
            }
#endif
            if visit.captureItems.isEmpty {
                Text("No capture items yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var captureItemSections: some View {
        Group {
            ForEach(TwinArea.allCases, id: \.self) { area in
                let items = visit.captureItems.filter { $0.twinArea == area }
                if !items.isEmpty {
                    Section(area.displayName) {
                        ForEach(items) { item in
                            Button {
                                editingCaptureItem = item
                            } label: {
                                CaptureItemRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    deleteCaptureItem(id: item.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            statusToggleButton
        }
    }

    private var evidenceSection: some View {
        Section("Evidence") {
            if photoEvidenceRecords.isEmpty {
                Text("No photos captured yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(photoEvidenceRecords) { record in
                    EvidenceRow(record: record, captureItems: visit.captureItems)
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

    private func deleteCaptureItem(id: UUID) {
        visit.captureItems.removeAll { $0.id == id }
        persistVisit()
    }

    private func persistVisit() {
        visit.updatedAt = Date()
        store.update(visit)
        syncFromStore()
    }

    private var photoEvidenceRecords: [EvidenceRecord] {
        visit.evidenceRecords
            .filter { $0.evidenceType == .photo }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

private struct CaptureItemRow: View {

    let item: CaptureItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.tag.displayName)
                .font(.headline)
            Text(item.status.displayName)
                .font(.subheadline)
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
        .padding(.vertical, 2)
    }
}

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
    }

    private struct EvidenceRow: View {

        let record: EvidenceRecord
        let captureItems: [CaptureItem]

        var body: some View {
            HStack(spacing: 12) {
    #if canImport(UIKit)
                if let image = imageForRecord {
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
                    Text("Photo")
                        .font(.headline)
                    if let captureItemName = captureItemDisplayName {
                        Text("Capture Item: \(captureItemName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let localUri = record.localUri {
                        Text(localUri)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 2)
        }

        private var placeholder: some View {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }

    #if canImport(UIKit)
        private var imageForRecord: UIImage? {
            guard let localUri = record.localUri else { return nil }
            let url = EvidenceMediaStore.resolveURL(for: localUri)
            return UIImage(contentsOfFile: url.path)
        }
    #endif

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
        .onChange(of: tag) { newTag in
            twinArea = newTag.defaultTwinArea
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

private extension TwinArea {
    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .house:
            return "House"
        case .home:
            return "Home"
        }
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