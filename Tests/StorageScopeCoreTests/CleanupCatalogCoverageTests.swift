import XCTest
@testable import StorageScopeCore

final class CleanupCatalogCoverageTests: XCTestCase {
    func testExpandedCatalogRulesAreRegistered() {
        let catalog = CleanupCatalog.standard
        let expandedRuleIDs = [
            "zoom-app-cache",
            "epic-games-launcher-cache",
            "godot-cache",
            "microsoft-teams-new-cache",
            "dropbox-cache-folders",
            "ableton-pack-downloads",
            "obs-logs",
            "obs-crash-reports",
            "audacity-session-data",
            "krita-resource-data",
            "terraform-plugin-cache",
            "pulumi-plugin-cache",
            "dart-pub-cache",
            "julia-compiled-cache",
            "elixir-native-build-cache",
            "safari-technology-preview-website-data",
            "google-drivefs-data"
        ]

        XCTAssertEqual(Set(expandedRuleIDs).count, expandedRuleIDs.count)
        for id in expandedRuleIDs {
            XCTAssertNotNil(catalog.rule(id: id), "Missing expanded rule: \(id)")
        }
    }

    func testExpandedProtectedDataCannotBeCleaned() {
        let catalog = CleanupCatalog.standard
        let protectedRuleIDs = [
            "audacity-session-data",
            "krita-resource-data",
            "safari-technology-preview-website-data",
            "google-drivefs-data"
        ]

        for id in protectedRuleIDs {
            guard let rule = catalog.rule(id: id) else {
                return XCTFail("Missing protected rule: \(id)")
            }
            XCTAssertEqual(rule.safety, .protected, id)
            XCTAssertEqual(rule.cleanupAction, .none, id)
            XCTAssertTrue(rule.isReadOnly, id)
        }
    }

    func testExpandedAppRulesBlockTheOwningProcessWhereKnown() {
        let catalog = CleanupCatalog.standard
        let expectedBlockedBundleIDs = [
            "zoom-app-cache": "us.zoom.xos",
            "epic-games-launcher-cache": "com.epicgames.EpicGamesLauncher",
            "godot-cache": "org.godotengine.godot",
            "microsoft-teams-new-cache": "com.microsoft.teams2",
            "ableton-pack-downloads": "com.ableton.live",
            "obs-logs": "com.obsproject.obs-studio",
            "obs-crash-reports": "com.obsproject.obs-studio"
        ]

        for (ruleID, bundleID) in expectedBlockedBundleIDs {
            guard let rule = catalog.rule(id: ruleID) else {
                return XCTFail("Missing app rule: \(ruleID)")
            }
            XCTAssertTrue(rule.blockedBundleIdentifiers.contains(bundleID), ruleID)
        }
    }

    func testExpandedRulesDiscoverTheirDocumentedDefaultLocations() throws {
        let fileManager = FileManager.default
        let homeURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: homeURL) }

        let fixturePaths = [
            "Library/Caches/com.epicgames.EpicGamesLauncher/webcache/entry",
            "Dropbox/.dropbox.cache/upload",
            ".terraform.d/plugin-cache/provider",
            "Library/Application Support/obs-studio/logs/session.log"
        ]
        for path in fixturePaths {
            let fileURL = homeURL.appendingPathComponent(path)
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data([0x01]).write(to: fileURL)
        }

        let catalog = CleanupCatalog.standard
        let ruleIDs = [
            "epic-games-launcher-cache",
            "dropbox-cache-folders",
            "terraform-plugin-cache",
            "obs-logs"
        ]
        let rules = try ruleIDs.map { id throws -> CleanupRule in
            guard let rule = catalog.rule(id: id) else {
                throw TestError.missingRule(id)
            }
            return rule
        }

        var discovery = StorageCandidateDiscovery(fileManager: fileManager)
        discovery.prepare(rules: rules, homeURL: homeURL)

        for rule in rules {
            let rootURL = rule.location.resolve(homeURL: homeURL)
            let candidates = try discovery.candidates(
                for: rule,
                rootURL: rootURL,
                homeURL: homeURL
            )
            XCTAssertFalse(candidates.isEmpty, "No candidate for \(rule.id)")
        }
    }
}

private enum TestError: Error {
    case missingRule(String)
}
