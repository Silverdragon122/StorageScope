import Foundation

extension CleanupCatalog {
    static let appleDevelopmentRules: [CleanupRule] = [
        rule(
            "xcode-derived-data",
            .developer,
            "Xcode build files",
            "Build files",
            "Files Xcode creates while compiling projects.",
            "Projects will rebuild these files the next time they are opened.",
            .reclaimable,
            "Library/Developer/Xcode/DerivedData",
            .children,
            .childWithSuffix("build files"),
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "xcode-previews",
            .developer,
            "Xcode previews",
            "Preview files",
            "Temporary files used to render previews.",
            "Previews may take longer to open once while these files are recreated.",
            .reclaimable,
            "Library/Developer/Xcode/UserData/Previews",
            .children,
            .child,
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "xcode-documentation-cache",
            .developer,
            "Xcode documentation",
            "Downloaded documentation",
            "Documentation stored for offline use.",
            "Removed documentation must be downloaded again before it is available offline.",
            .reviewRequired,
            "Library/Developer/Xcode/DocumentationCache",
            .children,
            .child,
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "xcode-archives",
            .developer,
            "Xcode archives",
            "Build archive",
            "Saved app archives used for distribution and crash reports.",
            "The selected archive cannot be used again for export or symbol lookup.",
            .reviewRequired,
            "Library/Developer/Xcode/Archives",
            .matchingDirectories(
                names: [],
                extensions: ["xcarchive"],
                requiredAncestorExtensions: [],
                maximumDepth: 3
            ),
            .childWithSuffix("archive"),
            .deleteItem,
            xcodeBundleIDs
        ),
        deviceSupportRule(
            id: "xcode-device-support",
            platform: "iOS",
            relativePath: "Library/Developer/Xcode/iOS DeviceSupport"
        ),
        deviceSupportRule(
            id: "xcode-watch-device-support",
            platform: "watchOS",
            relativePath: "Library/Developer/Xcode/watchOS DeviceSupport"
        ),
        deviceSupportRule(
            id: "xcode-tv-device-support",
            platform: "tvOS",
            relativePath: "Library/Developer/Xcode/tvOS DeviceSupport"
        ),
        deviceSupportRule(
            id: "xcode-vision-device-support",
            platform: "visionOS",
            relativePath: "Library/Developer/Xcode/visionOS DeviceSupport"
        ),
        deviceSupportRule(
            id: "xcode-xros-device-support",
            platform: "xrOS",
            relativePath: "Library/Developer/Xcode/xrOS DeviceSupport"
        ),
        deviceSupportRule(
            id: "xcode-mac-device-support",
            platform: "macOS",
            relativePath: "Library/Developer/Xcode/macOS DeviceSupport"
        ),
        rule(
            "xcode-device-logs",
            .developer,
            "Connected-device logs",
            "Device logs",
            "Logs and diagnostic data copied from Apple devices.",
            "The selected logs will no longer be available for device troubleshooting.",
            .reviewRequired,
            "Library/Developer/Xcode/DeviceLogs",
            .children,
            .child,
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "xcode-download-cache",
            .developer,
            "Xcode download cache",
            "Xcode cache",
            "Temporary downloads and metadata retained by Xcode.",
            "Xcode will download or recreate these files when needed.",
            .reclaimable,
            "Library/Caches/com.apple.dt.Xcode",
            .children,
            .child,
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "instruments-cache",
            .developer,
            "Instruments cache",
            "Instruments cache",
            "Temporary analysis files created by Instruments.",
            "Instruments will recreate these files when needed.",
            .reclaimable,
            "Library/Caches/com.apple.dt.Instruments",
            .children,
            .child,
            .deleteItem,
            ["com.apple.dt.Instruments"]
        ),
        rule(
            "xcode-test-devices",
            .developer,
            "Xcode test devices",
            "Test device",
            "Temporary devices created while running automated tests.",
            "Tests will recreate a device when one is needed.",
            .reclaimable,
            "Library/Developer/XCTestDevices",
            .children,
            .child,
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "simulator-devices",
            .developer,
            "Simulator devices",
            "Simulator device",
            "Apps, settings, and files stored inside one simulated device.",
            "Everything stored inside the selected simulated device will be removed.",
            .reviewRequired,
            "Library/Developer/CoreSimulator/Devices",
            .simulatorDevices,
            .simulatorDevice,
            .simulatorDevice,
            xcodeBundleIDs
        ),
        rule(
            "simulator-caches",
            .developer,
            "Simulator caches",
            "Simulator cache",
            "Temporary files created by Simulator.",
            "Simulator will recreate these files when needed.",
            .reclaimable,
            "Library/Developer/CoreSimulator/Caches",
            .children,
            .child,
            .deleteItem,
            xcodeBundleIDs
        ),
        rule(
            "swift-package-cache",
            .developer,
            "Swift package cache",
            "Swift package",
            "Downloaded package files that can be fetched again.",
            "The package will be downloaded again when a project needs it.",
            .reclaimable,
            "Library/Caches/org.swift.swiftpm",
            .children,
            .child,
            .deleteItem
        ),
        readOnlyRule(
            "xcode-coding-assistant",
            .localModels,
            "Xcode coding models",
            "Models and support data used by Xcode coding assistance.",
            "Manage downloaded components from Xcode settings.",
            .home(relativePath: "Library/Developer/Xcode/CodingAssistant"),
            .children,
            .child
        ),
        readOnlyRule(
            "xcode-products",
            .developer,
            "Installed Xcode products",
            "Products installed or registered by Xcode.",
            "Remove these products through Xcode or their owning workflow.",
            .home(relativePath: "Library/Developer/Xcode/Products"),
            .children,
            .child
        )
    ]

    private static func deviceSupportRule(
        id: String,
        platform: String,
        relativePath: String
    ) -> CleanupRule {
        rule(
            id,
            .developer,
            "\(platform) device support",
            "Device support",
            "Support files downloaded when a \(platform) device connects to Xcode.",
            "Xcode may download these files again. Older crash reports may lose symbol details.",
            .reviewRequired,
            relativePath,
            .children,
            .childWithSuffix("device support"),
            .deleteItem,
            xcodeBundleIDs
        )
    }
}
