#if canImport(SwiftUI)
import SwiftUI

struct VisitExportPreviewSheet: View {
    let package: AtlasVisitPackage
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Export Summary") {
                    summaryRow("Capture items", value: package.exportSummary.captureItemCount)
                    summaryRow("Evidence", value: package.exportSummary.evidenceCount)
                    summaryRow("Media", value: package.exportSummary.mediaCount)
                    summaryRow("Missing media", value: package.exportSummary.missingMediaCount)
                    summaryRow("Unresolved", value: package.exportSummary.unresolvedCount)
                }

                if !package.missingMediaWarnings.isEmpty {
                    Section("Warnings") {
                        ForEach(package.missingMediaWarnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Section("Package") {
                    Text("Schema \(package.schemaVersion)")
                    Text(package.packageId.uuidString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Export Preview")
            .iOSNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(package.missingMediaWarnings.isEmpty ? "Export" : "Export Anyway", action: onConfirm)
                }
            }
        }
    }

    private func summaryRow(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .foregroundStyle(.secondary)
        }
    }
}
#endif
