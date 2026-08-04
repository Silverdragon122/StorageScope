import Foundation

enum CleanupPreviewData {
    @MainActor
    static func model(
        report: ScanReport?,
        progress: ScanProgress? = nil
    ) -> CleanupScreenModel {
        CleanupScreenModel(
            scanner: PreviewScanner(report: report ?? emptyReport),
            cleaner: PreviewCleaner(),
            workspace: PreviewWorkspace(),
            initialReport: report,
            initialProgress: progress,
            automaticallyScans: false,
            checkFullDiskAccess: { .granted }
        )
    }

    @MainActor
    static func cleanupReviewModel() -> CleanupScreenModel {
        let model = model(report: loadedReport)
        model.selectedItemIDs = ["backup"]
        model.showReview()
        return model
    }

    @MainActor
    static func detailsModel() -> CleanupScreenModel {
        let model = model(report: loadedReport)
        if let firstItem = loadedReport.items.first {
            model.inspect(firstItem)
        }
        return model
    }

    static let loadedReport = ScanReport(
        items: [
            item(
                id: "xcode",
                category: .developer,
                title: AppCopy.Preview.text("xcode.title"),
                detail: AppCopy.Preview.text("xcode.detail"),
                consequence: AppCopy.Preview.text("xcode.consequence"),
                path: "/Users/sample/Library/Developer/Xcode/DerivedData/TrailNotes",
                bytes: 38_400_000_000,
                safety: .reclaimable,
                action: .deleteItem
            ),
            item(
                id: "preboot",
                category: .systemManaged,
                title: AppCopy.Preview.text("preboot.title"),
                detail: AppCopy.Preview.text("preboot.detail"),
                consequence: AppCopy.Preview.text("preboot.consequence"),
                path: "/System/Volumes/Preboot",
                bytes: 36_200_000_000,
                safety: .protected,
                action: .none
            ),
            item(
                id: "backup",
                category: .backups,
                title: AppCopy.Preview.text("backup.title"),
                detail: AppCopy.Preview.text("backup.detail"),
                consequence: AppCopy.Preview.text("backup.consequence"),
                path: "/Users/sample/Library/Application Support/MobileSync/Backup/phone",
                bytes: 29_800_000_000,
                safety: .reviewRequired,
                action: .deleteItem
            ),
            item(
                id: "model",
                category: .localModels,
                title: AppCopy.Preview.text("model.title"),
                detail: AppCopy.Preview.text("model.detail"),
                consequence: AppCopy.Preview.text("model.consequence"),
                path: "/Users/sample/.cache/whisper/large",
                bytes: 18_600_000_000,
                safety: .reviewRequired,
                action: .deleteItem
            ),
            item(
                id: "final-cut",
                category: .creative,
                title: AppCopy.Preview.text("final-cut.title"),
                detail: AppCopy.Preview.text("final-cut.detail"),
                consequence: AppCopy.Preview.text("final-cut.consequence"),
                path: "/Users/sample/Movies/Summer Film.fcpbundle/Render Files",
                bytes: 17_200_000_000,
                safety: .reclaimable,
                action: .deleteContents
            ),
            item(
                id: "simulator",
                category: .developer,
                title: AppCopy.Preview.text("simulator.title"),
                detail: AppCopy.Preview.text("simulator.detail"),
                consequence: AppCopy.Preview.text("simulator.consequence"),
                path: "/Users/sample/Library/Developer/CoreSimulator/Devices/00000000-0000-0000-0000-000000000001",
                bytes: 12_400_000_000,
                safety: .reviewRequired,
                action: .simulatorDevice(
                    identifier: "00000000-0000-0000-0000-000000000001"
                )
            ),
            item(
                id: "slack",
                category: .appCaches,
                title: AppCopy.Preview.text("slack.title"),
                detail: AppCopy.Preview.text("slack.detail"),
                consequence: AppCopy.Preview.text("slack.consequence"),
                path: "/Users/sample/Library/Application Support/Slack/Cache",
                bytes: 4_100_000_000,
                safety: .reclaimable,
                action: .deleteContents
            )
        ],
        issues: [],
        notices: [],
        fullDiskAccessStatus: .granted,
        scannedAt: Date(),
        duration: .seconds(8)
    )

    static let limitedReport = ScanReport(
        items: loadedReport.items,
        issues: [
            ScanIssue(
                id: "mail",
                locationName: AppCopy.Preview.text("mail.location"),
                kind: .permissionDenied
            ),
            ScanIssue(
                id: "messages",
                locationName: AppCopy.Preview.text("messages.location"),
                kind: .permissionDenied
            )
        ],
        notices: [
            ScanNotice(
                id: "snapshots",
                title: AppCopy.Core.localSnapshots(2),
                message: AppCopy.Core.localSnapshotsMessage
            )
        ],
        fullDiskAccessStatus: .denied,
        scannedAt: Date(),
        duration: .seconds(8)
    )

    static let emptyReport = ScanReport(
        items: [],
        issues: [],
        notices: [],
        fullDiskAccessStatus: .granted,
        scannedAt: Date(),
        duration: .seconds(1)
    )

    static let scanningProgress = ScanProgress(
        completedRules: 27,
        totalRules: 61,
        currentLocation: AppCopy.Category.creative,
        discoveredBytes: 71_400_000_000,
        discoveredItemCount: 18
    )

    static let completionReport = CleanupReport(
        results: [
            CleanupItemResult(
                id: "xcode",
                title: AppCopy.Preview.text("xcode.title"),
                outcome: .deleted(bytes: 38_400_000_000)
            ),
            CleanupItemResult(
                id: "backup",
                title: AppCopy.Preview.text("backup.title"),
                outcome: .partiallyDeleted(
                    bytes: 18_200_000_000,
                    reason: .applicationIsOpen
                )
            )
        ],
        completedAt: Date()
    )

    private static func item(
        id: String,
        category: StorageCategory,
        title: String,
        detail: String,
        consequence: String,
        path: String,
        bytes: Int64,
        safety: CleanupSafety,
        action: CleanupAction
    ) -> StorageItem {
        StorageItem(
            id: id,
            ruleID: id,
            category: category,
            title: title,
            detail: detail,
            consequence: consequence,
            url: URL(fileURLWithPath: path),
            allocatedBytes: bytes,
            fileCount: 120,
            safety: safety,
            cleanupAction: action,
            identity: FileIdentity(
                device: 1,
                inode: UInt64(bitPattern: Int64(id.hashValue)),
                owner: 501,
                kind: .directory,
                modificationSeconds: 0,
                modificationNanoseconds: 0
            ),
            blockedBundleIdentifiers: []
        )
    }
}

private struct PreviewScanner: StorageScanning {
    let report: ScanReport

    func scan(
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async -> ScanReport {
        report
    }
}

private struct PreviewCleaner: StorageCleaning {
    func cleanup(
        request: CleanupRequest,
        progress: @escaping @Sendable (CleanupProgress) async -> Void
    ) async -> CleanupReport {
        CleanupReport(results: [], completedAt: Date())
    }

    func recoverInterruptedCleanups() async -> RecoveryReport {
        RecoveryReport(
            restoredItemCount: 0,
            preservedItemCount: 0,
            preservedLocation: nil
        )
    }
}

@MainActor
private final class PreviewWorkspace: WorkspaceProviding {
    func activeBundleIdentifiers() -> Set<String> { [] }
    func applications(
        withBundleIdentifiers bundleIdentifiers: Set<String>
    ) -> [CleanupApplication] { [] }
    func requestTermination(
        ofApplicationsWithBundleIdentifiers bundleIdentifiers: Set<String>
    ) {}
    func forceTermination(
        ofApplicationsWithBundleIdentifiers bundleIdentifiers: Set<String>
    ) {}
    func reveal(_ url: URL) {}
    func openPrivacySettings() {}
}
