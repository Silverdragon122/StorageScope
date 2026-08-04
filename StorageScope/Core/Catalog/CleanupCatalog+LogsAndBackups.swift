import Foundation

extension CleanupCatalog {
    static let logAndBackupRules: [CleanupRule] = [
        rule(
            "saved-application-state",
            .logsAndTemporary,
            "Saved window state",
            "Saved window state",
            "Window restoration data kept by apps.",
            "The selected app may reopen with its default windows next time.",
            .reclaimable,
            "Library/Saved Application State",
            .children,
            .appCache,
            .deleteItem
        ),
        rule(
            "diagnostic-reports",
            .logsAndTemporary,
            "Crash reports",
            "Crash report",
            "Reports created when an app or process stops unexpectedly.",
            "The selected reports will no longer be available for troubleshooting.",
            .reclaimable,
            "Library/Logs/DiagnosticReports",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "crash-reporter-data",
            .logsAndTemporary,
            "Crash reporter records",
            "Crash reporter record",
            "Diagnostic records retained by macOS crash reporting.",
            "The selected records will no longer be available for troubleshooting.",
            .reclaimable,
            "Library/Application Support/CrashReporter",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "logs",
            .logsAndTemporary,
            "App logs",
            "App logs",
            "Diagnostic records written by apps.",
            "The selected logs will no longer be available for troubleshooting.",
            .reclaimable,
            "Library/Logs",
            .children,
            .appCache,
            .deleteItem
        ),
        rule(
            "trash",
            .logsAndTemporary,
            "Trash",
            "Item in Trash",
            "Files already moved to the Trash.",
            "The selected item will be permanently deleted and cannot be restored from Trash.",
            .reclaimable,
            ".Trash",
            .children,
            .child,
            .deleteItem
        ),
        deviceUpdateRule(
            id: "ios-update-downloads",
            name: "iPhone update downloads",
            path: "Library/iTunes/iPhone Software Updates"
        ),
        deviceUpdateRule(
            id: "ipados-update-downloads",
            name: "iPad update downloads",
            path: "Library/iTunes/iPad Software Updates"
        ),
        deviceUpdateRule(
            id: "ipod-update-downloads",
            name: "iPod update downloads",
            path: "Library/iTunes/iPod Software Updates"
        ),
        deviceUpdateRule(
            id: "tvos-update-downloads",
            name: "Apple TV update downloads",
            path: "Library/iTunes/Apple TV Software Updates"
        ),
        rule(
            "mobile-device-backups",
            .backups,
            "iPhone and iPad backups",
            "Device backup",
            "A local backup of an iPhone or iPad.",
            "The selected backup cannot be used to restore that device.",
            .reviewRequired,
            "Library/Application Support/MobileSync/Backup",
            .children,
            .childWithSuffix("backup"),
            .deleteItem,
            ["com.apple.MobileDeviceUpdater"]
        ),
        readOnlyRule(
            "autosave-information",
            .backups,
            "Unsaved document recovery",
            "Recovery copies retained by apps for documents that may not have been saved.",
            "Open the owning app and confirm the documents are no longer needed.",
            .home(relativePath: "Library/Autosave Information"),
            .children,
            .child
        ),
        readOnlyRule(
            "relocated-items",
            .largeAppData,
            "Relocated system-upgrade items",
            "Files macOS moved aside during an upgrade because they could not remain in place.",
            "Review these files manually before deciding whether they are still needed.",
            .absolute(path: "/Users/Shared/Relocated Items"),
            .children,
            .child
        ),
        readOnlyRule(
            "deleted-user-data",
            .largeAppData,
            "Deleted user archives",
            "Home folders or disk images retained after a macOS user account was removed.",
            "Confirm the former user's data is backed up before removing it.",
            .absolute(path: "/Users/Deleted Users"),
            .children,
            .child
        ),
        readOnlyRule(
            "shared-user-data",
            .largeAppData,
            "Shared user files",
            "Files available to multiple user accounts on this Mac.",
            "Review ownership and backups before changing shared files.",
            .absolute(path: "/Users/Shared"),
            .children,
            .child
        ),
        readOnlyRule(
            "other-user-homes",
            .largeAppData,
            "Other user accounts",
            "Files owned by other local user accounts.",
            "Sign in as that user or remove the account from System Settings.",
            .absolute(path: "/Users"),
            .otherUserHomes,
            .child
        )
    ]

    private static func deviceUpdateRule(
        id: String,
        name: String,
        path: String
    ) -> CleanupRule {
        rule(
            id,
            .logsAndTemporary,
            name,
            "Device update",
            "Downloaded Apple device firmware and update files.",
            "The update must be downloaded again if it is needed.",
            .reclaimable,
            path,
            .children,
            .child,
            .deleteItem
        )
    }
}
