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
        let visitDirectory = documentsDirectory(fileManager: fileManager, baseDirectory: baseDirectory)
            .appendingPathComponent(mediaRootDirectoryName, isDirectory: true)
            .appendingPathComponent(visitId.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: visitDirectory, withIntermediateDirectories: true)

        let fileName = "\(evidenceId.uuidString).jpg"
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

    private static func documentsDirectory(fileManager: FileManager, baseDirectory: URL?) -> URL {
        if let baseDirectory {
            return baseDirectory
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
