#if canImport(SwiftUI) && canImport(AVFoundation) && canImport(UIKit)
import AVFoundation
import SwiftUI
import UIKit

public struct PhotoCaptureView: View {

    @Environment(\.dismiss) private var dismiss

    private let visitId: UUID
    private let preferredTwinArea: TwinArea
    private let onCapture: (CaptureItem, EvidenceRecord) -> Void

    @State private var captureItems: [CaptureItem]
    @State private var showNativeCamera = false
    @State private var showTagSheet = false
    @State private var pendingCapture: PendingCapture?
    @State private var attachToExistingItem = false
    @State private var selectedCaptureItemId: UUID?
    @State private var selectedTag: ObjectTag
    @State private var selectedTwinArea: TwinArea
    @State private var selectedStatus: CaptureStatus = .unknown
    @State private var spaceLabel = ""
    @State private var recentTags = RecentObjectTags()
    @State private var errorMessage: String?

    public init(
        visit: Visit,
        onCapture: @escaping (CaptureItem, EvidenceRecord) -> Void,
        preferredTwinArea: TwinArea? = nil
    ) {
        let resolvedTwinArea = preferredTwinArea ?? visit.captureItems.first?.twinArea ?? .system
        let defaultTag = resolvedTwinArea.defaultObjectTag
        self.visitId = visit.id
        self.preferredTwinArea = resolvedTwinArea
        self.onCapture = onCapture
        _captureItems = State(initialValue: visit.captureItems)
        _selectedCaptureItemId = State(
            initialValue: visit.captureItems.first(where: { $0.twinArea == resolvedTwinArea })?.id ?? visit.captureItems.first?.id
        )
        _selectedTag = State(initialValue: defaultTag)
        _selectedTwinArea = State(initialValue: defaultTag.defaultTwinArea)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(.secondary)
                            Text("Use the native camera to capture photo or video evidence.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }

                if !recentTags.tags.isEmpty {
                    Text("Recent: \(recentTags.tags.prefix(3).map(\.displayName).joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Open Camera") {
                    showNativeCamera = true
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Open camera")
            }
            .padding()
            .navigationTitle("Capture Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showNativeCamera) {
            NativeCameraCaptureView(
                onCapturePhoto: { photoData in
                    pendingCapture = .photo(photoData)
                    prepareTagSheet()
                    showTagSheet = true
                },
                onCaptureVideo: { videoURL in
                    pendingCapture = .video(videoURL)
                    prepareTagSheet()
                    showTagSheet = true
                },
                onFailure: { error in
                    errorMessage = "Failed to capture media: \(error.localizedDescription)"
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showTagSheet) {
            PhotoTagSheetView(
                captureItems: captureItems,
                recentTags: recentTags.tags,
                attachToExistingItem: $attachToExistingItem,
                selectedCaptureItemId: $selectedCaptureItemId,
                selectedTag: $selectedTag,
                selectedTwinArea: $selectedTwinArea,
                selectedStatus: $selectedStatus,
                spaceLabel: $spaceLabel,
                title: pendingCapture?.tagTitle ?? "Tag Evidence",
                onRetake: retakeCapture,
                onDiscard: clearPendingCapture,
                onSave: saveCapturedEvidence
            )
        }
        .alert("Capture Error", isPresented: captureErrorPresented, actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Unknown camera error.")
        })
        .onDisappear {
            cleanupPendingCaptureAsset()
        }
    }

    private var captureErrorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func prepareTagSheet() {
        let preferredTag = recentTags.tags.first ?? preferredTwinArea.defaultObjectTag
        attachToExistingItem = !captureItems.isEmpty
        selectedCaptureItemId = captureItems.first(where: { $0.twinArea == preferredTwinArea })?.id ?? captureItems.first?.id
        selectedTag = preferredTag
        selectedTwinArea = preferredTag.defaultTwinArea
        selectedStatus = .unknown
        spaceLabel = ""
        if attachToExistingItem {
            applySelectedCaptureItemDefaults()
        }
    }

    private func saveCapturedEvidence() {
        guard let pendingCapture else { return }

        let captureItem = resolvedCaptureItemForSave()

        do {
            let evidenceId = UUID()
            let storedPath: String
            let evidenceType: EvidenceType

            switch pendingCapture {
            case .photo(let photoData):
                storedPath = try EvidenceMediaStore.savePhotoData(
                    photoData,
                    visitId: visitId,
                    evidenceId: evidenceId
                )
                evidenceType = .photo
            case .video(let videoURL):
                storedPath = try EvidenceMediaStore.saveVideoFile(
                    from: videoURL,
                    visitId: visitId,
                    evidenceId: evidenceId
                )
                evidenceType = .video
            }

            let record = EvidenceRecord(
                id: evidenceId,
                visitId: visitId,
                captureItemId: captureItem.id,
                evidenceType: evidenceType,
                localUri: storedPath,
                provenanceLevel: .surveyor
            )
            recentTags.record(captureItem.tag)
            onCapture(captureItem, record)
            clearPendingCapture()
            dismiss()
        } catch {
            errorMessage = "Failed to save evidence: \(error.localizedDescription)"
        }
    }

    private func resolvedCaptureItemForSave() -> CaptureItem {
        if attachToExistingItem,
           let selectedCaptureItemId,
           var existingItem = captureItems.first(where: { $0.id == selectedCaptureItemId }) {
            existingItem.visitId = visitId
            existingItem.tag = selectedTag
            existingItem.twinArea = selectedTwinArea
            existingItem.status = selectedStatus
            existingItem.spaceLabel = spaceLabel.nilIfBlank
            existingItem.updatedAt = Date()
            if let index = captureItems.firstIndex(where: { $0.id == existingItem.id }) {
                captureItems[index] = existingItem
            }
            return existingItem
        }

        let newItem = CaptureItem(
            visitId: visitId,
            twinArea: selectedTwinArea,
            tag: selectedTag,
            status: selectedStatus,
            spaceLabel: spaceLabel.nilIfBlank
        )
        captureItems.append(newItem)
        selectedCaptureItemId = newItem.id
        return newItem
    }

    private func retakeCapture() {
        clearPendingCapture()
        showNativeCamera = true
    }

    private func clearPendingCapture() {
        cleanupPendingCaptureAsset()
        pendingCapture = nil
        showTagSheet = false
    }

    private func cleanupPendingCaptureAsset() {
        guard case .video(let videoURL) = pendingCapture else { return }
        try? FileManager.default.removeItem(at: videoURL)
    }

    private func applySelectedCaptureItemDefaults() {
        guard attachToExistingItem,
              let selectedCaptureItemId,
              let item = captureItems.first(where: { $0.id == selectedCaptureItemId }) else {
            return
        }
        selectedTag = item.tag
        selectedTwinArea = item.twinArea
        selectedStatus = item.status
        spaceLabel = item.spaceLabel ?? ""
    }
}

private enum PendingCapture {
    case photo(Data)
    case video(URL)

    var tagTitle: String {
        switch self {
        case .photo:
            return "Tag Photo"
        case .video:
            return "Tag Video"
        }
    }
}

private struct NativeCameraCaptureView: UIViewControllerRepresentable {
    let onCapturePhoto: (Data) -> Void
    let onCaptureVideo: (URL) -> Void
    let onFailure: (Error) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        controller.videoQuality = .typeMedium
        controller.mediaTypes = ["public.image", "public.movie"]
        controller.videoMaximumDuration = 300
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: NativeCameraCaptureView

        init(parent: NativeCameraCaptureView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { parent.dismiss() }

            guard let mediaType = info[.mediaType] as? String else {
                parent.onFailure(
                    NSError(
                        domain: "PhotoCapture",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No media type returned by the camera."]
                    )
                )
                return
            }

            if mediaType == "public.image" {
                if let imageURL = info[.imageURL] as? URL,
                   let imageData = try? Data(contentsOf: imageURL) {
                    parent.onCapturePhoto(imageData)
                    return
                }

                if let image = info[.originalImage] as? UIImage,
                   let imageData = image.jpegData(compressionQuality: 0.92) {
                    parent.onCapturePhoto(imageData)
                    return
                }

                parent.onFailure(
                    NSError(
                        domain: "PhotoCapture",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "No photo data was returned by the camera."]
                    )
                )
                return
            }

            if mediaType == "public.movie",
               let movieURL = info[.mediaURL] as? URL {
                parent.onCaptureVideo(movieURL)
                return
            }

            parent.onFailure(
                NSError(
                    domain: "PhotoCapture",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Unsupported media type was returned by the camera."]
                )
            )
        }
    }
}

private struct PhotoTagSheetView: View {

    private static let quickTagOptions: [(title: String, tag: ObjectTag)] = [
        ("Boiler", .boiler),
        ("Cylinder", .cylinder),
        ("Flue", .flue),
        ("Controls", .programmer),
        ("Gas Meter", .gasMeter),
        ("Consumer Unit", .consumerUnit),
        ("Risk", .risk),
    ]

    let captureItems: [CaptureItem]
    let recentTags: [ObjectTag]
    @Binding var attachToExistingItem: Bool
    @Binding var selectedCaptureItemId: UUID?
    @Binding var selectedTag: ObjectTag
    @Binding var selectedTwinArea: TwinArea
    @Binding var selectedStatus: CaptureStatus
    @Binding var spaceLabel: String
    let title: String

    let onRetake: () -> Void
    let onDiscard: () -> Void
    let onSave: () -> Void

    @State private var hasManualTwinAreaOverride = false

    var body: some View {
        NavigationStack {
            Form {
                if !captureItems.isEmpty {
                    Section("Attach") {
                        Toggle("Attach to Existing Capture Item", isOn: $attachToExistingItem)
                        if attachToExistingItem {
                            Picker("Capture Item", selection: selectedItemBinding) {
                                ForEach(captureItems) { item in
                                    Text(item.tag.displayName).tag(item.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                Section("Quick Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.quickTagOptions, id: \.title) { quickTag in
                                Button(quickTag.title) {
                                    selectedTag = quickTag.tag
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(selectedTag == quickTag.tag ? .blue : .secondary)
                            }
                        }
                    }
                }

                if !recentTags.isEmpty {
                    Section("Recent Tags") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentTags, id: \.self) { tag in
                                    Button(tag.displayName) {
                                        selectedTag = tag
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Section("Tag Details") {
                    Picker("Object Tag", selection: $selectedTag) {
                        ForEach(ObjectTag.allCases, id: \.self) { tag in
                            Text(tag.displayName).tag(tag)
                        }
                    }
                    Picker("Twin Area", selection: $selectedTwinArea) {
                        ForEach(TwinArea.allCases, id: \.self) { area in
                            Text(area.displayName).tag(area)
                        }
                    }
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(CaptureStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    TextField("Space Label (optional)", text: $spaceLabel)
                }

                Section {
                    Button("Retake") { onRetake() }
                    Button("Discard", role: .destructive) { onDiscard() }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                }
            }
        }
        .onAppear {
            if attachToExistingItem {
                applySelectedItem()
            } else {
                hasManualTwinAreaOverride = selectedTwinArea != selectedTag.defaultTwinArea
            }
        }
        .onChange(of: selectedTag) { _, newTag in
            if !hasManualTwinAreaOverride {
                selectedTwinArea = newTag.defaultTwinArea
            }
        }
        .onChange(of: selectedTwinArea) { _, newTwinArea in
            hasManualTwinAreaOverride = newTwinArea != selectedTag.defaultTwinArea
        }
        .onChange(of: attachToExistingItem) { _, shouldAttach in
            if shouldAttach {
                if selectedCaptureItemId == nil {
                    selectedCaptureItemId = captureItems.first?.id
                }
                applySelectedItem()
            } else {
                hasManualTwinAreaOverride = selectedTwinArea != selectedTag.defaultTwinArea
            }
        }
        .onChange(of: selectedCaptureItemId) { _, _ in
            if attachToExistingItem {
                applySelectedItem()
            }
        }
    }

    private var selectedItemBinding: Binding<UUID> {
        Binding(
            get: { selectedCaptureItemId ?? captureItems.first?.id ?? UUID() },
            set: { selectedCaptureItemId = $0 }
        )
    }

    private func applySelectedItem() {
        guard let selectedCaptureItemId,
              let item = captureItems.first(where: { $0.id == selectedCaptureItemId }) else {
            return
        }
        selectedTag = item.tag
        selectedTwinArea = item.twinArea
        selectedStatus = item.status
        spaceLabel = item.spaceLabel ?? ""
        hasManualTwinAreaOverride = item.twinArea != item.tag.defaultTwinArea
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
