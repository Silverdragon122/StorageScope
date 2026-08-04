import Foundation

enum StorageFormatting {
    static func size(_ bytes: Int64) -> String {
        bytes.formatted(
            .byteCount(
                style: .file,
                allowedUnits: [.kb, .mb, .gb, .tb],
                spellsOutZero: true,
                includesActualByteCount: false
            )
        )
    }

    static func abbreviatedPath(_ url: URL) -> String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path == homePath {
            return AppCopy.Core.homeFolder
        }
        if url.path.hasPrefix(homePath + "/") {
            return AppCopy.Core.homeRelativePath(
                String(url.path.dropFirst(homePath.count + 1))
            )
        }
        return url.path
    }
}
