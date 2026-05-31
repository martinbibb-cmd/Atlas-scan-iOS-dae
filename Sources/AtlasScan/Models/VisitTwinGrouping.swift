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

    public var captureItemGroups: [CaptureItemEvidenceGroup] {
        captureItems.map { item in
            CaptureItemEvidenceGroup(
                captureItem: item,
                evidenceRecords: evidenceRecords.filter { $0.captureItemId == item.id }
            )
        }
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
}
