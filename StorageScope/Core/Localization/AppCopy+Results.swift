import Foundation

extension AppCopy {
    enum Results {
        static var searchPrompt: String { LocalizedCopy.text("results.search-prompt") }
        static var sortItems: String { LocalizedCopy.text("results.sort-items") }
        static var sortHelp: String { LocalizedCopy.text("results.sort-help") }
        static var stopScan: String { LocalizedCopy.text("results.stop-scan") }
        static var stopScanHelp: String {
            LocalizedCopy.text("results.stop-scan-help")
        }
        static var checkForChanges: String {
            LocalizedCopy.text("results.check-for-changes")
        }
        static var checkForChangesHelp: String {
            LocalizedCopy.text("results.check-for-changes-help")
        }
        static var emptyReportTitle: String {
            LocalizedCopy.text("results.empty-report-title")
        }
        static var noItemsTitle: String {
            LocalizedCopy.text("results.no-items-title")
        }
        static var noItemsMessage: String {
            LocalizedCopy.text("results.no-items-message")
        }
        static func noMatchTitle(_ query: String) -> String {
            LocalizedCopy.format("results.no-match-title \(query)")
        }
        static var noMatchMessage: String {
            LocalizedCopy.text("results.no-match-message")
        }
        static var chooseWhatToRemove: String {
            LocalizedCopy.text("results.choose-what-to-remove")
        }
        static var selectReadyItems: String {
            LocalizedCopy.text("results.select-ready-items")
        }
        static var clearSelection: String {
            LocalizedCopy.text("results.clear-selection")
        }
        static var reviewCleanup: String {
            LocalizedCopy.text("results.review-cleanup")
        }
        static var noLocationsFound: String {
            LocalizedCopy.text("results.no-locations-found")
        }
        static var fullDiskAccessNeededForScan: String {
            LocalizedCopy.text("results.full-disk-access-needed-for-scan")
        }
        static var locationsChanged: String {
            LocalizedCopy.text("results.locations-changed")
        }
        static var updatingStorageMap: String {
            LocalizedCopy.text("results.updating-storage-map")
        }
        static var ready: String { LocalizedCopy.text("results.ready") }
        static var review: String { LocalizedCopy.text("results.review") }
        static var managed: String { LocalizedCopy.text("results.managed") }
        static var scanProgress: String {
            LocalizedCopy.text("results.scan-progress")
        }
        static var buildingStorageMap: String {
            LocalizedCopy.text("results.building-storage-map")
        }
        static var startingScan: String {
            LocalizedCopy.text("results.starting-scan")
        }
        static func acrossItemsSoFar(_ count: Int) -> String {
            LocalizedCopy.format("results.across-items-so-far \(count)")
        }
        static var stopScanning: String {
            LocalizedCopy.text("results.stop-scanning")
        }
        static var scanTitle: String { LocalizedCopy.text("results.scan-title") }
        static var scanExplanation: String {
            LocalizedCopy.text("results.scan-explanation")
        }
        static var scanSafety: String { LocalizedCopy.text("results.scan-safety") }
        static var scanAction: String { LocalizedCopy.text("results.scan-action") }
        static var accessNoticeTitle: String {
            LocalizedCopy.text("results.access-notice-title")
        }
        static func accessNoticeMessage(_ count: Int) -> String {
            LocalizedCopy.format("results.access-notice-message \(count)")
        }
        static var openSettings: String {
            LocalizedCopy.text("results.open-settings")
        }
        static func skippedTitle(_ count: Int) -> String {
            LocalizedCopy.format("results.skipped-title \(count)")
        }
        static var skippedGrantedMessage: String {
            LocalizedCopy.text("results.skipped-granted-message")
        }
        static var skippedDeniedMessage: String {
            LocalizedCopy.text("results.skipped-denied-message")
        }
        static var skippedUnknownMessage: String {
            LocalizedCopy.text("results.skipped-unknown-message")
        }
        static func recoveryTitle(_ count: Int) -> String {
            LocalizedCopy.format("results.recovery-title \(count)")
        }
        static var preservedItemsMessage: String {
            LocalizedCopy.text("results.preserved-items-message")
        }
        static var rollbackMessage: String {
            LocalizedCopy.text("results.rollback-message")
        }
        static var showPreservedItems: String {
            LocalizedCopy.text("results.show-preserved-items")
        }
        static func selectedEstimated(count: Int, size: String) -> String {
            LocalizedCopy.format("results.selected-estimated \(count) \(size)")
        }
    }
}
