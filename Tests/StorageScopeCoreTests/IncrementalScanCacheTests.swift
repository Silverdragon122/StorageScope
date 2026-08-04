import Foundation
import XCTest
@testable import StorageScopeCore

final class IncrementalScanCacheTests: XCTestCase {
    func testUnchangedRuleReusesPersistentMeasurement() async throws {
        let fixture = try ScanFixture()
        defer { fixture.remove() }

        let firstScanner = fixture.scanner(
            eventID: 100,
            changes: FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: false
            )
        )
        let firstReport = await firstScanner.scan(progress: { _ in })
        XCTAssertEqual(firstReport.source, .full)
        XCTAssertGreaterThan(firstReport.totalBytes, 0)

        let secondScanner = fixture.scanner(
            eventID: 101,
            changes: FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: false
            )
        )
        let secondReport = await secondScanner.scan(progress: { _ in })

        guard case .incremental(let reusedRules, let totalRules) = secondReport.source else {
            return XCTFail("Expected an incremental scan")
        }
        XCTAssertEqual(reusedRules, 1)
        XCTAssertEqual(totalRules, 1)
        XCTAssertEqual(secondReport.items, firstReport.items)
    }

    func testChangedPathRemeasuresItsRuleAndUpdatesCache() async throws {
        let fixture = try ScanFixture()
        defer { fixture.remove() }

        let firstScanner = fixture.scanner(
            eventID: 200,
            changes: FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: false
            )
        )
        let firstReport = await firstScanner.scan(progress: { _ in })

        let addedFileURL = fixture.storageURL.appendingPathComponent("new-cache.bin")
        try Data(repeating: 0x7F, count: 64 * 1_024).write(to: addedFileURL)

        let changedScanner = fixture.scanner(
            eventID: 201,
            changes: FileSystemChangeSet(
                changedPaths: [addedFileURL.path],
                requiresFullScan: false
            )
        )
        let changedReport = await changedScanner.scan(progress: { _ in })

        XCTAssertEqual(changedReport.source, .full)
        XCTAssertGreaterThan(changedReport.totalBytes, firstReport.totalBytes)

        let cachedReport = await changedScanner.cachedReport()
        XCTAssertEqual(cachedReport?.source, .cache)
        XCTAssertEqual(cachedReport?.totalBytes, changedReport.totalBytes)
    }

    func testDroppedChangeHistoryFallsBackToFullScan() async throws {
        let fixture = try ScanFixture()
        defer { fixture.remove() }

        let firstScanner = fixture.scanner(
            eventID: 300,
            changes: FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: false
            )
        )
        _ = await firstScanner.scan(progress: { _ in })

        let fallbackScanner = fixture.scanner(
            eventID: 301,
            changes: FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: true
            )
        )
        let fallbackReport = await fallbackScanner.scan(progress: { _ in })

        XCTAssertEqual(fallbackReport.source, .full)
    }
}

private final class ScanFixture: @unchecked Sendable {
    let rootURL: URL
    let storageURL: URL
    let cacheStore: ScanCacheStore

    private let catalog: CleanupCatalog

    init() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        storageURL = rootURL
            .appendingPathComponent("Library/Caches/Demo", isDirectory: true)
        let cacheURL = rootURL.appendingPathComponent("scan-cache.json")

        try FileManager.default.createDirectory(
            at: storageURL,
            withIntermediateDirectories: true
        )
        try Data(repeating: 0x42, count: 64 * 1_024).write(
            to: storageURL.appendingPathComponent("cache.bin")
        )

        cacheStore = ScanCacheStore(cacheURL: cacheURL)
        catalog = CleanupCatalog(
            rules: [
                CleanupRule(
                    id: "demo-cache",
                    category: .appCaches,
                    locationName: "Demo cache",
                    itemTitle: "Demo cache",
                    itemDetail: "Temporary files retained by Demo.",
                    consequence: "Demo will recreate these files when needed.",
                    safety: .reclaimable,
                    location: .home(relativePath: "Library/Caches/Demo"),
                    source: .location,
                    nameStyle: .fixed,
                    cleanupAction: .deleteContents,
                    blockedBundleIdentifiers: []
                )
            ]
        )
    }

    func scanner(
        eventID: UInt64,
        changes: FileSystemChangeSet
    ) -> StorageScanner {
        StorageScanner(
            catalog: catalog,
            homeURL: rootURL,
            systemProbe: EmptySystemProbe(),
            cacheStore: cacheStore,
            changeTracker: FixedChangeTracker(
                eventID: eventID,
                changeSet: changes
            )
        )
    }

    func remove() {
        try? FileManager.default.removeItem(at: rootURL)
    }
}

private struct EmptySystemProbe: SystemStorageProbing {
    func inspect() async -> SystemStorageProbeResult {
        SystemStorageProbeResult(records: [], notices: [])
    }
}

private struct FixedChangeTracker: FileSystemChangeTracking {
    let eventID: UInt64
    let changeSet: FileSystemChangeSet

    func currentEventID() -> UInt64 {
        eventID
    }

    func changes(
        since eventID: UInt64,
        watching paths: [String]
    ) async -> FileSystemChangeSet {
        changeSet
    }
}
