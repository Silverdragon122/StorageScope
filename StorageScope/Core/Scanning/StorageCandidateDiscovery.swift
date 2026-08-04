import Foundation

struct ScanCandidate: Sendable {
    let url: URL
    let identifier: String?
    let titleOverride: String?
}

private struct DirectoryInventory {
    struct Entry {
        let url: URL
        let depth: Int
    }

    let maximumDepth: Int
    let entries: [Entry]
}

struct StorageCandidateDiscovery {
    private let fileManager: FileManager
    private var directoryInventories: [String: DirectoryInventory] = [:]
    private var childURLCache: [String: [URL]] = [:]
    private var existingPaths: Set<String> = []
    private var missingPaths: Set<String> = []
    private var plannedMaximumDepthByRoot: [String: Int] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    mutating func prepare(
        rules: [CleanupRule],
        homeURL: URL
    ) {
        directoryInventories.removeAll(keepingCapacity: true)
        childURLCache.removeAll(keepingCapacity: true)
        existingPaths.removeAll(keepingCapacity: true)
        missingPaths.removeAll(keepingCapacity: true)
        plannedMaximumDepthByRoot.removeAll(keepingCapacity: true)

        for rule in rules {
            guard
                case .matchingDirectories(
                    _,
                    _,
                    _,
                    let maximumDepth
                ) = rule.source
            else {
                continue
            }
            let rootPath = rule.location
                .resolve(homeURL: homeURL)
                .standardizedFileURL
                .path
            plannedMaximumDepthByRoot[rootPath] = max(
                plannedMaximumDepthByRoot[rootPath] ?? 0,
                maximumDepth
            )
        }
    }

    mutating func candidates(
        for rule: CleanupRule,
        rootURL: URL,
        homeURL: URL
    ) throws -> [ScanCandidate] {
        guard pathExists(rootURL) else { return [] }

        switch rule.source {
        case .location:
            return [ScanCandidate(url: rootURL, identifier: nil, titleOverride: nil)]
        case .children:
            return try childURLs(of: rootURL).map {
                ScanCandidate(url: $0, identifier: nil, titleOverride: nil)
            }
        case .nestedChildren(let relativePath):
            let containerURLs = try childURLs(of: rootURL)
            return containerURLs.compactMap { containerURL in
                let nestedURL = relativePath
                    .split(separator: "/", omittingEmptySubsequences: true)
                    .reduce(containerURL) { partialURL, component in
                        partialURL.appendingPathComponent(
                            String(component),
                            isDirectory: true
                        )
                    }

                guard pathExists(nestedURL) else { return nil }
                return ScanCandidate(
                    url: nestedURL,
                    identifier: nil,
                    titleOverride: containerURL.lastPathComponent
                )
            }
        case .matchingDirectories(
            let names,
            let extensions,
            let requiredAncestorExtensions,
            let maximumDepth
        ):
            return matchingDirectories(
                under: rootURL,
                names: names,
                extensions: extensions,
                requiredAncestorExtensions: requiredAncestorExtensions,
                maximumDepth: maximumDepth
            )
        case .simulatorDevices:
            return try simulatorDeviceCandidates(in: rootURL)
        case .otherUserHomes:
            return try otherUserHomeCandidates(
                in: rootURL,
                currentHomeURL: homeURL
            )
        }
    }

    private mutating func childURLs(
        of directoryURL: URL
    ) throws -> [URL] {
        let cacheKey = directoryURL.standardizedFileURL.path
        if let cachedURLs = childURLCache[cacheKey] {
            return cachedURLs
        }

        let urls = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: []
        )
        .filter { $0.lastPathComponent != ".DS_Store" }
        childURLCache[cacheKey] = urls
        existingPaths.insert(cacheKey)
        return urls
    }

    private mutating func matchingDirectories(
        under rootURL: URL,
        names: Set<String>,
        extensions: Set<String>,
        requiredAncestorExtensions: Set<String>,
        maximumDepth: Int
    ) -> [ScanCandidate] {
        let inventory = directoryInventory(
            under: rootURL,
            maximumDepth: maximumDepth
        )
        return inventory.entries.compactMap { entry in
            let url = entry.url
            let nameMatches = names.contains(url.lastPathComponent)
            let extensionMatches = extensions.contains(url.pathExtension.lowercased())
            guard nameMatches || extensionMatches else { return nil }

            if !requiredAncestorExtensions.isEmpty {
                let hasRequiredAncestor = url.deletingLastPathComponent().pathComponents
                    .contains { component in
                        let pathExtension = URL(fileURLWithPath: component).pathExtension
                        return requiredAncestorExtensions.contains(pathExtension.lowercased())
                    }
                guard hasRequiredAncestor else { return nil }
            }

            return ScanCandidate(url: url, identifier: nil, titleOverride: nil)
        }
    }

    private mutating func directoryInventory(
        under rootURL: URL,
        maximumDepth: Int
    ) -> DirectoryInventory {
        let cacheKey = rootURL.standardizedFileURL.path
        if
            let cached = directoryInventories[cacheKey],
            cached.maximumDepth >= maximumDepth
        {
            if cached.maximumDepth == maximumDepth {
                return cached
            }
            return DirectoryInventory(
                maximumDepth: maximumDepth,
                entries: cached.entries.filter { $0.depth <= maximumDepth }
            )
        }

        let scanDepth = max(
            maximumDepth,
            plannedMaximumDepthByRoot[cacheKey] ?? maximumDepth
        )
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey]
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return DirectoryInventory(maximumDepth: scanDepth, entries: [])
        }

        var entries: [DirectoryInventory.Entry] = []

        while let url = enumerator.nextObject() as? URL {
            if Task.isCancelled { break }

            let depth = enumerator.level
            if depth > scanDepth {
                enumerator.skipDescendants()
                continue
            }

            let kind = nodeKind(at: url, prefetchedKeys: resourceKeys)
            if kind == .symbolicLink {
                enumerator.skipDescendants()
                continue
            }
            guard kind == .directory else { continue }

            entries.append(
                DirectoryInventory.Entry(url: url, depth: depth)
            )
        }

        let inventory = DirectoryInventory(
            maximumDepth: scanDepth,
            entries: entries
        )
        directoryInventories[cacheKey] = inventory
        if scanDepth == maximumDepth {
            return inventory
        }
        return DirectoryInventory(
            maximumDepth: maximumDepth,
            entries: entries.filter { $0.depth <= maximumDepth }
        )
    }

    private func nodeKind(
        at url: URL,
        prefetchedKeys: Set<URLResourceKey>
    ) -> FileNodeKind? {
        if let values = try? url.resourceValues(forKeys: prefetchedKeys) {
            if values.isSymbolicLink == true {
                return .symbolicLink
            }
            if values.isDirectory == true {
                return .directory
            }
            if values.isDirectory == false {
                return .regularFile
            }
        }
        return try? FileIdentity(url: url).kind
    }

    private mutating func simulatorDeviceCandidates(
        in rootURL: URL
    ) throws -> [ScanCandidate] {
        try childURLs(of: rootURL).compactMap { deviceURL in
            let identifier = deviceURL.lastPathComponent
            guard UUID(uuidString: identifier) != nil else { return nil }

            let plistURL = deviceURL.appendingPathComponent("device.plist")
            let name = simulatorName(from: plistURL) ?? AppCopy.Core.simulatorDevice
            return ScanCandidate(
                url: deviceURL,
                identifier: identifier,
                titleOverride: name
            )
        }
    }

    private mutating func otherUserHomeCandidates(
        in rootURL: URL,
        currentHomeURL: URL
    ) throws -> [ScanCandidate] {
        let currentHomePath = currentHomeURL.standardizedFileURL.path
        return try childURLs(of: rootURL).compactMap { candidateURL in
            let standardizedURL = candidateURL.standardizedFileURL
            guard
                standardizedURL.path != currentHomePath,
                standardizedURL.lastPathComponent != "Shared",
                standardizedURL.lastPathComponent != "Deleted Users",
                (try? FileIdentity(url: standardizedURL).kind) == .directory
            else {
                return nil
            }

            return ScanCandidate(
                url: standardizedURL,
                identifier: nil,
                titleOverride: standardizedURL.lastPathComponent
            )
        }
    }

    private func simulatorName(from plistURL: URL) -> String? {
        guard
            let data = try? Data(contentsOf: plistURL),
            let object = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ),
            let dictionary = object as? [String: Any],
            let name = dictionary["name"] as? String
        else {
            return nil
        }

        if
            let runtime = dictionary["runtime"] as? String,
            let runtimeName = runtime.split(separator: ".").last
        {
            let readableRuntime = runtimeName
                .replacingOccurrences(of: "SimRuntime-", with: "")
                .replacingOccurrences(of: "-", with: " ")
            return AppCopy.Core.simulatorRuntime(
                name: name,
                runtime: readableRuntime
            )
        }

        return name
    }

    private mutating func pathExists(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        if existingPaths.contains(path) {
            return true
        }
        if missingPaths.contains(path) {
            return false
        }

        if fileManager.fileExists(atPath: path) {
            existingPaths.insert(path)
            return true
        }
        missingPaths.insert(path)
        return false
    }
}
