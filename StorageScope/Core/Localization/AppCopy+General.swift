import Foundation

extension AppCopy {
    enum Common {
        static var cancel: String { LocalizedCopy.text("common.cancel") }
        static var done: String { LocalizedCopy.text("common.done") }
    }

    enum Count {
        static func items(_ count: Int) -> String {
            LocalizedCopy.format("count.items \(count)")
        }

        static func files(_ count: Int) -> String {
            LocalizedCopy.format("count.files \(count)")
        }
    }

    enum Category {
        static var developer: String { LocalizedCopy.text("category.developer") }
        static var creative: String { LocalizedCopy.text("category.creative") }
        static var appCaches: String { LocalizedCopy.text("category.app-caches") }
        static var browsers: String { LocalizedCopy.text("category.browsers") }
        static var backups: String { LocalizedCopy.text("category.backups") }
        static var logsAndTemporary: String {
            LocalizedCopy.text("category.logs-and-temporary")
        }
        static var localModels: String {
            LocalizedCopy.text("category.downloaded-models")
        }
        static var largeAppData: String {
            LocalizedCopy.text("category.app-and-personal-data")
        }
        static var systemManaged: String {
            LocalizedCopy.text("category.managed-by-macos")
        }
    }

    enum Safety {
        static var readyToRemove: String {
            LocalizedCopy.text("safety.ready-to-remove")
        }
        static var reviewCarefully: String {
            LocalizedCopy.text("safety.review-carefully")
        }
        static var managedElsewhere: String {
            LocalizedCopy.text("safety.managed-elsewhere")
        }
        static var reclaimableSubtitle: String {
            LocalizedCopy.text("safety.reclaimable-subtitle")
        }
        static var reviewSubtitle: String {
            LocalizedCopy.text("safety.review-subtitle")
        }
        static var protectedSubtitle: String {
            LocalizedCopy.text("safety.protected-subtitle")
        }
    }

    enum Sort {
        static var largestFirst: String {
            LocalizedCopy.text("sort.largest-first")
        }
        static var smallestFirst: String {
            LocalizedCopy.text("sort.smallest-first")
        }
        static var name: String { LocalizedCopy.text("sort.name") }
    }

    enum Sidebar {
        static var allStorage: String { LocalizedCopy.text("sidebar.all-storage") }
        static var sources: String { LocalizedCopy.text("sidebar.sources") }
    }

    enum Row {
        static func select(_ title: String) -> String {
            LocalizedCopy.format("row.select \(title)")
        }
        static func deselect(_ title: String) -> String {
            LocalizedCopy.format("row.deselect \(title)")
        }
        static func accessibilityValue(size: String, safety: String) -> String {
            LocalizedCopy.format("row.accessibility-value \(size) \(safety)")
        }
        static var showDetailsHint: String {
            LocalizedCopy.text("row.show-details-hint")
        }
        static var selectAction: String { LocalizedCopy.text("row.select-action") }
        static var deselectAction: String {
            LocalizedCopy.text("row.deselect-action")
        }
        static var showDetailsAction: String {
            LocalizedCopy.text("row.show-details-action")
        }
    }

    enum Details {
        static var inspector: String { LocalizedCopy.text("details.inspector") }
        static var close: String { LocalizedCopy.text("details.close") }
        static var whatItIs: String { LocalizedCopy.text("details.what-it-is") }
        static var whyItStays: String { LocalizedCopy.text("details.why-it-stays") }
        static var afterCleanup: String { LocalizedCopy.text("details.after-cleanup") }
        static var details: String { LocalizedCopy.text("details.details") }
        static var category: String { LocalizedCopy.text("details.category") }
        static var contents: String { LocalizedCopy.text("details.contents") }
        static var cleanup: String { LocalizedCopy.text("details.cleanup") }
        static var available: String { LocalizedCopy.text("details.available") }
        static var unavailable: String { LocalizedCopy.text("details.unavailable") }
        static var location: String { LocalizedCopy.text("details.location") }
        static var showInFinder: String {
            LocalizedCopy.text("details.show-in-finder")
        }
    }

    enum Settings {
        static var scanOnLaunch: String {
            LocalizedCopy.text("settings.scan-on-launch")
        }
        static var refreshAfterCleanup: String {
            LocalizedCopy.text("settings.refresh-after-cleanup")
        }
        static var scanning: String { LocalizedCopy.text("settings.scanning") }
        static var showManagedStorage: String {
            LocalizedCopy.text("settings.show-managed-storage")
        }
        static var showFileCounts: String {
            LocalizedCopy.text("settings.show-file-counts")
        }
        static var sortItems: String { LocalizedCopy.text("settings.sort-items") }
        static var results: String { LocalizedCopy.text("settings.results") }
        static var forceQuitBlockingApps: String {
            LocalizedCopy.text("settings.force-quit-blocking-apps")
        }
        static var forceQuitExplanation: String {
            LocalizedCopy.text("settings.force-quit-explanation")
        }
        static var safety: String { LocalizedCopy.text("settings.safety") }
        static var restoreDefaults: String {
            LocalizedCopy.text("settings.restore-defaults")
        }
    }
}
