import Foundation

extension AppCopy {
    enum Review {
        static var forceQuitRequired: String {
            LocalizedCopy.text("review.force-quit-required")
        }
        static var filesOpen: String { LocalizedCopy.text("review.files-open") }
        static var forceQuitAndContinue: String {
            LocalizedCopy.text("review.force-quit-and-continue")
        }
        static var quitAndContinue: String {
            LocalizedCopy.text("review.quit-and-continue")
        }
        static var title: String { LocalizedCopy.text("review.title") }
        static var acknowledgment: String {
            LocalizedCopy.text("review.acknowledgment")
        }
        static var cleanupInProgress: String {
            LocalizedCopy.text("review.cleanup-in-progress")
        }
        static var deletionPermanent: String {
            LocalizedCopy.text("review.deletion-permanent")
        }
        static var listedItemsOnly: String {
            LocalizedCopy.text("review.listed-items-only")
        }
        static var deleteSelected: String {
            LocalizedCopy.text("review.delete-selected")
        }
        static var waitingForApps: String {
            LocalizedCopy.text("review.waiting-for-apps")
        }
        static var preparingItems: String {
            LocalizedCopy.text("review.preparing-items")
        }
        static func removing(_ itemTitle: String) -> String {
            LocalizedCopy.format("review.removing \(itemTitle)")
        }
        static func forceQuitMessage(
            applicationCount: Int,
            applicationList: String
        ) -> String {
            LocalizedCopy.format(
                "review.force-quit-message \(applicationCount) \(applicationList)"
            )
        }
        static func quitMessage(
            applicationCount: Int,
            applicationList: String
        ) -> String {
            LocalizedCopy.format(
                "review.quit-message \(applicationCount) \(applicationList)"
            )
        }
    }

    enum Completion {
        static var spaceReclaimed: String {
            LocalizedCopy.text("completion.space-reclaimed")
        }
        static var incomplete: String {
            LocalizedCopy.text("completion.incomplete")
        }
        static func removed(_ size: String) -> String {
            LocalizedCopy.format("completion.removed \(size)")
        }
        static func removedNeedsAttention(size: String, count: Int) -> String {
            LocalizedCopy.format("completion.removed-needs-attention \(size) \(count)")
        }
        static func partiallyRemoved(size: String, message: String) -> String {
            LocalizedCopy.format("completion.partially-removed \(size) \(message)")
        }
        static var noLongerExists: String {
            LocalizedCopy.text("completion.no-longer-exists")
        }
        static var changedSinceScan: String {
            LocalizedCopy.text("completion.changed-since-scan")
        }
        static var outsideAllowedLocation: String {
            LocalizedCopy.text("completion.outside-allowed-location")
        }
        static var protectedItem: String {
            LocalizedCopy.text("completion.protected-item")
        }
        static var applicationIsOpen: String {
            LocalizedCopy.text("completion.application-is-open")
        }
        static var unsafeFilesystemEntry: String {
            LocalizedCopy.text("completion.unsafe-filesystem-entry")
        }
        static var couldNotStage: String {
            LocalizedCopy.text("completion.could-not-stage")
        }
        static var couldNotDelete: String {
            LocalizedCopy.text("completion.could-not-delete")
        }
        static var authorizationCanceled: String {
            LocalizedCopy.text("completion.authorization-canceled")
        }
        static var authorizationFailed: String {
            LocalizedCopy.text("completion.authorization-failed")
        }
        static var commandUnavailable: String {
            LocalizedCopy.text("completion.command-unavailable")
        }
        static var commandFailed: String {
            LocalizedCopy.text("completion.command-failed")
        }
    }
}
