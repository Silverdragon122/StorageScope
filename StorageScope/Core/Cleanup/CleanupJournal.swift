import Darwin
import Foundation

enum StagedEntryState: String, Codable, Sendable {
    case staged
    case deleted
}

struct StagedEntry: Codable, Sendable {
    let ruleID: String?
    let originalPath: String
    let stagedName: String
    let expectedIdentity: FileIdentity
    let allocatedBytes: Int64
    var requiresAdministratorPrivileges: Bool? = nil
    var state: StagedEntryState

    init(
        ruleID: String? = nil,
        originalPath: String,
        stagedName: String,
        expectedIdentity: FileIdentity,
        allocatedBytes: Int64,
        requiresAdministratorPrivileges: Bool? = nil,
        state: StagedEntryState
    ) {
        self.ruleID = ruleID
        self.originalPath = originalPath
        self.stagedName = stagedName
        self.expectedIdentity = expectedIdentity
        self.allocatedBytes = allocatedBytes
        self.requiresAdministratorPrivileges = requiresAdministratorPrivileges
        self.state = state
    }
}

struct CleanupManifest: Codable, Sendable {
    let operationID: UUID
    var entries: [StagedEntry]
}

enum CleanupJournalError: Error {
    case unsafePath
    case invalidManifest
    case manifestTooLarge
    case couldNotRead
}

struct CleanupJournal {
    private static let maximumEntryCount = 100_000
    private static let maximumManifestBytes = 32 * 1024 * 1024

    private let fileManager: FileManager
    private let currentUserID: uid_t
    let recoveryRootURL: URL

    init(
        recoveryRootURL: URL,
        fileManager: FileManager = .default,
        currentUserID: uid_t = getuid()
    ) {
        self.recoveryRootURL = Self.canonicalizingExistingAncestor(
            of: recoveryRootURL
        )
        self.fileManager = fileManager
        self.currentUserID = currentUserID
    }

    func prepareRecoveryRoot() throws {
        var information = stat()
        if lstat(recoveryRootURL.path, &information) != 0 {
            guard errno == ENOENT else { throw CleanupJournalError.unsafePath }
            try fileManager.createDirectory(
                at: recoveryRootURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } else {
            guard
                information.st_mode & S_IFMT == S_IFDIR,
                information.st_uid == currentUserID,
                Self.pathResolvesToItself(recoveryRootURL.path)
            else {
                throw CleanupJournalError.unsafePath
            }
        }

        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: recoveryRootURL.path
        )
        _ = try secureDirectoryInformation(at: recoveryRootURL)
    }

    func createOperation(id: UUID) throws -> URL {
        try prepareRecoveryRoot()
        let operationURL = recoveryRootURL.appendingPathComponent(
            id.uuidString,
            isDirectory: true
        )
        guard !pathExistsWithoutFollowingLink(operationURL.path) else {
            throw CleanupJournalError.unsafePath
        }
        try fileManager.createDirectory(
            at: operationURL,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )
        _ = try validateOperationURL(operationURL)
        return operationURL
    }

    func save(_ manifest: CleanupManifest, at operationURL: URL) throws {
        try validate(manifest, at: operationURL)
        let manifestURL = manifestURL(for: operationURL)
        try validateExistingManifestFileIfPresent(manifestURL)

        let data = try JSONEncoder().encode(manifest)
        guard data.count <= Self.maximumManifestBytes else {
            throw CleanupJournalError.manifestTooLarge
        }
        try data.write(
            to: manifestURL,
            options: [.atomic, .completeFileProtection]
        )
        try validateExistingManifestFileIfPresent(manifestURL)
    }

    func load(from operationURL: URL) throws -> CleanupManifest {
        _ = try validateOperationURL(operationURL)
        let data = try readManifestData(at: manifestURL(for: operationURL))
        let manifest = try JSONDecoder().decode(CleanupManifest.self, from: data)
        try validate(manifest, at: operationURL)
        return manifest
    }

    func operationURLs() -> [URL] {
        guard (try? secureDirectoryInformation(at: recoveryRootURL)) != nil else {
            return []
        }
        guard
            let urls = try? fileManager.contentsOfDirectory(
                at: recoveryRootURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }
        return urls
    }

    func removeOperationIfEmpty(_ operationURL: URL) {
        guard (try? validateOperationURL(operationURL)) != nil else { return }
        guard
            let children = try? fileManager.contentsOfDirectory(
                at: operationURL,
                includingPropertiesForKeys: nil
            )
        else {
            return
        }

        let nonManifestChildren = children.filter {
            $0.lastPathComponent != "manifest.json"
        }
        guard nonManifestChildren.isEmpty else { return }
        try? fileManager.removeItem(at: operationURL)
    }

    func stagedURL(for entry: StagedEntry, operationURL: URL) throws -> URL {
        _ = try validateOperationURL(operationURL)
        guard Self.isCanonicalStagedName(entry.stagedName) else {
            throw CleanupJournalError.unsafePath
        }

        let url = operationURL.appendingPathComponent(
            entry.stagedName,
            isDirectory: false
        )
        guard
            url.deletingLastPathComponent().path
                == operationURL.path
        else {
            throw CleanupJournalError.unsafePath
        }
        return url
    }

    func isValidOperationURL(_ operationURL: URL) -> Bool {
        (try? validateOperationURL(operationURL)) != nil
    }

    private func validate(
        _ manifest: CleanupManifest,
        at operationURL: URL
    ) throws {
        let operationID = try validateOperationURL(operationURL)
        guard
            manifest.operationID == operationID,
            manifest.entries.count <= Self.maximumEntryCount
        else {
            throw CleanupJournalError.invalidManifest
        }

        var originalPaths: Set<String> = []
        for (index, entry) in manifest.entries.enumerated() {
            guard
                entry.stagedName == String(index),
                Self.isCanonicalStagedName(entry.stagedName),
                Self.isCanonicalAbsolutePath(entry.originalPath),
                entry.allocatedBytes >= 0,
                originalPaths.insert(entry.originalPath).inserted
            else {
                throw CleanupJournalError.invalidManifest
            }
            if let ruleID = entry.ruleID {
                guard !ruleID.isEmpty, ruleID.utf8.count <= 256 else {
                    throw CleanupJournalError.invalidManifest
                }
            }
        }
    }

    private func validateOperationURL(_ operationURL: URL) throws -> UUID {
        let operationPath = operationURL.path
        guard
            Self.isCanonicalAbsolutePath(operationPath),
            operationURL.deletingLastPathComponent().path
                == recoveryRootURL.path,
            let operationID = UUID(uuidString: operationURL.lastPathComponent),
            operationURL.lastPathComponent == operationID.uuidString
        else {
            throw CleanupJournalError.unsafePath
        }

        let rootInformation = try secureDirectoryInformation(at: recoveryRootURL)
        let operationInformation = try secureDirectoryInformation(at: operationURL)
        guard operationInformation.st_dev == rootInformation.st_dev else {
            throw CleanupJournalError.unsafePath
        }
        return operationID
    }

    private func secureDirectoryInformation(at url: URL) throws -> stat {
        var information = stat()
        guard
            lstat(url.path, &information) == 0,
            information.st_mode & S_IFMT == S_IFDIR,
            information.st_uid == currentUserID,
            information.st_mode & 0o077 == 0,
            information.st_mode & 0o700 == 0o700,
            Self.pathResolvesToItself(url.path),
            Self.hasSafeAncestorChain(of: url.path)
        else {
            throw CleanupJournalError.unsafePath
        }
        return information
    }

    private func validateExistingManifestFileIfPresent(_ url: URL) throws {
        var information = stat()
        if lstat(url.path, &information) != 0 {
            guard errno == ENOENT else { throw CleanupJournalError.unsafePath }
            return
        }
        guard
            information.st_mode & S_IFMT == S_IFREG,
            information.st_uid == currentUserID,
            information.st_mode & 0o022 == 0,
            information.st_nlink == 1
        else {
            throw CleanupJournalError.unsafePath
        }
    }

    private func readManifestData(at url: URL) throws -> Data {
        let descriptor = open(url.path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
        guard descriptor >= 0 else { throw CleanupJournalError.couldNotRead }
        defer { close(descriptor) }

        var information = stat()
        guard
            fstat(descriptor, &information) == 0,
            information.st_mode & S_IFMT == S_IFREG,
            information.st_uid == currentUserID,
            information.st_mode & 0o022 == 0,
            information.st_nlink == 1,
            information.st_size > 0,
            information.st_size <= Self.maximumManifestBytes
        else {
            throw CleanupJournalError.invalidManifest
        }

        let byteCount = Int(information.st_size)
        var data = Data(count: byteCount)
        let didReadAllBytes = data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return false }
            var offset = 0
            while offset < byteCount {
                let count = Darwin.read(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    byteCount - offset
                )
                if count < 0 && errno == EINTR { continue }
                guard count > 0 else { return false }
                offset += count
            }
            return true
        }
        guard didReadAllBytes else { throw CleanupJournalError.couldNotRead }

        var extraByte: UInt8 = 0
        let extraCount = withUnsafeMutablePointer(to: &extraByte) {
            Darwin.read(descriptor, $0, 1)
        }
        guard extraCount == 0 else { throw CleanupJournalError.invalidManifest }
        return data
    }

    private func pathExistsWithoutFollowingLink(_ path: String) -> Bool {
        var information = stat()
        return lstat(path, &information) == 0
    }

    private static func isCanonicalAbsolutePath(_ path: String) -> Bool {
        guard path.hasPrefix("/"), path != "/", !path.hasSuffix("/") else {
            return false
        }
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard components.first?.isEmpty == true else { return false }
        return components.dropFirst().allSatisfy {
            !$0.isEmpty && $0 != "." && $0 != ".."
        }
    }

    private static func isCanonicalStagedName(_ name: String) -> Bool {
        guard
            !name.isEmpty,
            name == "0" || !name.hasPrefix("0"),
            name.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
            let value = Int(name),
            value >= 0,
            value < maximumEntryCount
        else {
            return false
        }
        return true
    }

    private static func canonicalizingExistingAncestor(of url: URL) -> URL {
        var ancestor = url.standardizedFileURL
        var missingComponents: [String] = [ancestor.lastPathComponent]
        var information = stat()

        ancestor.deleteLastPathComponent()

        while lstat(ancestor.path, &information) != 0 && ancestor.path != "/" {
            missingComponents.insert(ancestor.lastPathComponent, at: 0)
            ancestor.deleteLastPathComponent()
        }

        var resolvedBuffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        let resolvedAncestorPath = ancestor.path.withCString { path in
            resolvedBuffer.withUnsafeMutableBufferPointer { buffer in
                guard
                    let baseAddress = buffer.baseAddress,
                    realpath(path, baseAddress) != nil
                else {
                    return ancestor.path
                }
                return String(cString: baseAddress)
            }
        }
        let resolvedAncestor = URL(
            fileURLWithPath: resolvedAncestorPath,
            isDirectory: true
        )

        return missingComponents.reduce(resolvedAncestor) { partialURL, component in
            partialURL.appendingPathComponent(component, isDirectory: true)
        }
    }

    private static func pathResolvesToItself(_ path: String) -> Bool {
        var resolvedBuffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        return path.withCString { inputPath in
            resolvedBuffer.withUnsafeMutableBufferPointer { buffer in
                guard
                    let baseAddress = buffer.baseAddress,
                    realpath(inputPath, baseAddress) != nil
                else {
                    return false
                }
                return String(cString: baseAddress) == path
            }
        }
    }

    private static func hasSafeAncestorChain(of path: String) -> Bool {
        var ancestorURL = URL(fileURLWithPath: path).deletingLastPathComponent()

        while true {
            var information = stat()
            guard
                lstat(ancestorURL.path, &information) == 0,
                information.st_mode & S_IFMT == S_IFDIR,
                information.st_mode & 0o022 == 0
                    || information.st_mode & 0o1000 != 0,
                pathResolvesToItself(ancestorURL.path)
            else {
                return false
            }
            guard ancestorURL.path != "/" else { return true }

            let parentURL = ancestorURL.deletingLastPathComponent()
            guard parentURL.path != ancestorURL.path else { return false }
            ancestorURL = parentURL
        }
    }

    private func manifestURL(for operationURL: URL) -> URL {
        operationURL.appendingPathComponent("manifest.json", isDirectory: false)
    }
}
