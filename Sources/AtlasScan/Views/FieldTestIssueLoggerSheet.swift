#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

struct FieldTestIssueLoggerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let visitId: UUID
    let onSave: (FieldTestNote) -> Void

    @State private var category: FieldTestIssueCategory = .captureFriction
    @State private var details = ""
    @State private var photoLocalUri: String?
    @State private var voiceLocalUri: String?
    @State private var voiceDurationSeconds: TimeInterval?
    @State private var showPhotoCapture = false
    @State private var errorMessage: String?
    #if canImport(AVFoundation)
    @State private var recorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var isRecordingVoice = false
    #endif

    var body: some View {
        NavigationStack {
            Form {
                Section("Issue") {
                    Picker("Category", selection: $category) {
                        ForEach(FieldTestIssueCategory.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    TextField("What broke?", text: $details, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Attachments") {
                    #if canImport(UIKit)
                    Button(photoLocalUri == nil ? "Attach Photo" : "Retake Photo") {
                        showPhotoCapture = true
                    }
                    if let photoLocalUri {
                        Text(photoLocalUri)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Button("Remove Photo", role: .destructive) {
                            self.photoLocalUri = nil
                        }
                    }
                    #else
                    Text("Photo attachment not available on this platform.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif

                    #if canImport(AVFoundation)
                    Button(isRecordingVoice ? "Stop Voice Note" : (voiceLocalUri == nil ? "Record Voice Note" : "Re-record Voice Note")) {
                        toggleVoiceNoteRecording()
                    }
                    if let voiceLocalUri {
                        Text(voiceLocalUri)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Button("Remove Voice Note", role: .destructive) {
                            self.voiceLocalUri = nil
                            self.voiceDurationSeconds = nil
                        }
                    }
                    #else
                    Text("Voice attachment not available on this platform.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif
                }
            }
            .navigationTitle("Log Field Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cleanupRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIssue()
                    }
                    .disabled(trimmedDetails.isEmpty)
                }
            }
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showPhotoCapture) {
            FieldTestPhotoCaptureView(
                onCapture: { capture in
                    storePhotoAttachment(capture)
                },
                onFailure: { error in
                    errorMessage = "Photo capture failed: \(error.localizedDescription)"
                }
            )
            .ignoresSafeArea()
        }
        #endif
        .alert("Issue Logging Error", isPresented: errorPresented, actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Unknown error.")
        })
        .onDisappear {
            cleanupRecording()
        }
    }

    private var trimmedDetails: String {
        details.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func saveIssue() {
        onSave(
            FieldTestNote(
                category: category,
                details: trimmedDetails,
                photoLocalUri: photoLocalUri,
                voiceLocalUri: voiceLocalUri,
                voiceDurationSeconds: voiceDurationSeconds
            )
        )
        cleanupRecording()
        dismiss()
    }

    private func storePhotoAttachment(_ data: Data) {
        do {
            let path = try EvidenceMediaStore.savePhotoData(
                data,
                visitId: visitId,
                evidenceId: UUID()
            )
            photoLocalUri = path
        } catch {
            errorMessage = "Failed to save photo attachment: \(error.localizedDescription)"
        }
    }

    #if canImport(AVFoundation)
    private func toggleVoiceNoteRecording() {
        if isRecordingVoice {
            stopVoiceNoteRecording()
        } else {
            startVoiceNoteRecording()
        }
    }

    private func startVoiceNoteRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        let permission = MicrophonePermission.current()
        guard permission == .granted else {
            if permission == .undetermined {
                MicrophonePermission.request { permission in
                    DispatchQueue.main.async {
                        if permission == .granted {
                            startVoiceNoteRecording()
                        } else {
                            errorMessage = "Microphone access is required to attach a voice note."
                        }
                    }
                }
            } else {
                errorMessage = "Microphone access is required to attach a voice note."
            }
            return
        }

        let recordingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            let recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            recorder.record()
            self.recorder = recorder
            self.recordingURL = recordingURL
            self.isRecordingVoice = true
        } catch {
            errorMessage = "Failed to start voice recording: \(error.localizedDescription)"
        }
    }

    private func stopVoiceNoteRecording() {
        guard let recorder, let recordingURL else { return }
        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        isRecordingVoice = false
        do {
            let data = try Data(contentsOf: recordingURL)
            let path = try EvidenceMediaStore.saveAudioData(
                data,
                visitId: visitId,
                evidenceId: UUID()
            )
            voiceLocalUri = path
            voiceDurationSeconds = max(duration, 0)
            try? FileManager.default.removeItem(at: recordingURL)
            self.recordingURL = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to save voice attachment: \(error.localizedDescription)"
        }
    }

    private func cleanupRecording() {
        recorder?.stop()
        recorder = nil
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
            self.recordingURL = nil
        }
        isRecordingVoice = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    #else
    private func cleanupRecording() {}
    #endif
}

#if canImport(UIKit)
private struct FieldTestPhotoCaptureView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    let onFailure: (Error) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: FieldTestPhotoCaptureView

        init(_ parent: FieldTestPhotoCaptureView) {
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

            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.8) else {
                parent.onFailure(FieldTestPhotoCaptureError.invalidCapture)
                return
            }
            parent.onCapture(data)
        }
    }
}

private enum FieldTestPhotoCaptureError: Error {
    case invalidCapture
}
#endif
#endif
