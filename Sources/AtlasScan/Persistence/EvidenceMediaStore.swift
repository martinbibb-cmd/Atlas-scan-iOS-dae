import Foundation

public enum EvidenceMediaStore {

    public static let mediaRootDirectoryName = "VisitMedia"

    public static func savePhotoData(
        _ data: Data,
        visitId: UUID,
        evidenceId: UUID,
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) throws -> String {
        try saveMediaData(
            data,
            visitId: visitId,
            evidenceId: evidenceId,
            fileExtension: "jpg",
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )
    }

    public static func saveAudioData(
        _ data: Data,
        visitId: UUID,
        evidenceId: UUID,
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) throws -> String {
        try saveMediaData(
            data,
            visitId: visitId,
            evidenceId: evidenceId,
            fileExtension: "m4a",
            fileManager: fileManager,
            baseDirectory: baseDirectory
        )
    }

    public static func saveVideoFile(
        from sourceURL: URL,
        visitId: UUID,
        evidenceId: UUID,
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) throws -> String {
        let videoExtension = normalizedVideoExtension(sourceURL.pathExtension)
        let visitDirectory = documentsDirectory(fileManager: fileManager, baseDirectory: baseDirectory)
            .appendingPathComponent(mediaRootDirectoryName, isDirectory: true)
            .appendingPathComponent(visitId.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: visitDirectory, withIntermediateDirectories: true)

        let fileName = "\(evidenceId.uuidString).\(videoExtension)"
        let destinationURL = visitDirectory.appendingPathComponent(fileName, isDirectory: false)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        return "\(mediaRootDirectoryName)/\(visitId.uuidString)/\(fileName)"
    }

    private static func saveMediaData(
        _ data: Data,
        visitId: UUID,
        evidenceId: UUID,
        fileExtension: String,
        fileManager: FileManager,
        baseDirectory: URL?
    ) throws -> String {
        let visitDirectory = documentsDirectory(fileManager: fileManager, baseDirectory: baseDirectory)
            .appendingPathComponent(mediaRootDirectoryName, isDirectory: true)
            .appendingPathComponent(visitId.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: visitDirectory, withIntermediateDirectories: true)

        let fileName = "\(evidenceId.uuidString).\(fileExtension)"
        let fileURL = visitDirectory.appendingPathComponent(fileName, isDirectory: false)
        try data.write(to: fileURL, options: .atomic)

        return "\(mediaRootDirectoryName)/\(visitId.uuidString)/\(fileName)"
    }

    public static func resolveURL(
        for storedPath: String,
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) -> URL {
        if let absoluteURL = URL(string: storedPath), absoluteURL.isFileURL {
            return absoluteURL
        }
        return documentsDirectory(fileManager: fileManager, baseDirectory: baseDirectory)
            .appendingPathComponent(storedPath)
    }

    private static func normalizedVideoExtension(_ sourceExtension: String) -> String {
        let sanitized = sourceExtension.lowercased()
        if sanitized == "mp4" {
            return "mp4"
        }
        return "mov"
    }

    private static func documentsDirectory(fileManager: FileManager, baseDirectory: URL?) -> URL {
        if let baseDirectory {
            return baseDirectory
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
