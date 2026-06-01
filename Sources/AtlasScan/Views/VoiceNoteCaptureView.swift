#if canImport(SwiftUI) && canImport(AVFoundation) && canImport(UIKit)
import AVFoundation
import SwiftUI
import UIKit

private enum MicrophonePermission {
    case undetermined
    case denied
    case granted

    static func current() -> Self {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            return .undetermined
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    static func request(_ completion: @escaping (Self) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            completion(granted ? .granted : .denied)
        }
    }
}

public struct VoiceNoteCaptureView: View {

    @Environment(\.dismiss) private var dismiss

    private let visitId: UUID
    private let onCapture: (EvidenceRecord) -> Void

    @StateObject private var recorderController = VoiceRecorderController()
    @State private var captureItems: [CaptureItem]
    @State private var selectedCaptureItemId: UUID?
    @State private var tempFileURL: URL?
    @State private var recordedDurationSeconds: TimeInterval?
    @State private var errorMessage: String?

    public init(visit: Visit, onCapture: @escaping (EvidenceRecord) -> Void) {
        self.visitId = visit.id
        self.onCapture = onCapture
        _captureItems = State(initialValue: visit.captureItems)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Attach To") {
                    Picker("Target", selection: $selectedCaptureItemId) {
                        Text("Visit-level note").tag(UUID?.none)
                        ForEach(captureItems) { item in
                            Text(captureItemTitle(item)).tag(UUID?.some(item.id))
                        }
                    }
                }

                Section("Recorder") {
                    HStack {
                        Label(
                            recorderController.isRecording ? "Recording…" : "Ready",
                            systemImage: recorderController.isRecording ? "waveform.circle.fill" : "waveform"
                        )
                        Spacer()
                        Text(formattedDuration(recorderController.elapsedSeconds))
                            .monospacedDigit()
                    }

                    if recorderController.isRecording {
                        Button("Stop Recording") {
                            recordedDurationSeconds = recorderController.stopRecording()
                        }
                    } else {
                        Button("Start Recording") {
                            startRecording()
                        }
                    }

                    if recordedDurationSeconds != nil {
                        Button("Save Voice Note") {
                            saveVoiceNote()
                        }
                    }
                }
            }
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        recorderController.cancelRecording()
                        cleanupTemporaryAudio()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            recorderController.requestPermissionIfNeeded()
        }
        .onDisappear {
            recorderController.cancelRecording()
            cleanupTemporaryAudio()
        }
        .alert("Voice Note Error", isPresented: errorPresented, actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "Unknown recording error.")
        })
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func startRecording() {
        let permission = recorderController.permission
        if permission == .undetermined {
            recorderController.requestPermissionIfNeeded()
            return
        }
        guard permission == .granted else {
            errorMessage = "Microphone access is required. Enable it in Settings."
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("m4a")
        tempFileURL = url
        recordedDurationSeconds = nil

        do {
            try recorderController.startRecording(to: url)
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func saveVoiceNote() {
        guard let tempFileURL else {
            errorMessage = "No recording available to save."
            return
        }
        do {
            let data = try Data(contentsOf: tempFileURL)
            let evidenceId = UUID()
            let storedPath = try EvidenceMediaStore.saveAudioData(
                data,
                visitId: visitId,
                evidenceId: evidenceId
            )
            let record = EvidenceRecord(
                id: evidenceId,
                visitId: visitId,
                captureItemId: selectedCaptureItemId,
                evidenceType: .voice,
                localUri: storedPath,
                voiceDurationSeconds: recordedDurationSeconds,
                provenanceLevel: .surveyor
            )
            onCapture(record)
            cleanupTemporaryAudio()
            dismiss()
        } catch {
            errorMessage = "Failed to save voice note: \(error.localizedDescription)"
        }
    }

    private func cleanupTemporaryAudio() {
        guard let tempFileURL else { return }
        try? FileManager.default.removeItem(at: tempFileURL)
        self.tempFileURL = nil
        recordedDurationSeconds = nil
    }

    private func captureItemTitle(_ item: CaptureItem) -> String {
        if let space = item.spaceLabel, !space.isEmpty {
            return "\(item.tag.displayName) • \(space)"
        }
        return item.tag.displayName
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

private final class VoiceRecorderController: NSObject, ObservableObject {

    @Published private(set) var permission: MicrophonePermission
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    private let audioSession = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private static let sampleRate: Double = 44_100
    private static let channelCount = 1
    private static let audioQuality = AVAudioQuality.high.rawValue

    override init() {
        permission = MicrophonePermission.current()
        super.init()
    }

    func requestPermissionIfNeeded() {
        guard permission == .undetermined else { return }
        MicrophonePermission.request { [weak self] permission in
            DispatchQueue.main.async {
                self?.permission = permission
            }
        }
    }

    func startRecording(to url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Self.sampleRate,
            AVNumberOfChannelsKey: Self.channelCount,
            AVEncoderAudioQualityKey: Self.audioQuality,
        ]

        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        elapsedSeconds = 0
        isRecording = true
        startTimer()
    }

    @discardableResult
    func stopRecording() -> TimeInterval {
        let duration = recorder?.currentTime ?? elapsedSeconds
        recorder?.stop()
        recorder = nil
        stopTimer()
        isRecording = false
        elapsedSeconds = duration
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        return duration
    }

    func cancelRecording() {
        recorder?.stop()
        recorder = nil
        stopTimer()
        isRecording = false
        elapsedSeconds = 0
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds = self.recorder?.currentTime ?? self.elapsedSeconds
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
#endif
