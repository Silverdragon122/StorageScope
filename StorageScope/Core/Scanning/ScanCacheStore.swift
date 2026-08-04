import Foundation

struct CachedRuleScan: Codable, Equatable, Sendable {
    let items: [StorageItem]
    let issues: [ScanIssue]
}

struct ScanCacheSnapshot: Codable, Equatable, Sendable {
    static let currentVersion = 1

    let version: Int
    let catalogSignature: String
    let homePath: String
    let eventID: UInt64
    let scannedAt: Date
    let rules: [String: CachedRuleScan]
    let notices: [ScanNotice]

    init(
        catalogSignature: String,
        homePath: String,
        eventID: UInt64,
        scannedAt: Date,
        rules: [String: CachedRuleScan],
        notices: [ScanNotice]
    ) {
        self.version = Self.currentVersion
        self.catalogSignature = catalogSignature
        self.homePath = homePath
        self.eventID = eventID
        self.scannedAt = scannedAt
        self.rules = rules
        self.notices = notices
    }
}

actor ScanCacheStore {
    private let fileManager: FileManager
    private let cacheURL: URL
    private var memorySnapshot: ScanCacheSnapshot?

    init(
        fileManager: FileManager = .default,
        cacheURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.cacheURL = cacheURL ?? Self.defaultCacheURL(fileManager: fileManager)
    }

    func load(
        catalogSignature: String,
        homePath: String
    ) -> ScanCacheSnapshot? {
        if
            let memorySnapshot,
            memorySnapshot.version == ScanCacheSnapshot.currentVersion,
            memorySnapshot.catalogSignature == catalogSignature,
            memorySnapshot.homePath == homePath
        {
            return memorySnapshot
        }

        guard
            let data = try? Data(
                contentsOf: cacheURL,
                options: [.mappedIfSafe]
            ),
            let snapshot = try? JSONDecoder().decode(ScanCacheSnapshot.self, from: data),
            snapshot.version == ScanCacheSnapshot.currentVersion,
            snapshot.catalogSignature == catalogSignature,
            snapshot.homePath == homePath
        else {
            return nil
        }

        memorySnapshot = snapshot
        return snapshot
    }

    func save(_ snapshot: ScanCacheSnapshot) {
        memorySnapshot = snapshot
        do {
            let directoryURL = cacheURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            // A cache failure must never prevent a scan from completing.
        }
    }

    private static func defaultCacheURL(fileManager: FileManager) -> URL {
        let cachesURL = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return cachesURL
            .appendingPathComponent("StorageScope", isDirectory: true)
            .appendingPathComponent("scan-cache-v1.json", isDirectory: false)
    }
}
