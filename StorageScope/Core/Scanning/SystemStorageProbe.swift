import Foundation

struct SystemStorageRecord: Equatable, Sendable {
    let ruleID: String
    let url: URL
    let allocatedBytes: Int64
}

struct SystemStorageProbeResult: Equatable, Sendable {
    let records: [SystemStorageRecord]
    let notices: [ScanNotice]
}

protocol SystemStorageProbing: Sendable {
    func inspect() async -> SystemStorageProbeResult
}

struct LiveSystemStorageProbe: SystemStorageProbing {
    func inspect() async -> SystemStorageProbeResult {
        let recordsTask = Task.detached(priority: .utility) {
            Self.apfsVolumeRecords()
        }
        let noticesTask = Task.detached(priority: .utility) {
            Self.localSnapshotNotices()
        }
        let records = await recordsTask.value
        let notices = await noticesTask.value
        return SystemStorageProbeResult(records: records, notices: notices)
    }

    private static func apfsVolumeRecords() -> [SystemStorageRecord] {
        guard
            let infoData = run(
                executablePath: "/usr/sbin/diskutil",
                arguments: ["info", "-plist", "/"]
            ),
            let info = propertyListDictionary(from: infoData),
            let containerReference = info["APFSContainerReference"] as? String,
            isDiskIdentifier(containerReference),
            let listData = run(
                executablePath: "/usr/sbin/diskutil",
                arguments: ["apfs", "list", "-plist", containerReference]
            ),
            let list = propertyListDictionary(from: listData),
            let containers = list["Containers"] as? [[String: Any]],
            let container = containers.first(where: {
                $0["ContainerReference"] as? String == containerReference
            }),
            let volumes = container["Volumes"] as? [[String: Any]]
        else {
            return []
        }

        let mappings: [String: (ruleID: String, path: String)] = [
            "Preboot": ("preboot-data", "/System/Volumes/Preboot"),
            "Recovery": ("recovery-data", "/System/Volumes/Recovery"),
            "Update": ("apfs-update-volume", "/System/Volumes/Update"),
            "VM": ("swap-data", "/private/var/vm")
        ]

        return volumes.compactMap { volume in
            guard
                let roles = volume["Roles"] as? [String],
                let role = roles.first(where: { mappings[$0] != nil }),
                let mapping = mappings[role],
                let capacity = number(from: volume["CapacityInUse"]),
                capacity > 0
            else {
                return nil
            }

            return SystemStorageRecord(
                ruleID: mapping.ruleID,
                url: URL(fileURLWithPath: mapping.path, isDirectory: true),
                allocatedBytes: capacity
            )
        }
    }

    private static func localSnapshotNotices() -> [ScanNotice] {
        guard
            let output = run(
                executablePath: "/usr/bin/tmutil",
                arguments: ["listlocalsnapshots", "/"]
            ),
            let text = String(data: output, encoding: .utf8)
        else {
            return []
        }

        let snapshotCount = text
            .split(whereSeparator: \.isNewline)
            .count { $0.contains("com.apple.TimeMachine.") }
        guard snapshotCount > 0 else { return [] }

        return [
            ScanNotice(
                id: "local-backup-snapshots",
                title: AppCopy.Core.localSnapshots(snapshotCount),
                message: AppCopy.Core.localSnapshotsMessage
            )
        ]
    }

    private static func run(
        executablePath: String,
        arguments: [String]
    ) -> Data? {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            return nil
        }

        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return data
        } catch {
            return nil
        }
    }

    private static func propertyListDictionary(
        from data: Data
    ) -> [String: Any]? {
        guard
            let propertyList = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
        else {
            return nil
        }
        return propertyList as? [String: Any]
    }

    private static func isDiskIdentifier(_ value: String) -> Bool {
        guard value.hasPrefix("disk") else { return false }
        let suffix = value.dropFirst(4)
        return !suffix.isEmpty && suffix.allSatisfy(\.isNumber)
    }

    private static func number(from value: Any?) -> Int64? {
        switch value {
        case let value as Int64:
            value
        case let value as Int:
            Int64(value)
        case let value as NSNumber:
            value.int64Value
        default:
            nil
        }
    }
}
