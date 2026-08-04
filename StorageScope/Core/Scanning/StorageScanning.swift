import Foundation

protocol StorageScanning: Sendable {
    func cachedReport() async -> ScanReport?

    func scan(
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async -> ScanReport
}

extension StorageScanning {
    func cachedReport() async -> ScanReport? {
        nil
    }
}
