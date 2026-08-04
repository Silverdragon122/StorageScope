import Foundation

protocol StorageCleaning: Sendable {
    func cleanup(
        request: CleanupRequest,
        progress: @escaping @Sendable (CleanupProgress) async -> Void
    ) async -> CleanupReport

    func recoverInterruptedCleanups() async -> RecoveryReport
}

