#if canImport(SwiftUI)
import SwiftUI

/// Shows and edits a single visit's metadata and lets the user change its status.
public struct VisitDetailView: View {

    @ObservedObject public var store: VisitStore
    @Environment(\.dismiss) private var dismiss

    @State private var visit: Visit
    @State private var isEditing = false

    public init(visit: Visit, store: VisitStore) {
        _visit = State(initialValue: visit)
        self.store = store
    }

    public var body: some View {
        Form {
            detailSection
            statusSection
            actionSection
            deleteSection
        }
        .navigationTitle(visit.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") { toggleEdit() }
            }
        }
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

    private var actionSection: some View {
        Section {
            statusToggleButton
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
            var toSave = visit
            toSave.updatedAt = Date()
            store.update(toSave)
            visit = toSave
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
}
#endif