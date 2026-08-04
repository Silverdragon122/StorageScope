import Foundation

struct StorageItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let ruleID: String
    let category: StorageCategory
    let title: String
    let detail: String
    let consequence: String
    let url: URL
    let allocatedBytes: Int64
    let fileCount: Int
    let safety: CleanupSafety
    let cleanupAction: CleanupAction
    let identity: FileIdentity
    let blockedBundleIdentifiers: Set<String>

    var isSelectable: Bool {
        safety.allowsCleanup && cleanupAction != .none && allocatedBytes > 0
    }
}
