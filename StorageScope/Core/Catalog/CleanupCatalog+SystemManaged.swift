import Foundation

extension CleanupCatalog {
    static let systemManagedRules: [CleanupRule] = [
        readOnlyRule(
            "apple-update-assets",
            .systemManaged,
            "macOS managed assets",
            "Updates, language resources, voices, models, and other assets managed by macOS.",
            "Use supported macOS settings; these protected files must not be removed manually.",
            .absolute(path: "/System/Volumes/Data/System/Library/AssetsV2"),
            .children,
            .child
        ),
        readOnlyRule(
            "preboot-data",
            .systemManaged,
            "Startup support files",
            "Files required to start macOS, FileVault, and system updates.",
            "macOS manages this storage. It must not be removed manually.",
            .absolute(path: "/System/Volumes/Preboot"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "recovery-data",
            .systemManaged,
            "Recovery files",
            "Tools used to repair or reinstall macOS.",
            "macOS manages this storage. It must not be removed manually.",
            .absolute(path: "/System/Volumes/Recovery"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "swap-data",
            .systemManaged,
            "Memory swap",
            "Disk space macOS uses when applications need more memory.",
            "macOS adjusts this storage automatically.",
            .absolute(path: "/private/var/vm"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "temporary-system-data",
            .systemManaged,
            "Current-user temporary data",
            "Temporary and cache files shared by this user's macOS processes.",
            "macOS manages this storage and removes files when appropriate.",
            .userTemporaryRoot,
            .location,
            .fixed
        ),
        readOnlyRule(
            "simulator-runtimes",
            .systemManaged,
            "Legacy Simulator runtimes",
            "Installed operating systems used by older Simulator versions.",
            "Remove runtimes from Xcode Settings.",
            .absolute(path: "/Library/Developer/CoreSimulator/Profiles/Runtimes"),
            .children,
            .child
        ),
        readOnlyRule(
            "simulator-runtime-volumes",
            .systemManaged,
            "Simulator runtime volumes",
            "Mounted or installed Simulator operating-system runtime volumes.",
            "Remove runtimes from Xcode Settings.",
            .absolute(path: "/Library/Developer/CoreSimulator/Volumes"),
            .children,
            .child
        ),
        readOnlyRule(
            "simulator-runtime-images",
            .systemManaged,
            "Simulator runtime images",
            "Downloaded and staged Simulator operating-system images.",
            "Finish or remove runtime downloads from Xcode Settings.",
            .absolute(path: "/Library/Developer/CoreSimulator/Images"),
            .children,
            .child
        ),
        readOnlyRule(
            "simulator-cryptex-data",
            .systemManaged,
            "Simulator cryptex data",
            "Protected runtime images and personalization data used by Simulator.",
            "Manage installed runtimes from Xcode Settings.",
            .absolute(path: "/Library/Developer/CoreSimulator/Cryptex"),
            .children,
            .child
        ),
        readOnlyRule(
            "core-device-support-images",
            .systemManaged,
            "Apple device support images",
            "Developer disk images used to communicate with physical Apple devices.",
            "Manage installed platform support from Xcode.",
            .absolute(path: "/Library/Developer/DeveloperDiskImages"),
            .children,
            .child
        ),
        readOnlyRule(
            "core-device-candidate-images",
            .systemManaged,
            "Staged Apple device support",
            "Candidate developer disk images staged for connected devices.",
            "Xcode and macOS manage these files.",
            .absolute(path: "/Library/Developer/CoreDevice/CandidateDDIs"),
            .children,
            .child
        ),
        readOnlyRule(
            "software-update-downloads",
            .systemManaged,
            "Software update downloads",
            "Downloaded packages retained for macOS and other Apple software updates.",
            "Finish or cancel updates from System Settings.",
            .absolute(path: "/Library/Updates"),
            .children,
            .child
        ),
        readOnlyRule(
            "apfs-update-volume",
            .systemManaged,
            "System update staging volume",
            "Files staged on the APFS Update volume for an operating-system update.",
            "Finish or cancel the update from System Settings.",
            .absolute(path: "/System/Volumes/Update"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "software-update-state",
            .systemManaged,
            "Software update state",
            "Update catalogs, download state, and installation records managed by macOS.",
            "Use Software Update in System Settings.",
            .absolute(path: "/private/var/db/softwareupdate"),
            .children,
            .child
        ),
        readOnlyRule(
            "macos-install-data",
            .systemManaged,
            "macOS installation data",
            "Files staged for an in-progress or interrupted macOS installation.",
            "Finish or cancel the installer through supported macOS controls.",
            .absolute(path: "/System/Volumes/Data/macOS Install Data"),
            .children,
            .child
        ),
        readOnlyRule(
            "content-caching-data",
            .systemManaged,
            "Apple content cache",
            "Apps, updates, and iCloud content cached for Apple devices on the network.",
            "Reset or resize this cache from Content Caching settings.",
            .absolute(path: "/Library/Application Support/Apple/AssetCache/Data"),
            .location,
            .fixed
        ),
        warnedSystemRule(
            "system-library-caches",
            "System-wide caches",
            "Caches shared by apps, services, and all users.",
            "Quit the owning app or service first. Removed cache data may be recreated.",
            "/Library/Caches",
            .children,
            .appCache
        ),
        warnedSystemRule(
            "system-library-logs",
            "System-wide logs",
            "Diagnostic records written for apps and services across user accounts.",
            "Only remove logs you no longer need for troubleshooting.",
            "/Library/Logs",
            .children,
            .child
        ),
        readOnlyRule(
            "private-system-logs",
            .systemManaged,
            "Runtime system logs",
            "Logs written by low-level macOS services.",
            "macOS rotates and manages these logs.",
            .absolute(path: "/private/var/log"),
            .children,
            .child
        ),
        readOnlyRule(
            "system-temporary-files",
            .systemManaged,
            "System temporary files",
            "Temporary files that can outlive a restart or belong to system services.",
            "macOS and the owning services manage these files.",
            .absolute(path: "/private/var/tmp"),
            .children,
            .child
        ),
        readOnlyRule(
            "shared-temporary-files",
            .systemManaged,
            "Shared temporary files",
            "Short-lived files shared through the system temporary directory.",
            "macOS and the owning apps manage these files.",
            .absolute(path: "/private/tmp"),
            .children,
            .child
        ),
        readOnlyRule(
            "system-cache-buckets",
            .systemManaged,
            "macOS cache and temporary buckets",
            "Per-user and per-service caches and temporary files under var folders.",
            "macOS manages these locations; permission-limited buckets are expected.",
            .absolute(path: "/private/var/folders"),
            .children,
            .child
        ),
        readOnlyRule(
            "unified-log-data",
            .systemManaged,
            "Unified logging data",
            "Compressed trace and string data used by Console and diagnostic tools.",
            "macOS applies retention policies to this storage.",
            .absolute(path: "/private/var/db/diagnostics"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "unified-log-text",
            .systemManaged,
            "Unified log text data",
            "Text mappings used to decode unified logging records.",
            "macOS manages this storage with the unified logging system.",
            .absolute(path: "/private/var/db/uuidtext"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "spotlight-index",
            .systemManaged,
            "Spotlight index",
            "Search indexes and metadata maintained for the startup data volume.",
            "Manage Spotlight privacy settings and allow macOS to maintain the index.",
            .absolute(path: "/System/Volumes/Data/.Spotlight-V100"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "document-revisions",
            .systemManaged,
            "Document version history",
            "Autosaved historical versions used by macOS document restoration.",
            "Manage documents from their apps; do not remove this database manually.",
            .absolute(path: "/System/Volumes/Data/.DocumentRevisions-V100"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "apple-model-catalog",
            .systemManaged,
            "Apple model catalog",
            "Catalog and state for machine-learning models managed by macOS.",
            "Manage Apple Intelligence and language features from System Settings.",
            .absolute(path: "/private/var/db/com.apple.modelcatalog"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "apple-model-manager",
            .systemManaged,
            "Apple managed models",
            "Downloaded machine-learning models and model-manager state.",
            "macOS downloads and removes these models as features require them.",
            .absolute(path: "/private/var/db/modelmanagerd"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "apple-intelligence-platform",
            .systemManaged,
            "Apple Intelligence data",
            "System-managed models, assets, and runtime state for Apple Intelligence.",
            "Manage Apple Intelligence from System Settings.",
            .absolute(path: "/private/var/db/AppleIntelligencePlatform"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "coreml-system-data",
            .systemManaged,
            "Core ML system data",
            "Compiled models, caches, and runtime support managed by Core ML.",
            "macOS manages this data automatically.",
            .absolute(path: "/private/var/db/coreml"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "neural-engine-system-data",
            .systemManaged,
            "Neural Engine data",
            "System-managed compilation and runtime data for the Neural Engine.",
            "macOS manages this data automatically.",
            .absolute(path: "/private/var/db/neuralengine"),
            .location,
            .fixed
        ),
        readOnlyRule(
            "system-developer-data",
            .systemManaged,
            "System-wide developer support",
            "Command-line tools, device support, Simulator components, and shared developer data.",
            "Manage installed developer components from Xcode or the official installer.",
            .absolute(path: "/Library/Developer"),
            .children,
            .child
        ),
        warnedSystemRule(
            "adobe-system-support",
            "Adobe system support",
            "Shared Adobe downloads, components, databases, licensing support, and installed-app resources.",
            "Only remove this after uninstalling every Adobe app you no longer use. Installed Adobe apps may stop launching or require repair.",
            "/Library/Application Support/Adobe",
            .location,
            .fixed
        ),
        readOnlyRule(
            "system-application-support",
            .systemManaged,
            "System-wide app support",
            "Shared app data, downloaded content, databases, and support files.",
            "Manage this data from the owning app or macOS feature.",
            .absolute(path: "/Library/Application Support"),
            .children,
            .child
        ),
        warnedSystemRule(
            "core-dumps",
            "Core dumps",
            "Process memory dumps created after low-level crashes.",
            "Keep dumps still needed for debugging. Removed crash memory cannot be recovered.",
            "/cores",
            .children,
            .child
        )
    ]

    private static func warnedSystemRule(
        _ id: String,
        _ name: String,
        _ detail: String,
        _ consequence: String,
        _ absolutePath: String,
        _ source: CandidateSource,
        _ nameStyle: ItemNameStyle
    ) -> CleanupRule {
        CleanupRule(
            id: id,
            category: .systemManaged,
            locationName: name,
            itemTitle: name,
            itemDetail: detail,
            consequence: consequence,
            safety: .reviewRequired,
            location: .absolute(path: absolutePath),
            source: source,
            nameStyle: nameStyle,
            cleanupAction: .deleteItem,
            blockedBundleIdentifiers: []
        )
    }
}
