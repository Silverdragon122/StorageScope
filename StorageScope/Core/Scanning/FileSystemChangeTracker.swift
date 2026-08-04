import CoreServices
import Foundation

struct FileSystemChangeSet: Equatable, Sendable {
    let changedPaths: Set<String>
    let requiresFullScan: Bool
}

protocol FileSystemChangeTracking: Sendable {
    func currentEventID() -> UInt64

    func changes(
        since eventID: UInt64,
        watching paths: [String]
    ) async -> FileSystemChangeSet
}

struct LiveFileSystemChangeTracker: FileSystemChangeTracking {
    func currentEventID() -> UInt64 {
        FSEventsGetCurrentEventId()
    }

    func changes(
        since eventID: UInt64,
        watching paths: [String]
    ) async -> FileSystemChangeSet {
        guard eventID > 0, !paths.isEmpty else {
            return FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: true
            )
        }

        let collector = FileSystemEventCollector()
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(collector).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagUseCFTypes
                | kFSEventStreamCreateFlagNoDefer
                | kFSEventStreamCreateFlagWatchRoot
                | kFSEventStreamCreateFlagFileEvents
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fileSystemEventCallback,
            &context,
            paths as CFArray,
            eventID,
            0,
            flags
        ) else {
            return FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: true
            )
        }

        let queue = DispatchQueue(
            label: "StorageScope.FileSystemChangeTracker.history",
            qos: .utility
        )
        FSEventStreamSetDispatchQueue(stream, queue)

        guard FSEventStreamStart(stream) else {
            FSEventStreamInvalidate(stream)
            return FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: true
            )
        }

        FSEventStreamFlushSync(stream)
        let receivedHistory = collector.waitForHistory()
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)

        guard receivedHistory else {
            return FileSystemChangeSet(
                changedPaths: [],
                requiresFullScan: true
            )
        }
        return collector.result
    }
}

// FSEvents invokes this reference from its dispatch queue. Every mutable field
// is accessed under `lock`; the semaphore is used only to signal completion.
private final class FileSystemEventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private let historySemaphore = DispatchSemaphore(value: 0)
    private var changedPaths: Set<String> = []
    private var requiresFullScan = false
    private var receivedHistory = false

    func receive(
        paths: [String],
        flags: UnsafePointer<FSEventStreamEventFlags>,
        count: Int
    ) {
        lock.lock()
        defer { lock.unlock() }

        for index in 0..<count {
            let eventFlags = flags[index]
            if eventFlags & FSEventStreamEventFlags(
                kFSEventStreamEventFlagHistoryDone
            ) != 0 {
                if !receivedHistory {
                    receivedHistory = true
                    historySemaphore.signal()
                }
                continue
            }

            if eventFlags & FSEventStreamEventFlags(
                kFSEventStreamEventFlagMustScanSubDirs
                    | kFSEventStreamEventFlagUserDropped
                    | kFSEventStreamEventFlagKernelDropped
                    | kFSEventStreamEventFlagEventIdsWrapped
                    | kFSEventStreamEventFlagRootChanged
            ) != 0 {
                requiresFullScan = true
            }

            if paths.indices.contains(index) {
                changedPaths.insert(
                    URL(fileURLWithPath: paths[index]).standardizedFileURL.path
                )
            }
        }
    }

    func waitForHistory() -> Bool {
        if lock.withLock({ receivedHistory }) {
            return true
        }
        return historySemaphore.wait(timeout: .now() + 2) == .success
    }

    var result: FileSystemChangeSet {
        lock.withLock {
            FileSystemChangeSet(
                changedPaths: changedPaths,
                requiresFullScan: requiresFullScan
            )
        }
    }
}

private func fileSystemEventCallback(
    _ stream: ConstFSEventStreamRef,
    _ context: UnsafeMutableRawPointer?,
    _ eventCount: Int,
    _ eventPaths: UnsafeMutableRawPointer,
    _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    _ eventIDs: UnsafePointer<FSEventStreamEventId>
) {
    guard let context else { return }
    let collector = Unmanaged<FileSystemEventCollector>
        .fromOpaque(context)
        .takeUnretainedValue()
    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
    collector.receive(paths: paths, flags: eventFlags, count: eventCount)
}
