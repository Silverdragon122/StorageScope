import Foundation

extension CleanupCatalog {
    /// Additional app-specific rules whose locations are documented by the
    /// owning vendor or project. Keep these narrower than the generic cache
    /// rules so the results explain what the user is looking at.
    static let expandedApplicationCacheRules: [CleanupRule] = [
        rule(
            "zoom-app-cache",
            .appCaches,
            "Zoom app cache",
            "Zoom cache",
            "Temporary Zoom app data used for web content and Zoom Apps.",
            "Zoom will rebuild this cache. Zoom Apps may require sign-in again.",
            .reviewRequired,
            "Library/Application Support/zoom.us/data",
            .location,
            .fixed,
            .deleteContents,
            ["us.zoom.xos"]
        ),
        rule(
            "epic-games-launcher-cache",
            .appCaches,
            "Epic Games Launcher cache",
            "Launcher web cache",
            "Web content cached by the Epic Games Launcher.",
            "The launcher will download this web content again when needed.",
            .reclaimable,
            "Library/Caches/com.epicgames.EpicGamesLauncher",
            .matchingDirectories(
                names: ["webcache", "webcache_4147", "webcache_4430"],
                extensions: [],
                requiredAncestorExtensions: [],
                maximumDepth: 1
            ),
            .child,
            .deleteItem,
            ["com.epicgames.EpicGamesLauncher"]
        ),
        rule(
            "godot-cache",
            .developer,
            "Godot editor cache",
            "Godot cache",
            "Temporary editor data such as generated resource thumbnails.",
            "Godot will recreate the selected cache files when needed.",
            .reclaimable,
            "Library/Caches/Godot",
            .children,
            .child,
            .deleteItem,
            ["org.godotengine.godot"]
        ),
        rule(
            "microsoft-teams-new-cache",
            .appCaches,
            "Microsoft Teams cache",
            "Teams cache",
            "Temporary cache files used by the current Microsoft Teams client.",
            "Teams will rebuild the selected cache files and may take longer to start once.",
            .reclaimable,
            "Library/Containers/com.microsoft.teams2/Data/Library/Caches",
            .children,
            .child,
            .deleteItem,
            ["com.microsoft.teams2"]
        ),
        rule(
            "dropbox-cache-folders",
            .appCaches,
            "Dropbox cache folders",
            "Dropbox cache",
            "Temporary upload and download files in folders named exactly .dropbox.cache.",
            "Dropbox may need to download or stage files again. The Dropbox app must be closed first.",
            .reviewRequired,
            "",
            .matchingDirectories(
                names: [".dropbox.cache"],
                extensions: [],
                requiredAncestorExtensions: [],
                maximumDepth: 4
            ),
            .child,
            .deleteContents,
            ["com.getdropbox.dropbox"]
        )
    ]

    static let expandedCreativeRules: [CleanupRule] = [
        rule(
            "ableton-pack-downloads",
            .creative,
            "Ableton Live Pack downloads",
            "Pack download",
            "Downloaded installer packages for Ableton Live Packs.",
            "Installed Packs remain available; a Pack not yet installed must be downloaded again.",
            .reclaimable,
            "Library/Caches/Ableton/PackDownloads",
            .children,
            .child,
            .deleteItem,
            ["com.ableton.live"]
        ),
        rule(
            "obs-logs",
            .logsAndTemporary,
            "OBS Studio logs",
            "OBS log",
            "Diagnostic logs written by OBS Studio sessions.",
            "The selected logs will no longer be available for troubleshooting.",
            .reclaimable,
            "Library/Application Support/obs-studio/logs",
            .children,
            .child,
            .deleteItem,
            ["com.obsproject.obs-studio"]
        ),
        rule(
            "obs-crash-reports",
            .logsAndTemporary,
            "OBS Studio crash reports",
            "OBS crash report",
            "Crash reports created by OBS Studio.",
            "The selected crash reports will no longer be available for troubleshooting.",
            .reclaimable,
            "Library/Application Support/obs-studio/crashes",
            .children,
            .child,
            .deleteItem,
            ["com.obsproject.obs-studio"]
        ),
        readOnlyRule(
            "audacity-session-data",
            .creative,
            "Audacity unsaved session data",
            "Temporary audio for unsaved Audacity sessions.",
            "Open Audacity and confirm the sessions are no longer needed before removing this data.",
            .home(relativePath: "Library/Application Support/SessionData"),
            .children,
            .child
        ),
        readOnlyRule(
            "krita-resource-data",
            .creative,
            "Krita resources and cache database",
            "Brushes, resources, tags, and the database Krita uses to index them.",
            "Manage resources from Krita; removing this folder can discard resource metadata and custom content.",
            .home(relativePath: "Library/Application Support/Krita"),
            .location,
            .fixed
        )
    ]

    static let expandedDeveloperRules: [CleanupRule] = [
        rule(
            "terraform-plugin-cache",
            .developer,
            "Terraform provider plugin cache",
            "Terraform provider",
            "Provider binaries downloaded into Terraform's shared plugin cache.",
            "Terraform will download a selected provider again. Use Terraform-aware cleanup when possible.",
            .reviewRequired,
            ".terraform.d/plugin-cache",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "pulumi-plugin-cache",
            .developer,
            "Pulumi plugin cache",
            "Pulumi plugin",
            "Provider and language plugins downloaded by Pulumi.",
            "Pulumi will download a selected plugin again when a stack needs it.",
            .reviewRequired,
            ".pulumi/plugins",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "dart-pub-cache",
            .developer,
            "Dart and Flutter package cache",
            "Dart package",
            "Packages downloaded into Dart's shared PUB_CACHE for Dart and Flutter projects.",
            "Dart or Flutter will download packages again; globally activated tools may need to be activated again.",
            .reviewRequired,
            ".pub-cache",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "julia-compiled-cache",
            .developer,
            "Julia compiled package cache",
            "Julia compiled cache",
            "Precompiled Julia package images generated for faster startup.",
            "Julia will compile the selected package again when it is used.",
            .reclaimable,
            ".julia/compiled",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "elixir-native-build-cache",
            .developer,
            "Elixir native build cache",
            "Native build cache",
            "Downloaded native release archives reused by Elixir build tooling.",
            "Elixir tooling will download or rebuild the selected native artifact when needed.",
            .reclaimable,
            "Library/Caches/elixir_make",
            .children,
            .child,
            .deleteItem
        )
    ]

    static let expandedBrowserRules: [CleanupRule] = [
        readOnlyRule(
            "safari-technology-preview-website-data",
            .browsers,
            "Safari Technology Preview website data",
            "Cookies, service-worker data, local storage, and other website data used by Safari Technology Preview.",
            "Manage this data from Safari Technology Preview to avoid losing website sessions or local content.",
            .home(
                relativePath: "Library/Containers/com.apple.SafariTechnologyPreview/Data/Library/WebKit/WebsiteData"
            ),
            .location,
            .fixed
        )
    ]

    static let expandedProtectedDataRules: [CleanupRule] = [
        readOnlyRule(
            "google-drivefs-data",
            .largeAppData,
            "Google Drive for desktop data",
            "Offline files, content cache, account state, and metadata used by Google Drive for desktop.",
            "Use Google Drive for desktop's offline and streaming controls; do not remove this data directly.",
            .home(relativePath: "Library/Application Support/Google/DriveFS"),
            .location,
            .fixed
        )
    ]
}
