import Foundation

struct ScanProgress: Equatable, Sendable {
    let completedRules: Int
    let totalRules: Int
    let currentLocation: String
    let discoveredBytes: Int64
    let discoveredItemCount: Int
    // These collections contain only changes since the preceding update.
    let indexedItems: [StorageItem]
    let refreshedRuleIDs: Set<String>
    let issues: [ScanIssue]
    let notices: [ScanNotice]
    let fullDiskAccessStatus: FullDiskAccessStatus

    init(
        completedRules: Int,
        totalRules: Int,
        currentLocation: String,
        discoveredBytes: Int64,
        discoveredItemCount: Int,
        indexedItems: [StorageItem] = [],
        refreshedRuleIDs: Set<String> = [],
        issues: [ScanIssue] = [],
        notices: [ScanNotice] = [],
        fullDiskAccessStatus: FullDiskAccessStatus = .unknown
    ) {
        self.completedRules = completedRules
        self.totalRules = totalRules
        self.currentLocation = currentLocation
        self.discoveredBytes = discoveredBytes
        self.discoveredItemCount = discoveredItemCount
        self.indexedItems = indexedItems
        self.refreshedRuleIDs = refreshedRuleIDs
        self.issues = issues
        self.notices = notices
        self.fullDiskAccessStatus = fullDiskAccessStatus
    }

    var fractionCompleted: Double {
        guard totalRules > 0 else { return 0 }
        return min(1, max(0, Double(completedRules) / Double(totalRules)))
    }
}

enum ScanIssueKind: String, Codable, Sendable {
    case permissionDenied
    case unreadable
    case changedDuringScan
}

struct ScanIssue: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let locationName: String
    let kind: ScanIssueKind
}

struct ScanNotice: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
}

enum ScanReportSource: Equatable, Sendable {
    case full
    case incremental(reusedRuleCount: Int, totalRuleCount: Int)
    case cache
    case live
}

struct ScanReport: Equatable, Sendable {
    let items: [StorageItem]
    let issues: [ScanIssue]
    let notices: [ScanNotice]
    let fullDiskAccessStatus: FullDiskAccessStatus
    let scannedAt: Date
    let duration: Duration
    let source: ScanReportSource

    init(
        items: [StorageItem],
        issues: [ScanIssue],
        notices: [ScanNotice],
        fullDiskAccessStatus: FullDiskAccessStatus = .unknown,
        scannedAt: Date,
        duration: Duration,
        source: ScanReportSource = .full
    ) {
        self.items = items
        self.issues = issues
        self.notices = notices
        self.fullDiskAccessStatus = fullDiskAccessStatus
        self.scannedAt = scannedAt
        self.duration = duration
        self.source = source
    }

    var totalBytes: Int64 {
        items.reduce(into: 0) { $0 += $1.allocatedBytes }
    }

    var selectableBytes: Int64 {
        items.reduce(into: 0) { total, item in
            if item.isSelectable {
                total += item.allocatedBytes
            }
        }
    }
}
