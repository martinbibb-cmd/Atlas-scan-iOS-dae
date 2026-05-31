import Foundation
#if canImport(Combine)
import Combine
#endif

/// Persists and manages the ordered list of survey visits as a JSON file on disk.
///
/// All mutations are written atomically after each change so that a relaunch
/// always resumes from the last known state.
///
/// - Note: Designed for use on the main thread in SwiftUI via `@StateObject` /
///         `@ObservedObject`. In tests, supply a temporary `fileURL` and call
///         methods directly — no actor isolation is required.
public final class VisitStore {

    #if canImport(Combine)
    @Published public private(set) var visits: [Visit] = []
    #else
    public private(set) var visits: [Visit] = []
    #endif

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Init

    /// Creates a store backed by `fileURL`.
    public init(fileURL: URL) {
        self.fileURL = fileURL

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = .prettyPrinted
        encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        decoder = dec

        load()
    }

    /// Creates a store backed by `visits.json` in the user's Documents directory.
    public convenience init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.init(fileURL: docs.appendingPathComponent("visits.json"))
    }

    // MARK: - CRUD

    /// Appends a new visit and persists.
    public func add(_ visit: Visit) {
        visits.append(visit)
        save()
    }

    /// Replaces the stored visit that shares the same `id` and persists.
    public func update(_ visit: Visit) {
        guard let index = visits.firstIndex(where: { $0.id == visit.id }) else { return }
        visits[index] = visit
        save()
    }

    /// Removes the visit with the matching `id` and persists.
    public func delete(_ visit: Visit) {
        visits.removeAll { $0.id == visit.id }
        save()
    }

    /// Sets the visit's status to `.active` and updates `updatedAt`.
    public func markActive(_ visit: Visit) {
        setStatus(.active, on: visit)
    }

    /// Sets the visit's status to `.completed` and updates `updatedAt`.
    public func markCompleted(_ visit: Visit) {
        setStatus(.completed, on: visit)
    }

    /// Sets the visit's status to `.exported` and updates `updatedAt`.
    public func markExported(_ visit: Visit) {
        setStatus(.exported, on: visit)
    }

    // MARK: - Private

    private func setStatus(_ status: VisitStatus, on visit: Visit) {
        guard let index = visits.firstIndex(where: { $0.id == visit.id }) else { return }
        var updated = visits[index]
        updated.status = status
        updated.updatedAt = Date()
        visits[index] = updated
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            visits = try decoder.decode([Visit].self, from: data)
        } catch {
            visits = []
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(visits)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Surface via logging in a future iteration.
        }
    }
}

#if canImport(Combine)
extension VisitStore: ObservableObject {}
#endif