import Foundation

extension AppCopy {
    enum Core {
        static var startingScan: String { LocalizedCopy.text("core.starting-scan") }
        static func localSnapshots(_ count: Int) -> String {
            LocalizedCopy.format("core.local-snapshots \(count)")
        }
        static var localSnapshotsMessage: String {
            LocalizedCopy.text("core.local-snapshots-message")
        }
        static func cacheTitle(_ name: String) -> String {
            LocalizedCopy.format("core.cache-title \(name)")
        }
        static var simulatorDevice: String {
            LocalizedCopy.text("core.simulator-device")
        }
        static func simulatorRuntime(name: String, runtime: String) -> String {
            LocalizedCopy.format("core.simulator-runtime \(name) \(runtime)")
        }
        static var storedFiles: String { LocalizedCopy.text("core.stored-files") }
        static var homeFolder: String { LocalizedCopy.text("core.home-folder") }
        static func homeRelativePath(_ relativePath: String) -> String {
            LocalizedCopy.format("core.home-relative-path \(relativePath)")
        }
        static var restoreAuthorizationPrompt: String {
            LocalizedCopy.text("core.restore-authorization-prompt")
        }
        static func removeAuthorizationPrompt(_ title: String) -> String {
            LocalizedCopy.format("core.remove-authorization-prompt \(title)")
        }
        static func rollbackAuthorizationPrompt(_ title: String) -> String {
            LocalizedCopy.format("core.rollback-authorization-prompt \(title)")
        }
        static func applicationName(bundleIdentifier: String, fallback: String) -> String {
            LocalizedCopy.text(
                "application.\(bundleIdentifier).name",
                fallback: fallback
            )
        }
    }

    enum Preview {
        static func text(_ key: String) -> String {
            LocalizedCopy.text("preview.\(key)")
        }
    }
}
