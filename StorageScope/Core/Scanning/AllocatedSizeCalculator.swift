import Darwin
import Foundation

struct FileKey: Hashable, Sendable {
    let device: UInt64
    let inode: UInt64
}

struct SizeMeasurement: Equatable, Sendable {
    let allocatedBytes: Int64
    let fileCount: Int
    let encounteredUnreadableEntry: Bool
    let rootIdentity: FileIdentity
}

enum SizeMeasurementError: Error {
    case changedDuringScan
}

private struct FileMetadata {
    let identity: FileIdentity
    let allocatedBytes: Int64
    let linkCount: UInt64

    init(url: URL) throws {
        var information = stat()
        guard lstat(url.path, &information) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        identity = FileIdentity(information: information)
        allocatedBytes = max(Int64(0), Int64(information.st_blocks)) * 512
        linkCount = UInt64(information.st_nlink)
    }
}

struct AllocatedSizeCalculator {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func measure(
        url: URL,
        seenFiles: inout Set<FileKey>,
        countRootAllocation: Bool = true,
        excluding excludedPaths: Set<String> = []
    ) throws -> SizeMeasurement {
        try Task.checkCancellation()

        let startingMetadata = try FileMetadata(url: url)
        let startingIdentity = startingMetadata.identity
        guard
            startingIdentity.kind == .regularFile
                || startingIdentity.kind == .directory
        else {
            return SizeMeasurement(
                allocatedBytes: 0,
                fileCount: 0,
                encounteredUnreadableEntry: false,
                rootIdentity: startingIdentity
            )
        }

        var allocatedBytes: Int64 = 0
        var fileCount = 0
        var encounteredUnreadableEntry = false

        if countRootAllocation {
            addAllocation(
                metadata: startingMetadata,
                seenFiles: &seenFiles,
                allocatedBytes: &allocatedBytes,
                fileCount: &fileCount
            )
        }

        if startingIdentity.kind == .directory {
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: nil,
                options: [],
                errorHandler: { _, _ in
                    encounteredUnreadableEntry = true
                    return true
                }
            )

            var visitedEntryCount = 0
            while let child = enumerator?.nextObject() as? URL {
                visitedEntryCount &+= 1
                if visitedEntryCount.isMultiple(of: 128) {
                    try Task.checkCancellation()
                }

                if
                    !excludedPaths.isEmpty,
                    excludedPaths.contains(child.path)
                {
                    enumerator?.skipDescendants()
                    continue
                }

                guard let metadata = try? FileMetadata(url: child) else {
                    encounteredUnreadableEntry = true
                    enumerator?.skipDescendants()
                    continue
                }
                let identity = metadata.identity

                if identity.device != startingIdentity.device {
                    enumerator?.skipDescendants()
                    continue
                }

                if identity.kind == .symbolicLink {
                    enumerator?.skipDescendants()
                }

                addAllocation(
                    metadata: metadata,
                    seenFiles: &seenFiles,
                    allocatedBytes: &allocatedBytes,
                    fileCount: &fileCount
                )
            }
        }

        guard (try? FileIdentity(url: url)) == startingIdentity else {
            throw SizeMeasurementError.changedDuringScan
        }

        return SizeMeasurement(
            allocatedBytes: allocatedBytes,
            fileCount: fileCount,
            encounteredUnreadableEntry: encounteredUnreadableEntry,
            rootIdentity: startingIdentity
        )
    }

    private func addAllocation(
        metadata: FileMetadata,
        seenFiles: inout Set<FileKey>,
        allocatedBytes: inout Int64,
        fileCount: inout Int
    ) {
        let identity = metadata.identity

        if identity.kind != .directory, metadata.linkCount > 1 {
            let key = FileKey(device: identity.device, inode: identity.inode)
            guard seenFiles.insert(key).inserted else { return }
        }

        allocatedBytes += metadata.allocatedBytes

        if identity.kind != .directory {
            fileCount += 1
        }
    }
}
