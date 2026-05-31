#if canImport(SwiftUI) && canImport(AVFoundation) && canImport(UIKit)
import AVFoundation
import SwiftUI
import UIKit

public struct PhotoCaptureView: View {

    @Environment(\.dismiss) private var dismiss

    private let visitId: UUID
    private let preferredTwinArea: TwinArea
    private let onCapture: (CaptureItem, EvidenceRecord) -> Void

    @StateObject private var cameraController = CameraSessionController()
    @State private var captureItems: [CaptureItem]
    @State private var showTagSheet = false
    @State private var pendingPhotoData: Data?
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
            VStack(spacing: 12) {
                cameraContent
                controls
            }
            .padding()
            .navigationTitle("Capture Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            cameraController.requestAccessIfNeeded()
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
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
                onRetake: clearPendingCapture,
                onDiscard: clearPendingCapture,
                onSave: saveCapturedPhoto
            )
        }
        .alert("Capture Error", isPresented: captureErrorPresented, actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Unknown camera error.")
        })
    }

    @ViewBuilder
    private var cameraContent: some View {
        switch cameraController.authorizationStatus {
        case .authorized:
            CameraPreview(session: cameraController.session)
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        case .notDetermined:
            permissionPlaceholder(
                title: "Camera access required",
                subtitle: "Atlas Scan needs camera access to capture evidence."
            )
        case .denied, .restricted:
            VStack(spacing: 12) {
                permissionPlaceholder(
                    title: "Camera access denied",
                    subtitle: "Enable camera access in Settings to capture photos."
                )
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }
        @unknown default:
            permissionPlaceholder(
                title: "Camera unavailable",
                subtitle: "Camera access is not available right now."
            )
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack {
                if cameraController.hasTorch {
                    Button(cameraController.isTorchEnabled ? "Torch Off" : "Torch On") {
                        cameraController.toggleTorch()
                    }
                }
                Spacer()
                if !recentTags.tags.isEmpty {
                    Text("Recent: \(recentTags.tags.prefix(3).map(\.displayName).joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Button {
                takePhoto()
            } label: {
                Circle()
                    .strokeBorder(.white, lineWidth: 6)
                    .background(Circle().fill(Color.red))
                    .frame(width: 78, height: 78)
            }
            .disabled(
                cameraController.authorizationStatus != .authorized
            )
            .accessibilityLabel("Shutter")
        }
    }

    private func permissionPlaceholder(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.fill")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var captureErrorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func takePhoto() {
        cameraController.capturePhoto { result in
            switch result {
            case .success(let data):
                pendingPhotoData = data
                prepareTagSheet()
                showTagSheet = true
            case .failure(let error):
                errorMessage = "Failed to capture photo: \(error.localizedDescription)"
            }
        }
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

    private func saveCapturedPhoto() {
        guard let pendingPhotoData else { return }

        let captureItem = resolvedCaptureItemForSave()

        do {
            let evidenceId = UUID()
            let storedPath = try EvidenceMediaStore.savePhotoData(
                pendingPhotoData,
                visitId: visitId,
                evidenceId: evidenceId
            )
            let record = EvidenceRecord(
                id: evidenceId,
                visitId: visitId,
                captureItemId: captureItem.id,
                evidenceType: .photo,
                localUri: storedPath,
                provenanceLevel: .surveyor
            )
            recentTags.record(captureItem.tag)
            onCapture(captureItem, record)
            clearPendingCapture()
            dismiss()
        } catch {
            errorMessage = "Failed to save photo: \(error.localizedDescription)"
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

    private func clearPendingCapture() {
        pendingPhotoData = nil
        showTagSheet = false
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
            .navigationTitle("Tag Photo")
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
        .onChange(of: selectedTag) { newTag in
            if !hasManualTwinAreaOverride {
                selectedTwinArea = newTag.defaultTwinArea
            }
        }
        .onChange(of: selectedTwinArea) { newTwinArea in
            hasManualTwinAreaOverride = newTwinArea != selectedTag.defaultTwinArea
        }
        .onChange(of: attachToExistingItem) { shouldAttach in
            if shouldAttach {
                if selectedCaptureItemId == nil {
                    selectedCaptureItemId = captureItems.first?.id
                }
                applySelectedItem()
            } else {
                hasManualTwinAreaOverride = selectedTwinArea != selectedTag.defaultTwinArea
            }
        }
        .onChange(of: selectedCaptureItemId) { _ in
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

private final class CameraSessionController: NSObject, ObservableObject {

    @Published var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var hasTorch = false
    @Published var isTorchEnabled = false

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "AtlasScan.CameraSession")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var captureCompletion: ((Result<Data, Error>) -> Void)?

    func requestAccessIfNeeded() {
        if authorizationStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.startSession()
                    }
                }
            }
        }
    }

    func startSession() {
        guard authorizationStatus == .authorized else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSessionIfNeeded()
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            self.setTorch(enabled: false)
        }
    }

    func toggleTorch() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.setTorch(enabled: !self.isTorchEnabled)
        }
    }

    func capturePhoto(completion: @escaping (Result<Data, Error>) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings.codec = .jpeg
            }
            self.captureCompletion = completion
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input),
              session.canAddOutput(photoOutput) else {
            return
        }

        session.addInput(input)
        session.addOutput(photoOutput)

        DispatchQueue.main.async {
            self.hasTorch = camera.hasTorch
        }
    }

    private func setTorch(enabled: Bool) {
        guard let deviceInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        let device = deviceInput.device
        guard device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if enabled {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
            DispatchQueue.main.async {
                self.isTorchEnabled = enabled
            }
        } catch {
            print("Torch toggle failed: \(error.localizedDescription)")
        }
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            captureCompletion?(.failure(error))
            captureCompletion = nil
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            captureCompletion?(
                .failure(
                    NSError(
                        domain: "PhotoCapture",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to obtain photo data representation."]
                    )
                )
            )
            captureCompletion = nil
            return
        }
        captureCompletion?(.success(data))
        captureCompletion = nil
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
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
