#if canImport(SwiftUI)
import SwiftUI

/// Modal sheet for creating a new visit.
public struct CreateVisitSheet: View {

    @ObservedObject public var store: VisitStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var customerName = ""
    @State private var addressSummary = ""

    public init(store: VisitStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                }
                Section("Optional") {
                    TextField("Customer Name", text: $customerName)
                    TextField("Address", text: $addressSummary)
                }
            }
            .navigationTitle("New Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createVisit() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Private

    private func createVisit() {
        let visit = Visit(
            title: title.trimmingCharacters(in: .whitespaces),
            status: .active,
            customerName: customerName.isEmpty ? nil : customerName,
            addressSummary: addressSummary.isEmpty ? nil : addressSummary
        )
        store.add(visit)
        dismiss()
    }
}
#endif