import Darwin
import Foundation

enum FullDiskAccessStatus: String, Codable, Equatable, Sendable {
    case granted
    case denied
    case unknown
}

struct FullDiskAccessProbe {
    private let homeURL: URL
    private let accessProtectedLocation: @Sendable (URL) throws -> Void

    init(
        homeURL: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.homeURL = homeURL.standardizedFileURL
        self.accessProtectedLocation = Self.accessLiveProtectedLocation
    }

    init(
        homeURL: URL,
        accessProtectedLocation:
            @escaping @Sendable (URL) throws -> Void
    ) {
        self.homeURL = homeURL.standardizedFileURL
        self.accessProtectedLocation = accessProtectedLocation
    }

    func status() -> FullDiskAccessStatus {
        for url in protectedProbeURLs {
            do {
                try accessProtectedLocation(url)
                return .granted
            } catch {
                if isPermissionDenied(error) {
                    // One protected location is enough to establish that Full
                    // Disk Access is off. Do not continue into other private
                    // folders, because macOS may ask about each one separately.
                    return .denied
                }
            }
        }

        return .unknown
    }

    private var protectedProbeURLs: [URL] {
        [
            homeURL.appendingPathComponent(
                "Library/Application Support/com.apple.TCC/TCC.db",
                isDirectory: false
            ),
            homeURL.appendingPathComponent(
                "Library/Mail",
                isDirectory: true
            ),
            homeURL.appendingPathComponent(
                "Library/Safari",
                isDirectory: true
            )
        ]
    }

    private static func accessLiveProtectedLocation(_ url: URL) throws {
        if url.pathExtension == "db" {
            let handle = try FileHandle(forReadingFrom: url)
            try? handle.close()
        } else {
            _ = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        }
    }

    private func isPermissionDenied(_ error: Error) -> Bool {
        let nsError = error as NSError
        if
            nsError.domain == NSCocoaErrorDomain,
            nsError.code == CocoaError.fileReadNoPermission.rawValue
        {
            return true
        }
        return
            nsError.domain == NSPOSIXErrorDomain
            && (nsError.code == Int(EACCES) || nsError.code == Int(EPERM))
    }
}
