import Foundation

struct CleanupCatalog: Sendable {
    let rules: [CleanupRule]
    private let rulesByID: [String: CleanupRule]

    static let standard = CleanupCatalog(rules: standardRules)

    init(rules: [CleanupRule]) {
        var index: [String: CleanupRule] = [:]
        index.reserveCapacity(rules.count)

        for rule in rules {
            precondition(
                index.updateValue(rule, forKey: rule.id) == nil,
                "Duplicate cleanup rule identifier: \(rule.id)"
            )
        }

        self.rules = rules
        self.rulesByID = index
    }

    func rule(id: String) -> CleanupRule? {
        rulesByID[id]
    }
}

extension CleanupCatalog {
    static let xcodeBundleIDs: Set<String> = [
        "com.apple.dt.Xcode",
        "com.apple.iphonesimulator"
    ]

    static let creativeBundleIDs: Set<String> = [
        "com.apple.FinalCut",
        "com.apple.iMovieApp"
    ]

    static let standardRules: [CleanupRule] =
        appleDevelopmentRules
        + developerToolRules
        + expandedDeveloperRules
        + creativeRules
        + expandedCreativeRules
        + expandedBrowserRules
        + browserRules
        + expandedApplicationCacheRules
        + applicationCacheRules
        + logAndBackupRules
        + localModelRules
        + expandedProtectedDataRules
        + largeDataRules
        + systemManagedRules

    static func rule(
        _ id: String,
        _ category: StorageCategory,
        _ locationName: String,
        _ itemTitle: String,
        _ detail: String,
        _ consequence: String,
        _ safety: CleanupSafety,
        _ relativePath: String,
        _ source: CandidateSource,
        _ nameStyle: ItemNameStyle,
        _ cleanupAction: RuleCleanupAction,
        _ blockedBundleIdentifiers: Set<String> = []
    ) -> CleanupRule {
        CleanupRule(
            id: id,
            category: category,
            locationName: locationName,
            itemTitle: itemTitle,
            itemDetail: detail,
            consequence: consequence,
            safety: safety,
            location: .home(relativePath: relativePath),
            source: source,
            nameStyle: nameStyle,
            cleanupAction: cleanupAction,
            blockedBundleIdentifiers: blockedBundleIdentifiers
        )
    }

    static func readOnlyRule(
        _ id: String,
        _ category: StorageCategory,
        _ locationName: String,
        _ detail: String,
        _ consequence: String,
        _ location: CatalogLocation,
        _ source: CandidateSource,
        _ nameStyle: ItemNameStyle
    ) -> CleanupRule {
        CleanupRule(
            id: id,
            category: category,
            locationName: locationName,
            itemTitle: locationName,
            itemDetail: detail,
            consequence: consequence,
            safety: .protected,
            location: location,
            source: source,
            nameStyle: nameStyle,
            cleanupAction: .none,
            blockedBundleIdentifiers: []
        )
    }
}
