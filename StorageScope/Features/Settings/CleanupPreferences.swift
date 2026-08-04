import Foundation

enum CleanupItemSortOrder: String, CaseIterable, Identifiable {
    case largestFirst
    case smallestFirst
    case name

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .largestFirst:
            AppCopy.Sort.largestFirst
        case .smallestFirst:
            AppCopy.Sort.smallestFirst
        case .name:
            AppCopy.Sort.name
        }
    }
}

enum CleanupPreferences {
    static let forceCloseModeKey = "cleanup.forceCloseBlockingApplications"
    static let scanOnLaunchKey = "scan.automaticallyOnLaunch"
    static let refreshAfterCleanupKey = "scan.refreshAfterCleanup"
    static let showProtectedItemsKey = "results.showProtectedItems"
    static let showFileCountsKey = "results.showFileCounts"
    static let itemSortOrderKey = "results.itemSortOrder"

    @MainActor
    static var forceCloseModeEnabled: Bool {
        UserDefaults.standard.bool(forKey: forceCloseModeKey)
    }

    @MainActor
    static var scanOnLaunchEnabled: Bool {
        bool(forKey: scanOnLaunchKey, defaultValue: true)
    }

    @MainActor
    static var refreshAfterCleanupEnabled: Bool {
        bool(forKey: refreshAfterCleanupKey, defaultValue: true)
    }

    @MainActor
    static var showProtectedItemsEnabled: Bool {
        bool(forKey: showProtectedItemsKey, defaultValue: true)
    }

    @MainActor
    static var showFileCountsEnabled: Bool {
        bool(forKey: showFileCountsKey, defaultValue: true)
    }

    @MainActor
    static var itemSortOrder: CleanupItemSortOrder {
        guard
            let rawValue = UserDefaults.standard.string(
                forKey: itemSortOrderKey
            ),
            let order = CleanupItemSortOrder(rawValue: rawValue)
        else {
            return .largestFirst
        }
        return order
    }

    @MainActor
    private static func bool(
        forKey key: String,
        defaultValue: Bool
    ) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }
}
