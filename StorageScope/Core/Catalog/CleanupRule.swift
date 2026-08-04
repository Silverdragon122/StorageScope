import Foundation

enum CatalogLocation: Hashable, Sendable {
    case home(relativePath: String)
    case absolute(path: String)
    case userTemporaryRoot

    func resolve(homeURL: URL) -> URL {
        switch self {
        case .home(let relativePath):
            return relativePath
                .split(separator: "/", omittingEmptySubsequences: true)
                .reduce(homeURL) { partialURL, component in
                    partialURL.appendingPathComponent(String(component), isDirectory: true)
                }
        case .absolute(let path):
            return URL(fileURLWithPath: path, isDirectory: true)
        case .userTemporaryRoot:
            return URL(
                fileURLWithPath: NSTemporaryDirectory(),
                isDirectory: true
            )
            .deletingLastPathComponent()
        }
    }
}

enum CandidateSource: Hashable, Sendable {
    case location
    case children
    case nestedChildren(relativePath: String)
    case matchingDirectories(
        names: Set<String>,
        extensions: Set<String>,
        requiredAncestorExtensions: Set<String>,
        maximumDepth: Int
    )
    case simulatorDevices
    case otherUserHomes
}

enum ItemNameStyle: Hashable, Sendable {
    case fixed
    case child
    case childWithSuffix(String)
    case enclosingPackageWithSuffix(String)
    case appCache
    case simulatorDevice
}

enum RuleCleanupAction: Hashable, Sendable {
    case deleteItem
    case deleteContents
    case simulatorDevice
    case none

    func itemAction(identifier: String? = nil) -> CleanupAction {
        switch self {
        case .deleteItem:
            return .deleteItem
        case .deleteContents:
            return .deleteContents
        case .simulatorDevice:
            guard let identifier else { return .none }
            return .simulatorDevice(identifier: identifier)
        case .none:
            return .none
        }
    }
}

struct CleanupRule: Identifiable, Hashable, Sendable {
    let id: String
    let category: StorageCategory
    let locationName: String
    let itemTitle: String
    let itemDetail: String
    let consequence: String
    let safety: CleanupSafety
    let location: CatalogLocation
    let source: CandidateSource
    let nameStyle: ItemNameStyle
    let cleanupAction: RuleCleanupAction
    let blockedBundleIdentifiers: Set<String>

    init(
        id: String,
        category: StorageCategory,
        locationName: String,
        itemTitle: String,
        itemDetail: String,
        consequence: String,
        safety: CleanupSafety,
        location: CatalogLocation,
        source: CandidateSource,
        nameStyle: ItemNameStyle,
        cleanupAction: RuleCleanupAction,
        blockedBundleIdentifiers: Set<String>
    ) {
        self.id = id
        self.category = category
        self.locationName = LocalizedCopy.catalogField(
            ruleID: id,
            field: "location",
            fallback: locationName
        )
        self.itemTitle = LocalizedCopy.catalogField(
            ruleID: id,
            field: "title",
            fallback: itemTitle
        )
        self.itemDetail = LocalizedCopy.catalogField(
            ruleID: id,
            field: "detail",
            fallback: itemDetail
        )
        self.consequence = LocalizedCopy.catalogField(
            ruleID: id,
            field: "consequence",
            fallback: consequence
        )
        self.safety = safety
        self.location = location
        self.source = source
        self.nameStyle = nameStyle
        self.cleanupAction = cleanupAction
        self.blockedBundleIdentifiers = blockedBundleIdentifiers
    }

    var isReadOnly: Bool {
        safety == .protected || cleanupAction == .none
    }
}
