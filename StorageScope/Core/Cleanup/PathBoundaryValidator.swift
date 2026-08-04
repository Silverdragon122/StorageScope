import Darwin
import Foundation

enum CleanupValidationError: Error {
    case failure(CleanupFailureReason)

    var reason: CleanupFailureReason {
        switch self {
        case .failure(let reason):
            return reason
        }
    }
}

struct ValidatedCleanupTarget: Sendable {
    let url: URL
    let identity: FileIdentity
    let allocatedBytes: Int64
}

struct ValidatedCleanup: Sendable {
    let item: StorageItem
    let targets: [ValidatedCleanupTarget]
    let requiresAdministratorPrivileges: Bool
}

struct ValidatedRecoveryDestination: Sendable {
    let url: URL
    let requiresAdministratorPrivileges: Bool
}

struct PathBoundaryValidator {
    static let approvedAbsoluteCleanupRootPaths = [
        "/Library/Application Support/Adobe",
        "/Library/Caches",
        "/Library/Logs",
        "/cores"
    ]

    private let catalog: CleanupCatalog
    private let homeURL: URL
    private let fileManager: FileManager
    private let currentUserID: uid_t
    private let approvedAbsoluteCleanupRootPaths: [String]

    init(
        catalog: CleanupCatalog,
        homeURL: URL,
        fileManager: FileManager = .default,
        currentUserID: uid_t = getuid(),
        approvedAbsoluteCleanupRootPaths: [String] = Self.approvedAbsoluteCleanupRootPaths
    ) {
        self.catalog = catalog
        self.homeURL = homeURL.standardizedFileURL
        self.fileManager = fileManager
        self.currentUserID = currentUserID
        self.approvedAbsoluteCleanupRootPaths =
            approvedAbsoluteCleanupRootPaths.map {
                URL(fileURLWithPath: $0).standardizedFileURL.path
            }
    }

    func validate(
        item: StorageItem,
        activeBundleIdentifiers: Set<String>
    ) throws -> ValidatedCleanup {
        guard let rule = catalog.rule(id: item.ruleID) else {
            throw failure(.outsideAllowedLocation)
        }
        guard rule.safety.allowsCleanup, !rule.isReadOnly, item.safety.allowsCleanup else {
            throw failure(.protectedItem)
        }
        guard
            activeBundleIdentifiers.isDisjoint(
                with: item.blockedBundleIdentifiers
            )
        else {
            throw failure(.applicationIsOpen)
        }

        let rootURL = rule.location.resolve(homeURL: homeURL).standardizedFileURL
        let itemURL = item.url.standardizedFileURL
        let pathValidationBaseURL: URL
        let requiresCurrentUserOwnership: Bool

        switch rule.location {
        case .home:
            guard isWithinHome(rootURL), rootURL != homeURL else {
                throw failure(.outsideAllowedLocation)
            }
            pathValidationBaseURL = homeURL
            requiresCurrentUserOwnership = true
        case .absolute:
            guard isApprovedAbsoluteCleanupRoot(rootURL) else {
                throw failure(.outsideAllowedLocation)
            }
            pathValidationBaseURL = URL(
                fileURLWithPath: "/",
                isDirectory: true
            )
            requiresCurrentUserOwnership = false
        case .userTemporaryRoot:
            throw failure(.outsideAllowedLocation)
        }

        guard
            itemURL == rootURL || isDescendant(itemURL, of: rootURL),
            matches(itemURL, rule: rule, rootURL: rootURL)
        else {
            throw failure(.outsideAllowedLocation)
        }
        guard itemURL != homeURL, itemURL.path != "/" else {
            throw failure(.outsideAllowedLocation)
        }

        try rejectSymbolicLinkInPath(
            from: pathValidationBaseURL,
            through: itemURL
        )

        guard fileManager.fileExists(atPath: itemURL.path) else {
            throw failure(.noLongerExists)
        }

        let currentIdentity: FileIdentity
        do {
            currentIdentity = try FileIdentity(url: itemURL)
        } catch {
            throw failure(.noLongerExists)
        }

        guard currentIdentity == item.identity else {
            throw failure(.changedSinceScan)
        }
        guard
            !requiresCurrentUserOwnership
                || currentIdentity.owner == currentUserID,
            currentIdentity.kind == .regularFile
                || currentIdentity.kind == .directory
        else {
            throw failure(.unsafeFilesystemEntry)
        }

        let targets: [ValidatedCleanupTarget]
        switch item.cleanupAction {
        case .deleteItem:
            try validateTree(at: itemURL, expectedDevice: currentIdentity.device)
            targets = [
                ValidatedCleanupTarget(
                    url: itemURL,
                    identity: currentIdentity,
                    allocatedBytes: item.allocatedBytes
                )
            ]
        case .deleteContents:
            guard currentIdentity.kind == .directory else {
                throw failure(.unsafeFilesystemEntry)
            }
            try validateTree(at: itemURL, expectedDevice: currentIdentity.device)
            targets = try childTargets(
                in: itemURL,
                expectedDevice: currentIdentity.device
            )
        case .simulatorDevice(let identifier):
            guard
                case .simulatorDevices = rule.source,
                UUID(uuidString: identifier) != nil,
                itemURL.lastPathComponent.caseInsensitiveCompare(identifier)
                    == .orderedSame
            else {
                throw failure(.outsideAllowedLocation)
            }
            targets = []
        case .none:
            throw failure(.protectedItem)
        }

        return ValidatedCleanup(
            item: item,
            targets: targets,
            requiresAdministratorPrivileges: !requiresCurrentUserOwnership
        )
    }

    func validateRecoveryDestination(
        for entry: StagedEntry
    ) throws -> ValidatedRecoveryDestination {
        guard
            let ruleID = entry.ruleID,
            let rule = catalog.rule(id: ruleID),
            rule.safety.allowsCleanup,
            !rule.isReadOnly,
            let storedAdministratorRequirement =
                entry.requiresAdministratorPrivileges
        else {
            throw failure(.outsideAllowedLocation)
        }

        let rootURL = rule.location.resolve(homeURL: homeURL).standardizedFileURL
        let originalURL = URL(fileURLWithPath: entry.originalPath).standardizedFileURL
        guard
            originalURL.path == entry.originalPath,
            originalURL.path != "/",
            originalURL != homeURL
        else {
            throw failure(.outsideAllowedLocation)
        }

        let pathValidationBaseURL: URL
        let requiresAdministratorPrivileges: Bool
        switch rule.location {
        case .home:
            guard isWithinHome(rootURL), rootURL != homeURL else {
                throw failure(.outsideAllowedLocation)
            }
            pathValidationBaseURL = homeURL
            requiresAdministratorPrivileges = false
        case .absolute:
            guard isApprovedAbsoluteCleanupRoot(rootURL) else {
                throw failure(.outsideAllowedLocation)
            }
            pathValidationBaseURL = URL(fileURLWithPath: "/", isDirectory: true)
            requiresAdministratorPrivileges = true
        case .userTemporaryRoot:
            throw failure(.outsideAllowedLocation)
        }

        guard storedAdministratorRequirement == requiresAdministratorPrivileges else {
            throw failure(.outsideAllowedLocation)
        }

        let itemURL: URL
        switch rule.cleanupAction {
        case .deleteItem:
            itemURL = originalURL
        case .deleteContents:
            itemURL = originalURL.deletingLastPathComponent()
            guard isDescendant(originalURL, of: itemURL) else {
                throw failure(.outsideAllowedLocation)
            }
        case .simulatorDevice, .none:
            throw failure(.protectedItem)
        }

        guard
            itemURL == rootURL || isDescendant(itemURL, of: rootURL),
            matches(itemURL, rule: rule, rootURL: rootURL)
        else {
            throw failure(.outsideAllowedLocation)
        }

        try rejectSymbolicLinkInPath(
            from: pathValidationBaseURL,
            through: originalURL
        )

        return ValidatedRecoveryDestination(
            url: originalURL,
            requiresAdministratorPrivileges: requiresAdministratorPrivileges
        )
    }

    private func childTargets(
        in directoryURL: URL,
        expectedDevice: UInt64
    ) throws -> [ValidatedCleanupTarget] {
        let children: [URL]
        do {
            children = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: []
            )
        } catch {
            throw failure(.unsafeFilesystemEntry)
        }

        return try children.map { childURL in
            let identity = try FileIdentity(url: childURL)
            guard
                identity.device == expectedDevice,
                isSafeCleanupEntry(identity.kind)
            else {
                throw failure(.unsafeFilesystemEntry)
            }

            if identity.kind == .directory {
                try validateTree(at: childURL, expectedDevice: expectedDevice)
            }

            var seenFiles: Set<FileKey> = []
            let measurement = try AllocatedSizeCalculator(
                fileManager: fileManager
            ).measure(url: childURL, seenFiles: &seenFiles)
            guard !measurement.encounteredUnreadableEntry else {
                throw failure(.unsafeFilesystemEntry)
            }

            return ValidatedCleanupTarget(
                url: childURL,
                identity: identity,
                allocatedBytes: measurement.allocatedBytes
            )
        }
    }

    private func validateTree(at rootURL: URL, expectedDevice: UInt64) throws {
        var encounteredReadError = false
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: [],
            errorHandler: { _, _ in
                encounteredReadError = true
                return false
            }
        ) else {
            return
        }

        while let childURL = enumerator.nextObject() as? URL {
            let identity: FileIdentity
            do {
                identity = try FileIdentity(url: childURL)
            } catch {
                throw failure(.unsafeFilesystemEntry)
            }

            guard identity.device == expectedDevice else {
                throw failure(.unsafeFilesystemEntry)
            }

            switch identity.kind {
            case .directory, .regularFile:
                continue
            case .symbolicLink, .namedPipe, .unixSocket:
                enumerator.skipDescendants()
            case .characterDevice, .blockDevice, .other:
                throw failure(.unsafeFilesystemEntry)
            }
        }

        if encounteredReadError {
            throw failure(.unsafeFilesystemEntry)
        }
    }

    private func rejectSymbolicLinkInPath(from baseURL: URL, through targetURL: URL) throws {
        guard isDescendant(targetURL, of: baseURL) else {
            throw failure(.outsideAllowedLocation)
        }

        let baseComponents = baseURL.pathComponents
        let targetComponents = targetURL.pathComponents
        var currentURL = baseURL

        for component in targetComponents.dropFirst(baseComponents.count) {
            currentURL.appendPathComponent(component)
            guard let identity = try? FileIdentity(url: currentURL) else { continue }
            if identity.kind == .symbolicLink {
                throw failure(.unsafeFilesystemEntry)
            }
        }
    }

    private func isWithinHome(_ url: URL) -> Bool {
        url == homeURL || isDescendant(url, of: homeURL)
    }

    private func isSafeCleanupEntry(_ kind: FileNodeKind) -> Bool {
        switch kind {
        case .regularFile, .directory, .symbolicLink, .namedPipe, .unixSocket:
            true
        case .characterDevice, .blockDevice, .other:
            false
        }
    }

    private func isApprovedAbsoluteCleanupRoot(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return approvedAbsoluteCleanupRootPaths.contains {
            path == $0 || path.hasPrefix($0 + "/")
        }
    }

    private func isDescendant(_ candidate: URL, of root: URL) -> Bool {
        let rootComponents = root.standardizedFileURL.pathComponents
        let candidateComponents = candidate.standardizedFileURL.pathComponents
        guard candidateComponents.count > rootComponents.count else { return false }
        return candidateComponents.starts(with: rootComponents)
    }

    private func matches(
        _ candidateURL: URL,
        rule: CleanupRule,
        rootURL: URL
    ) -> Bool {
        let relativeComponents = Array(
            candidateURL.pathComponents.dropFirst(rootURL.pathComponents.count)
        )

        switch rule.source {
        case .location:
            return candidateURL == rootURL
        case .children:
            return relativeComponents.count == 1
        case .nestedChildren(let relativePath):
            let nestedComponents = relativePath
                .split(separator: "/", omittingEmptySubsequences: true)
                .map(String.init)
            guard relativeComponents.count == nestedComponents.count + 1 else {
                return false
            }
            return Array(relativeComponents.dropFirst()) == nestedComponents
        case .matchingDirectories(
            let names,
            let extensions,
            let requiredAncestorExtensions,
            let maximumDepth
        ):
            guard
                !relativeComponents.isEmpty,
                relativeComponents.count <= maximumDepth
            else {
                return false
            }
            let nameMatches = names.contains(candidateURL.lastPathComponent)
            let extensionMatches = extensions.contains(
                candidateURL.pathExtension.lowercased()
            )
            guard nameMatches || extensionMatches else { return false }
            if requiredAncestorExtensions.isEmpty {
                return true
            }
            return candidateURL.deletingLastPathComponent().pathComponents.contains {
                requiredAncestorExtensions.contains(
                    URL(fileURLWithPath: $0).pathExtension.lowercased()
                )
            }
        case .simulatorDevices:
            return
                relativeComponents.count == 1
                && UUID(uuidString: candidateURL.lastPathComponent) != nil
        case .otherUserHomes:
            return false
        }
    }

    private func failure(_ reason: CleanupFailureReason) -> CleanupValidationError {
        .failure(reason)
    }
}
