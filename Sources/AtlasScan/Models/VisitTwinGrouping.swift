import Foundation

public struct CaptureItemEvidenceGroup: Identifiable, Sendable {
    public let captureItem: CaptureItem
    public let evidenceRecords: [EvidenceRecord]

    public init(captureItem: CaptureItem, evidenceRecords: [EvidenceRecord]) {
        self.captureItem = captureItem
        self.evidenceRecords = evidenceRecords
    }

    public var id: UUID { captureItem.id }
}

public struct TwinAreaSummary: Sendable {
    public let area: TwinArea
    public let captureItems: [CaptureItem]
    public let evidenceRecords: [EvidenceRecord]

    public init(area: TwinArea, captureItems: [CaptureItem], evidenceRecords: [EvidenceRecord]) {
        self.area = area
        self.captureItems = captureItems
        self.evidenceRecords = evidenceRecords
    }

    public var captureItemCount: Int { captureItems.count }
    public var evidenceRecordCount: Int { evidenceRecords.count }
    public var needsReviewCount: Int {
        captureItems.filter { $0.status == .needsReview }.count
    }
    public var unknownCount: Int {
        captureItems.filter { $0.status == .unknown }.count
    }
    public var assumedCount: Int {
        captureItems.filter { $0.status == .assumed }.count
    }
    public var unresolvedCount: Int { needsReviewCount + unknownCount + assumedCount }

    public var captureItemGroups: [CaptureItemEvidenceGroup] {
        captureItems.map { item in
            CaptureItemEvidenceGroup(
                captureItem: item,
                evidenceRecords: evidenceRecords.filter { $0.captureItemId == item.id }
            )
        }
    }
}

// MARK: - VisitProgressSummary

public struct VisitProgressSummary: Sendable {
    public let system: TwinAreaSummary
    public let house: TwinAreaSummary
    public let home: TwinAreaSummary
    public let visitNoteCount: Int

    public init(
        system: TwinAreaSummary,
        house: TwinAreaSummary,
        home: TwinAreaSummary,
        visitNoteCount: Int
    ) {
        self.system = system
        self.house = house
        self.home = home
        self.visitNoteCount = visitNoteCount
    }

    public func areaSummary(for area: TwinArea) -> TwinAreaSummary {
        switch area {
        case .system: return system
        case .house:  return house
        case .home:   return home
        }
    }

    public var totalCapturedCount: Int {
        system.captureItemCount + house.captureItemCount + home.captureItemCount
    }
    public var totalNeedsReviewCount: Int {
        system.needsReviewCount + house.needsReviewCount + home.needsReviewCount
    }
    public var totalUnknownCount: Int {
        system.unknownCount + house.unknownCount + home.unknownCount
    }
    public var totalAssumedCount: Int {
        system.assumedCount + house.assumedCount + home.assumedCount
    }
    public var totalUnresolvedCount: Int {
        totalNeedsReviewCount + totalUnknownCount + totalAssumedCount
    }
}

public extension Visit {
    func twinAreaSummary(for area: TwinArea) -> TwinAreaSummary {
        let areaCaptureItems = captureItems.filter { $0.twinArea == area }
        let areaCaptureItemIds = Set(areaCaptureItems.map(\.id))
        let areaEvidenceRecords = evidenceRecords
            .filter { record in
                guard let captureItemId = record.captureItemId else { return false }
                return areaCaptureItemIds.contains(captureItemId)
            }
            .sorted { $0.createdAt > $1.createdAt }

        return TwinAreaSummary(
            area: area,
            captureItems: areaCaptureItems,
            evidenceRecords: areaEvidenceRecords
        )
    }

    var visitLevelEvidenceRecords: [EvidenceRecord] {
        evidenceRecords
            .filter { $0.captureItemId == nil }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var progressSummary: VisitProgressSummary {
        VisitProgressSummary(
            system: twinAreaSummary(for: .system),
            house: twinAreaSummary(for: .house),
            home: twinAreaSummary(for: .home),
            visitNoteCount: visitLevelEvidenceRecords.count
        )
    }
}
