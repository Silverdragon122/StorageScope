import AuthorizationShim
import Foundation
import XCTest
@testable import StorageScopeCore

final class AuthorizationBoundarySecurityTests: XCTestCase {
    func testCPolicyAllowsOnlyExpectedSystemAndRecoveryPairs() {
        let recoveryRoot = "/Users/example/Library/Application Support/StorageScope/Interrupted Cleanups"
        let operationID = UUID().uuidString
        let stagedPath = "\(recoveryRoot)/\(operationID)/0"

        XCTAssertTrue(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/Caches/com.example.cache",
                destination: stagedPath
            )
        )
        XCTAssertTrue(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: stagedPath,
                destination: "/Library/Logs/com.example.log"
            )
        )
        XCTAssertTrue(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/Application Support/Adobe",
                destination: stagedPath
            )
        )
        XCTAssertTrue(removalIsAllowed(recoveryRoot: recoveryRoot, path: stagedPath))
    }

    func testCPolicyRejectsBroadSystemPathsTraversalAndNestedStagingPaths() {
        let recoveryRoot = "/Users/example/Library/Application Support/StorageScope/Interrupted Cleanups"
        let operationID = UUID().uuidString
        let stagedPath = "\(recoveryRoot)/\(operationID)/0"

        XCTAssertFalse(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/Caches",
                destination: stagedPath
            )
        )
        XCTAssertFalse(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/LaunchDaemons/com.example.plist",
                destination: stagedPath
            )
        )
        XCTAssertFalse(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/Caches/parent/child",
                destination: stagedPath
            )
        )
        XCTAssertFalse(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/Application Support/Adobe/child",
                destination: stagedPath
            )
        )
        XCTAssertFalse(
            moveIsAllowed(
                recoveryRoot: recoveryRoot,
                source: "/Library/Caches/com.example.cache",
                destination: "\(recoveryRoot)/\(operationID)/../../payload"
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot,
                path: "\(recoveryRoot)/\(operationID)/0/nested"
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot,
                path: "\(recoveryRoot)/not-a-uuid/0"
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot,
                path: "\(recoveryRoot)/01234567-89ab-cdef-8123-456789abcdef/0"
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot,
                path: "\(recoveryRoot)/\(operationID)/01"
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot,
                path: "\(recoveryRoot)/\(operationID)/100000"
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot + "-other",
                path: stagedPath
            )
        )
        XCTAssertFalse(
            removalIsAllowed(
                recoveryRoot: recoveryRoot,
                path: "/Library/Caches/com.example.cache"
            )
        )
    }

    func testSessionRejectsAnArbitraryRecoveryRoot() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        try journal.prepareRecoveryRoot()

        let session = journal.recoveryRootURL.path.withCString {
            NSDAuthorizationSessionCreate($0)
        }
        defer {
            if let session {
                NSDAuthorizationSessionDestroy(session)
            }
        }

        XCTAssertNil(session)
    }

    func testJournalRejectsTraversalStagedName() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        let operationURL = try journal.createOperation(id: UUID())
        let entry = StagedEntry(
            ruleID: "test-rule",
            originalPath: fixture.homeURL.appendingPathComponent("target").path,
            stagedName: "../../payload",
            expectedIdentity: placeholderIdentity,
            allocatedBytes: 1,
            requiresAdministratorPrivileges: false,
            state: .staged
        )

        XCTAssertThrowsError(
            try journal.stagedURL(for: entry, operationURL: operationURL)
        )
    }

    func testJournalRejectsMismatchedOperationIdentifier() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        let operationURL = try journal.createOperation(id: UUID())
        let manifest = CleanupManifest(operationID: UUID(), entries: [])

        XCTAssertThrowsError(try journal.save(manifest, at: operationURL))
    }

    func testJournalRejectsNoncanonicalOperationIdentifier() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        try journal.prepareRecoveryRoot()
        let operationURL = journal.recoveryRootURL.appendingPathComponent(
            "01234567-89ab-cdef-8123-456789abcdef",
            isDirectory: true
        )
        try fixture.fileManager.createDirectory(
            at: operationURL,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )

        XCTAssertThrowsError(try journal.load(from: operationURL))
    }

    func testJournalRejectsSymlinkedOperationDirectory() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        try journal.prepareRecoveryRoot()
        let externalURL = fixture.rootURL.appendingPathComponent(
            "External Operation",
            isDirectory: true
        )
        try fixture.fileManager.createDirectory(
            at: externalURL,
            withIntermediateDirectories: true
        )
        let operationURL = journal.recoveryRootURL.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try fixture.fileManager.createSymbolicLink(
            at: operationURL,
            withDestinationURL: externalURL
        )

        XCTAssertThrowsError(try journal.load(from: operationURL))
    }

    func testJournalRejectsSymlinkedRecoveryRoot() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let externalURL = fixture.rootURL.appendingPathComponent(
            "External Recovery",
            isDirectory: true
        )
        try fixture.fileManager.createDirectory(
            at: externalURL,
            withIntermediateDirectories: true
        )
        try fixture.fileManager.createSymbolicLink(
            at: fixture.recoveryRootURL,
            withDestinationURL: externalURL
        )
        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )

        XCTAssertThrowsError(try journal.prepareRecoveryRoot())
    }

    func testJournalRejectsSymlinkedManifestFile() throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        let operationURL = try journal.createOperation(id: UUID())
        let externalManifestURL = fixture.rootURL.appendingPathComponent(
            "external-manifest.json",
            isDirectory: false
        )
        try Data("{}".utf8).write(to: externalManifestURL)
        try fixture.fileManager.createSymbolicLink(
            at: operationURL.appendingPathComponent("manifest.json"),
            withDestinationURL: externalManifestURL
        )

        XCTAssertThrowsError(try journal.load(from: operationURL))
    }

    func testPersistedPrivilegedEntryIsPreservedWithoutAdministratorCall() async throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let systemRootURL = fixture.rootURL.appendingPathComponent(
            "System Caches",
            isDirectory: true
        )
        let originalURL = systemRootURL.appendingPathComponent("Example", isDirectory: false)
        try fixture.fileManager.createDirectory(
            at: systemRootURL,
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: originalURL)

        let rule = cleanupRule(
            id: "absolute-recovery-test",
            location: .absolute(path: systemRootURL.path)
        )
        let staged = try stageEntry(
            originalURL: originalURL,
            ruleID: rule.id,
            requiresAdministratorPrivileges: true,
            fixture: fixture
        )
        let administrator = RecordingAdministratorFileOperator()
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: fixture.homeURL,
            recoveryRootURL: fixture.recoveryRootURL,
            administratorFileOperator: administrator,
            approvedAbsoluteCleanupRootPaths: [systemRootURL.path]
        )

        let report = await cleaner.recoverInterruptedCleanups()
        let administratorCallCount = await administrator.callCount()
        let invalidationCount = await administrator.invalidationCount()

        XCTAssertEqual(report.restoredItemCount, 0)
        XCTAssertEqual(report.preservedItemCount, 1)
        XCTAssertFalse(fixture.fileManager.fileExists(atPath: originalURL.path))
        XCTAssertTrue(fixture.fileManager.fileExists(atPath: staged.stagedURL.path))
        XCTAssertEqual(administratorCallCount, 0)
        XCTAssertEqual(invalidationCount, 1)
    }

    func testValidatedNonPrivilegedEntryIsRestored() async throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let cacheRootURL = fixture.homeURL.appendingPathComponent(
            "Library/Caches",
            isDirectory: true
        )
        let originalURL = cacheRootURL.appendingPathComponent("Example", isDirectory: false)
        try fixture.fileManager.createDirectory(
            at: cacheRootURL,
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: originalURL)

        let rule = cleanupRule(
            id: "home-recovery-test",
            location: .home(relativePath: "Library/Caches")
        )
        let staged = try stageEntry(
            originalURL: originalURL,
            ruleID: rule.id,
            requiresAdministratorPrivileges: false,
            fixture: fixture
        )
        XCTAssertEqual(try FileIdentity(url: staged.stagedURL), staged.entry.expectedIdentity)
        XCTAssertNoThrow(
            try PathBoundaryValidator(
                catalog: CleanupCatalog(rules: [rule]),
                homeURL: fixture.homeURL,
                fileManager: fixture.fileManager
            ).validateRecoveryDestination(for: staged.entry)
        )
        let recoveryJournal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        XCTAssertEqual(
            staged.operationURL.deletingLastPathComponent().path,
            recoveryJournal.recoveryRootURL.path
        )
        let loadedManifest = try recoveryJournal.load(from: staged.operationURL)
        XCTAssertEqual(loadedManifest.entries.count, 1)
        let enumeratedOperationURL = try XCTUnwrap(recoveryJournal.operationURLs().first)
        XCTAssertEqual(enumeratedOperationURL.path, staged.operationURL.path)
        XCTAssertNoThrow(try recoveryJournal.load(from: enumeratedOperationURL))
        let administrator = RecordingAdministratorFileOperator()
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: fixture.homeURL,
            recoveryRootURL: fixture.recoveryRootURL,
            administratorFileOperator: administrator
        )

        let report = await cleaner.recoverInterruptedCleanups()
        let administratorCallCount = await administrator.callCount()
        let invalidationCount = await administrator.invalidationCount()

        XCTAssertEqual(report.restoredItemCount, 1)
        XCTAssertEqual(report.preservedItemCount, 0)
        XCTAssertTrue(fixture.fileManager.fileExists(atPath: originalURL.path))
        XCTAssertEqual(administratorCallCount, 0)
        XCTAssertEqual(invalidationCount, 1)
    }

    func testTamperedRecoveryDestinationIsPreserved() async throws {
        let fixture = try makeFixture()
        defer { try? fixture.fileManager.removeItem(at: fixture.rootURL) }

        let cacheRootURL = fixture.homeURL.appendingPathComponent(
            "Library/Caches",
            isDirectory: true
        )
        let originalURL = cacheRootURL.appendingPathComponent("Example", isDirectory: false)
        try fixture.fileManager.createDirectory(
            at: cacheRootURL,
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: originalURL)

        let rule = cleanupRule(
            id: "tampered-recovery-test",
            location: .home(relativePath: "Library/Caches")
        )
        let tamperedDestination = fixture.rootURL.appendingPathComponent(
            "Outside Home/payload",
            isDirectory: false
        )
        let staged = try stageEntry(
            originalURL: originalURL,
            recordedOriginalPath: tamperedDestination.path,
            ruleID: rule.id,
            requiresAdministratorPrivileges: false,
            fixture: fixture
        )
        let administrator = RecordingAdministratorFileOperator()
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: fixture.homeURL,
            recoveryRootURL: fixture.recoveryRootURL,
            administratorFileOperator: administrator
        )

        let report = await cleaner.recoverInterruptedCleanups()
        let administratorCallCount = await administrator.callCount()
        let invalidationCount = await administrator.invalidationCount()

        XCTAssertEqual(report.restoredItemCount, 0)
        XCTAssertEqual(report.preservedItemCount, 1)
        XCTAssertFalse(fixture.fileManager.fileExists(atPath: tamperedDestination.path))
        XCTAssertTrue(fixture.fileManager.fileExists(atPath: staged.stagedURL.path))
        XCTAssertEqual(administratorCallCount, 0)
        XCTAssertEqual(invalidationCount, 1)
    }

    private var placeholderIdentity: FileIdentity {
        FileIdentity(
            device: 1,
            inode: 1,
            owner: 1,
            kind: .regularFile,
            modificationSeconds: 0,
            modificationNanoseconds: 0
        )
    }

    private func moveIsAllowed(
        recoveryRoot: String,
        source: String,
        destination: String
    ) -> Bool {
        recoveryRoot.withCString { recoveryRootPath in
            source.withCString { sourcePath in
                destination.withCString { destinationPath in
                    NSDAuthorizationMovePathsAreAllowed(
                        recoveryRootPath,
                        sourcePath,
                        destinationPath
                    ) == 1
                }
            }
        }
    }

    private func removalIsAllowed(recoveryRoot: String, path: String) -> Bool {
        recoveryRoot.withCString { recoveryRootPath in
            path.withCString { itemPath in
                NSDAuthorizationRemovalPathIsAllowed(
                    recoveryRootPath,
                    itemPath
                ) == 1
            }
        }
    }

    private func cleanupRule(id: String, location: CatalogLocation) -> CleanupRule {
        CleanupRule(
            id: id,
            category: .systemManaged,
            locationName: "Test data",
            itemTitle: "Test data",
            itemDetail: "Test data.",
            consequence: "The selected test data will be removed.",
            safety: .reviewRequired,
            location: location,
            source: .children,
            nameStyle: .child,
            cleanupAction: .deleteItem,
            blockedBundleIdentifiers: []
        )
    }

    private func stageEntry(
        originalURL: URL,
        recordedOriginalPath: String? = nil,
        ruleID: String,
        requiresAdministratorPrivileges: Bool,
        fixture: Fixture
    ) throws -> (stagedURL: URL, operationURL: URL, entry: StagedEntry) {
        let identity = try FileIdentity(url: originalURL)
        let journal = CleanupJournal(
            recoveryRootURL: fixture.recoveryRootURL,
            fileManager: fixture.fileManager
        )
        let operationID = UUID()
        let operationURL = try journal.createOperation(id: operationID)
        let entry = StagedEntry(
            ruleID: ruleID,
            originalPath: recordedOriginalPath ?? originalURL.path,
            stagedName: "0",
            expectedIdentity: identity,
            allocatedBytes: 1,
            requiresAdministratorPrivileges: requiresAdministratorPrivileges,
            state: .staged
        )
        let stagedURL = try journal.stagedURL(
            for: entry,
            operationURL: operationURL
        )
        try fixture.fileManager.moveItem(at: originalURL, to: stagedURL)
        try journal.save(
            CleanupManifest(operationID: operationID, entries: [entry]),
            at: operationURL
        )
        return (stagedURL, operationURL, entry)
    }

    private func makeFixture() throws -> Fixture {
        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let homeURL = rootURL.appendingPathComponent("Home", isDirectory: true)
        let recoveryRootURL = rootURL.appendingPathComponent(
            "Recovery",
            isDirectory: true
        )
        try fileManager.createDirectory(at: homeURL, withIntermediateDirectories: true)
        return Fixture(
            fileManager: fileManager,
            rootURL: rootURL,
            homeURL: homeURL,
            recoveryRootURL: recoveryRootURL
        )
    }
}

private struct Fixture {
    let fileManager: FileManager
    let rootURL: URL
    let homeURL: URL
    let recoveryRootURL: URL
}

private actor RecordingAdministratorFileOperator: AdministratorFileOperating {
    private var calls = 0
    private var invalidations = 0

    func moveItem(
        at sourceURL: URL,
        to destinationURL: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        calls += 1
        return .failed
    }

    func removeItem(
        at url: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        calls += 1
        return .failed
    }

    func invalidateAuthorization() async {
        invalidations += 1
    }

    func callCount() -> Int {
        calls
    }

    func invalidationCount() -> Int {
        invalidations
    }
}
