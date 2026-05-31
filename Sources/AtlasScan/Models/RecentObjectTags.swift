import Foundation

/// Tracks recently used `ObjectTag` values in most-recent-first order.
public struct RecentObjectTags: Equatable, Sendable {
    public static let maxCount = 8

    public private(set) var tags: [ObjectTag]

    public init(tags: [ObjectTag] = []) {
        self.tags = Array(tags.prefix(Self.maxCount))
    }

    public mutating func record(_ tag: ObjectTag) {
        tags.removeAll { $0 == tag }
        tags.insert(tag, at: 0)
        if tags.count > Self.maxCount {
            tags.removeLast(tags.count - Self.maxCount)
        }
    }
}
