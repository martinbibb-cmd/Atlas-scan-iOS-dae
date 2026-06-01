#if canImport(AVFoundation)
import AVFoundation

enum MicrophonePermission {
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
#endif
