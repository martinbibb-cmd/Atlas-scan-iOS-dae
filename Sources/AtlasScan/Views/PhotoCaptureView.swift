#if canImport(SwiftUI) && canImport(AVFoundation) && canImport(UIKit)
import AVFoundation
import SwiftUI
import UIKit

public struct PhotoCaptureView: View {

    @Environment(\.dismiss) private var dismiss

    private let visitId: UUID
    private let onCapture: (CaptureItem, EvidenceRecord) -> Void

    @StateObject private var cameraController = CameraSessionController()
    @State private var captureItems: [CaptureItem]
    @State private var selectedCaptureItemId: UUID?
    @State private var showCaptureItemEditor = false
    @State private var errorMessage: String?

    public init(visit: Visit, onCapture: @escaping (CaptureItem, EvidenceRecord) -> Void) {
        self.visitId = visit.id
        self.onCapture = onCapture
        _captureItems = State(initialValue: visit.captureItems)
        _selectedCaptureItemId = State(initialValue: visit.captureItems.first?.id)
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
        .sheet(isPresented: $showCaptureItemEditor) {
            CaptureItemQuickCreateView(visitId: visitId) { item in
                captureItems.append(item)
                selectedCaptureItemId = item.id
            }
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
            if captureItems.isEmpty {
                Text("Create a capture item before taking a photo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Capture Item", selection: selectedItemBinding) {
                    ForEach(captureItems) { item in
                        Text(item.tag.displayName).tag(item.id)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Button("New Capture Item") {
                    showCaptureItemEditor = true
                }

                Spacer()

                if cameraController.hasTorch {
                    Button(cameraController.isTorchEnabled ? "Torch Off" : "Torch On") {
                        cameraController.toggleTorch()
                    }
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
                cameraController.authorizationStatus != .authorized ||
                selectedCaptureItemId == nil
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

    private var selectedItemBinding: Binding<UUID> {
        Binding(
            get: { selectedCaptureItemId ?? captureItems.first?.id ?? UUID() },
            set: { selectedCaptureItemId = $0 }
        )
    }

    private var captureErrorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func takePhoto() {
        guard let selectedCaptureItemId,
              let selectedCaptureItem = captureItems.first(where: { $0.id == selectedCaptureItemId }) else {
            showCaptureItemEditor = true
            return
        }

        cameraController.capturePhoto { result in
            switch result {
            case .success(let data):
                do {
                    let evidenceId = UUID()
                    let storedPath = try EvidenceMediaStore.savePhotoData(
                        data,
                        visitId: visitId,
                        evidenceId: evidenceId
                    )
                    let record = EvidenceRecord(
                        id: evidenceId,
                        visitId: visitId,
                        captureItemId: selectedCaptureItem.id,
                        evidenceType: .photo,
                        localUri: storedPath,
                        provenanceLevel: .surveyor
                    )
                    onCapture(selectedCaptureItem, record)
                    dismiss()
                } catch {
                    errorMessage = "Failed to save photo."
                }
            case .failure:
                errorMessage = "Failed to capture photo."
            }
        }
    }
}

private struct CaptureItemQuickCreateView: View {

    @Environment(\.dismiss) private var dismiss

    let visitId: UUID
    let onSave: (CaptureItem) -> Void

    @State private var tag: ObjectTag = .boiler
    @State private var spaceLabel = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Object") {
                    Picker("Tag", selection: $tag) {
                        ForEach(ObjectTag.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                }
                Section("Optional") {
                    TextField("Space Label", text: $spaceLabel)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle("New Capture Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = CaptureItem(
                            visitId: visitId,
                            twinArea: tag.defaultTwinArea,
                            tag: tag,
                            status: .unknown,
                            spaceLabel: spaceLabel.nilIfBlank,
                            notes: notes.nilIfBlank
                        )
                        onSave(item)
                        dismiss()
                    }
                }
            }
        }
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
        } catch {}
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
            captureCompletion?(.failure(NSError(domain: "PhotoCapture", code: -1)))
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

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
#endif
