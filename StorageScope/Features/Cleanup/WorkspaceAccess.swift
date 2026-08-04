import AppKit
import Foundation

struct CleanupApplication: Identifiable, Hashable {
    let bundleIdentifier: String
    let name: String

    var id: String { bundleIdentifier }
}

@MainActor
protocol WorkspaceProviding: AnyObject {
    func activeBundleIdentifiers() -> Set<String>
    func applications(
        withBundleIdentifiers bundleIdentifiers: Set<String>
    ) -> [CleanupApplication]
    func requestTermination(
        ofApplicationsWithBundleIdentifiers bundleIdentifiers: Set<String>
    )
    func forceTermination(
        ofApplicationsWithBundleIdentifiers bundleIdentifiers: Set<String>
    )
    func reveal(_ url: URL)
    func openPrivacySettings()
}

@MainActor
final class WorkspaceAccess: WorkspaceProviding {
    func activeBundleIdentifiers() -> Set<String> {
        Set(
            NSWorkspace.shared.runningApplications.compactMap(
                \.bundleIdentifier
            )
        )
    }

    func applications(
        withBundleIdentifiers bundleIdentifiers: Set<String>
    ) -> [CleanupApplication] {
        let applications = NSWorkspace.shared.runningApplications.reduce(
            into: [String: CleanupApplication]()
        ) { result, application in
            guard
                let bundleIdentifier = application.bundleIdentifier,
                bundleIdentifiers.contains(bundleIdentifier)
            else {
                return
            }

            result[bundleIdentifier] = CleanupApplication(
                bundleIdentifier: bundleIdentifier,
                name: application.localizedName ?? bundleIdentifier
            )
        }

        let resolvedApplications = bundleIdentifiers.map { bundleIdentifier in
            applications[bundleIdentifier] ?? CleanupApplication(
                bundleIdentifier: bundleIdentifier,
                name: bundleIdentifier
            )
        }

        return resolvedApplications.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func requestTermination(
        ofApplicationsWithBundleIdentifiers bundleIdentifiers: Set<String>
    ) {
        for application in NSWorkspace.shared.runningApplications {
            guard
                let bundleIdentifier = application.bundleIdentifier,
                bundleIdentifiers.contains(bundleIdentifier)
            else {
                continue
            }
            application.terminate()
        }
    }

    func forceTermination(
        ofApplicationsWithBundleIdentifiers bundleIdentifiers: Set<String>
    ) {
        for application in NSWorkspace.shared.runningApplications {
            guard
                let bundleIdentifier = application.bundleIdentifier,
                bundleIdentifiers.contains(bundleIdentifier)
            else {
                continue
            }
            application.forceTerminate()
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openPrivacySettings() {
        guard
            let url = URL(
                string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
            )
        else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
