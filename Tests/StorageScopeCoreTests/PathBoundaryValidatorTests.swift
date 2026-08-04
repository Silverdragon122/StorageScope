import Darwin
import Foundation
import XCTest
@testable import StorageScopeCore

final class PathBoundaryValidatorTests: XCTestCase {
    func testApplicationSupportFolderContainingNamedPipeCanBeValidated() throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appSupportURL = homeURL
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        let appFolderURL = appSupportURL
            .appendingPathComponent("Example App", isDirectory: true)
        let namedPipeURL = appFolderURL.appendingPathComponent("service.pipe")
        defer { try? fileManager.removeItem(at: homeURL) }

        try fileManager.createDirectory(
            at: appFolderURL,
            withIntermediateDirectories: true
        )
        XCTAssertEqual(mkfifo(namedPipeURL.path, 0o600), 0)

        let rule = CleanupRule(
            id: "application-support-test",
            category: .largeAppData,
            locationName: "App data",
            itemTitle: "App data",
            itemDetail: "App support data.",
            consequence: "The selected app data will be removed.",
            safety: .reviewRequired,
            location: .home(relativePath: "Library/Application Support"),
            source: .children,
            nameStyle: .child,
            cleanupAction: .deleteItem,
            blockedBundleIdentifiers: []
        )
        let item = StorageItem(
            id: "application-support-test|\(appFolderURL.path)",
            ruleID: rule.id,
            category: rule.category,
            title: "Example App",
            detail: rule.itemDetail,
            consequence: rule.consequence,
            url: appFolderURL,
            allocatedBytes: 1,
            fileCount: 1,
            safety: rule.safety,
            cleanupAction: .deleteItem,
            identity: try FileIdentity(url: appFolderURL),
            blockedBundleIdentifiers: []
        )

        let cleanup = try PathBoundaryValidator(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: homeURL,
            fileManager: fileManager
        ).validate(item: item, activeBundleIdentifiers: [])

        XCTAssertEqual(cleanup.targets.map(\.url), [appFolderURL])
        XCTAssertEqual(try FileIdentity(url: namedPipeURL).kind, .namedPipe)
    }

    func testApplicationSupportFolderContainingNamedPipeIsDeleted() async throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appFolderURL = homeURL
            .appendingPathComponent(
                "Library/Application Support/Example App",
                isDirectory: true
            )
        let namedPipeURL = appFolderURL.appendingPathComponent("service.pipe")
        defer { try? fileManager.removeItem(at: homeURL) }

        try fileManager.createDirectory(
            at: appFolderURL,
            withIntermediateDirectories: true
        )
        XCTAssertEqual(mkfifo(namedPipeURL.path, 0o600), 0)

        let rule = CleanupRule(
            id: "application-support-test",
            category: .largeAppData,
            locationName: "App data",
            itemTitle: "App data",
            itemDetail: "App support data.",
            consequence: "The selected app data will be removed.",
            safety: .reviewRequired,
            location: .home(relativePath: "Library/Application Support"),
            source: .children,
            nameStyle: .child,
            cleanupAction: .deleteItem,
            blockedBundleIdentifiers: []
        )
        let item = StorageItem(
            id: "application-support-test|\(appFolderURL.path)",
            ruleID: rule.id,
            category: rule.category,
            title: "Example App",
            detail: rule.itemDetail,
            consequence: rule.consequence,
            url: appFolderURL,
            allocatedBytes: 1,
            fileCount: 1,
            safety: rule.safety,
            cleanupAction: .deleteItem,
            identity: try FileIdentity(url: appFolderURL),
            blockedBundleIdentifiers: []
        )
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: homeURL
        )

        let report = await cleaner.cleanup(
            request: CleanupRequest(
                items: [item],
                activeBundleIdentifiers: []
            ),
            progress: { _ in }
        )

        XCTAssertEqual(report.results.first?.outcome, .deleted(bytes: 1))
        XCTAssertFalse(fileManager.fileExists(atPath: appFolderURL.path))
    }

    func testApprovedAbsoluteTargetUsesAdministratorFileOperator() async throws {
        let fileManager = FileManager.default
        let fixtureRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let homeURL = fixtureRoot.appendingPathComponent("Home", isDirectory: true)
        let systemRootURL = fixtureRoot
            .appendingPathComponent("System Application Support", isDirectory: true)
        let targetURL = systemRootURL
            .appendingPathComponent("Example Support", isDirectory: true)
        defer { try? fileManager.removeItem(at: fixtureRoot) }

        try fileManager.createDirectory(
            at: targetURL,
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: targetURL.appendingPathComponent("data"))

        let rule = absoluteTestRule(rootURL: systemRootURL)
        let item = try absoluteTestItem(rule: rule, targetURL: targetURL)
        let administrator = TestAdministratorFileOperator(behavior: .perform)
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: homeURL,
            administratorFileOperator: administrator,
            approvedAbsoluteCleanupRootPaths: [systemRootURL.path]
        )

        let report = await cleaner.cleanup(
            request: CleanupRequest(items: [item], activeBundleIdentifiers: []),
            progress: { _ in }
        )
        let callCounts = await administrator.callCounts()

        XCTAssertEqual(report.results.first?.outcome, .deleted(bytes: 1))
        XCTAssertEqual(callCounts.move, 1)
        XCTAssertEqual(callCounts.remove, 1)
        XCTAssertFalse(fileManager.fileExists(atPath: targetURL.path))
    }

    func testCanceledAdministratorApprovalLeavesAbsoluteTargetUntouched() async throws {
        let fileManager = FileManager.default
        let fixtureRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let homeURL = fixtureRoot.appendingPathComponent("Home", isDirectory: true)
        let systemRootURL = fixtureRoot
            .appendingPathComponent("System Application Support", isDirectory: true)
        let targetURL = systemRootURL
            .appendingPathComponent("Example Support", isDirectory: true)
        defer { try? fileManager.removeItem(at: fixtureRoot) }

        try fileManager.createDirectory(
            at: targetURL,
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: targetURL.appendingPathComponent("data"))

        let rule = absoluteTestRule(rootURL: systemRootURL)
        let item = try absoluteTestItem(rule: rule, targetURL: targetURL)
        let administrator = TestAdministratorFileOperator(behavior: .cancel)
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            homeURL: homeURL,
            administratorFileOperator: administrator,
            approvedAbsoluteCleanupRootPaths: [systemRootURL.path]
        )

        let report = await cleaner.cleanup(
            request: CleanupRequest(items: [item], activeBundleIdentifiers: []),
            progress: { _ in }
        )
        let callCounts = await administrator.callCounts()

        XCTAssertEqual(
            report.results.first?.outcome,
            .failed(.administratorAuthorizationCanceled)
        )
        XCTAssertEqual(callCounts.move, 1)
        XCTAssertEqual(callCounts.remove, 0)
        XCTAssertTrue(fileManager.fileExists(atPath: targetURL.path))
    }

    func testProtectedSystemTargetNeverRequestsAdministratorApproval() async {
        let protectedURL = URL(
            fileURLWithPath: "/System/Volumes/Preboot",
            isDirectory: true
        )
        let rule = CleanupRule(
            id: "protected-system-test",
            category: .systemManaged,
            locationName: "Protected system data",
            itemTitle: "Protected system data",
            itemDetail: "Protected by macOS.",
            consequence: "This item cannot be removed here.",
            safety: .protected,
            location: .absolute(path: protectedURL.path),
            source: .location,
            nameStyle: .fixed,
            cleanupAction: .none,
            blockedBundleIdentifiers: []
        )
        let item = StorageItem(
            id: "protected-system-test|\(protectedURL.path)",
            ruleID: rule.id,
            category: rule.category,
            title: rule.itemTitle,
            detail: rule.itemDetail,
            consequence: rule.consequence,
            url: protectedURL,
            allocatedBytes: 1,
            fileCount: 1,
            safety: .protected,
            cleanupAction: .none,
            identity: FileIdentity(
                device: 0,
                inode: 0,
                owner: 0,
                kind: .directory,
                modificationSeconds: 0,
                modificationNanoseconds: 0
            ),
            blockedBundleIdentifiers: []
        )
        let administrator = TestAdministratorFileOperator(behavior: .perform)
        let cleaner = SafeCleanupService(
            catalog: CleanupCatalog(rules: [rule]),
            administratorFileOperator: administrator
        )

        let report = await cleaner.cleanup(
            request: CleanupRequest(items: [item], activeBundleIdentifiers: []),
            progress: { _ in }
        )
        let callCounts = await administrator.callCounts()

        XCTAssertEqual(
            report.results.first?.outcome,
            .failed(.protectedItem)
        )
        XCTAssertEqual(callCounts.move, 0)
        XCTAssertEqual(callCounts.remove, 0)
    }

    private func absoluteTestRule(rootURL: URL) -> CleanupRule {
        CleanupRule(
            id: "system-application-support-test",
            category: .systemManaged,
            locationName: "System app support",
            itemTitle: "System app support",
            itemDetail: "System-wide app support data.",
            consequence: "The selected support data will be removed.",
            safety: .reviewRequired,
            location: .absolute(path: rootURL.path),
            source: .children,
            nameStyle: .child,
            cleanupAction: .deleteItem,
            blockedBundleIdentifiers: []
        )
    }

    private func absoluteTestItem(
        rule: CleanupRule,
        targetURL: URL
    ) throws -> StorageItem {
        StorageItem(
            id: "\(rule.id)|\(targetURL.path)",
            ruleID: rule.id,
            category: rule.category,
            title: targetURL.lastPathComponent,
            detail: rule.itemDetail,
            consequence: rule.consequence,
            url: targetURL,
            allocatedBytes: 1,
            fileCount: 1,
            safety: rule.safety,
            cleanupAction: .deleteItem,
            identity: try FileIdentity(url: targetURL),
            blockedBundleIdentifiers: []
        )
    }
}

private actor TestAdministratorFileOperator: AdministratorFileOperating {
    enum Behavior: Sendable {
        case perform
        case cancel
    }

    private let behavior: Behavior
    private var moveCallCount = 0
    private var removeCallCount = 0

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func moveItem(
        at sourceURL: URL,
        to destinationURL: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        moveCallCount += 1
        guard behavior == .perform else { return .canceled }

        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            return .succeeded
        } catch {
            return .failed
        }
    }

    func removeItem(
        at url: URL,
        prompt: String
    ) async -> AdministratorFileOperationResult {
        removeCallCount += 1
        guard behavior == .perform else { return .canceled }

        do {
            try FileManager.default.removeItem(at: url)
            return .succeeded
        } catch {
            return .failed
        }
    }

    func callCounts() -> (move: Int, remove: Int) {
        (moveCallCount, removeCallCount)
    }
}
