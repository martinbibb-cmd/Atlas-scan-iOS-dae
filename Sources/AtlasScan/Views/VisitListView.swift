#if canImport(SwiftUI)
import SwiftUI

/// The root screen — lists all visits and provides a button to create one.
public struct VisitListView: View {

    @ObservedObject public var store: VisitStore
    @State private var showCreate = false

    public init(store: VisitStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.visits.isEmpty {
                    emptyState
                } else {
                    visitList
                }
            }
            .navigationTitle("Visits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Visit") { showCreate = true }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateVisitSheet(store: store)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Visits",
            systemImage: "house",
            description: Text("Tap New Visit to start a survey.")
        )
    }

    private var visitList: some View {
        List {
            ForEach(store.visits) { visit in
                NavigationLink {
                   VisitDashboardView(visit: visit, store: store)
                } label: {
                    VisitRowView(visit: visit)
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { store.delete(store.visits[$0]) }
            }
        }
    }
}

// MARK: - VisitRowView

private struct VisitRowView: View {

    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(visit.title)
                .font(.headline)
            if let name = visit.customerName {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let address = visit.addressSummary {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(visit.status.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch visit.status {
        case .draft:     return .orange
        case .active:    return .green
        case .completed: return .blue
        case .exported:  return .gray
        }
    }
}
#endif