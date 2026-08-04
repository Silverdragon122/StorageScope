import Darwin
import Foundation

enum FileNodeKind: String, Codable, Sendable {
    case regularFile
    case directory
    case symbolicLink
    case namedPipe
    case unixSocket
    case characterDevice
    case blockDevice
    case other
}

struct FileIdentity: Codable, Hashable, Sendable {
    let device: UInt64
    let inode: UInt64
    let owner: UInt32
    let kind: FileNodeKind
    let modificationSeconds: Int64
    let modificationNanoseconds: Int64

    init(
        device: UInt64,
        inode: UInt64,
        owner: UInt32,
        kind: FileNodeKind,
        modificationSeconds: Int64,
        modificationNanoseconds: Int64
    ) {
        self.device = device
        self.inode = inode
        self.owner = owner
        self.kind = kind
        self.modificationSeconds = modificationSeconds
        self.modificationNanoseconds = modificationNanoseconds
    }

    init(url: URL) throws {
        var information = stat()
        guard lstat(url.path, &information) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        self.init(information: information)
    }

    init(information: stat) {
        device = UInt64(information.st_dev)
        inode = UInt64(information.st_ino)
        owner = information.st_uid
        kind = Self.nodeKind(for: information.st_mode)
        modificationSeconds = Int64(information.st_mtimespec.tv_sec)
        modificationNanoseconds = Int64(information.st_mtimespec.tv_nsec)
    }

    private static func nodeKind(for mode: mode_t) -> FileNodeKind {
        switch mode & S_IFMT {
        case S_IFREG:
            return .regularFile
        case S_IFDIR:
            return .directory
        case S_IFLNK:
            return .symbolicLink
        case S_IFIFO:
            return .namedPipe
        case S_IFSOCK:
            return .unixSocket
        case S_IFCHR:
            return .characterDevice
        case S_IFBLK:
            return .blockDevice
        default:
            return .other
        }
    }
}
