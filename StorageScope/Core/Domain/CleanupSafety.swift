import Foundation

enum CleanupSafety: String, CaseIterable, Codable, Hashable, Sendable {
    case reclaimable
    case reviewRequired
    case protected

    var allowsCleanup: Bool {
        self != .protected
    }
}

enum CleanupAction: Codable, Hashable, Sendable {
    case deleteItem
    case deleteContents
    case simulatorDevice(identifier: String)
    case none
}
