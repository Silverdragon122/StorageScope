import Foundation

struct CleanupRequest: Sendable {
    let items: [StorageItem]
    let activeBundleIdentifiers: Set<String>
}

enum CleanupFailureReason: String, Codable, Equatable, Sendable {
    case noLongerExists
    case changedSinceScan
    case outsideAllowedLocation
    case protectedItem
    case applicationIsOpen
    case unsafeFilesystemEntry
    case couldNotStage
    case couldNotDelete
    case administratorAuthorizationCanceled
    case administratorAuthorizationFailed
    case commandUnavailable
    case commandFailed
}

enum CleanupItemOutcome: Equatable, Sendable {
    case deleted(bytes: Int64)
    case partiallyDeleted(bytes: Int64, reason: CleanupFailureReason)
    case failed(CleanupFailureReason)
}

struct CleanupItemResult: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let outcome: CleanupItemOutcome
}

struct CleanupReport: Equatable, Sendable {
    let results: [CleanupItemResult]
    let completedAt: Date

    var deletedBytes: Int64 {
        results.reduce(into: 0) { total, result in
            switch result.outcome {
            case .deleted(let bytes), .partiallyDeleted(let bytes, _):
                total += bytes
            case .failed:
                break
            }
        }
    }

    var deletedCount: Int {
        results.count {
            if case .deleted = $0.outcome {
                return true
            }
            return false
        }
    }

    var failedCount: Int {
        results.count {
            switch $0.outcome {
            case .deleted:
                return false
            case .partiallyDeleted, .failed:
                return true
            }
        }
    }
}

struct RecoveryReport: Equatable, Sendable {
    let restoredItemCount: Int
    let preservedItemCount: Int
    let preservedLocation: URL?
}

struct CleanupProgress: Equatable, Sendable {
    let completedItemCount: Int
    let totalItemCount: Int
    let currentItemTitle: String
}
