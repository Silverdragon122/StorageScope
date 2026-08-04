import Foundation

private struct ApplicationCacheDefinition {
    let id: String
    let name: String
    let path: String
    let bundleIdentifiers: Set<String>
}

extension CleanupCatalog {
    static let applicationCacheRules: [CleanupRule] =
        electronApplicationDefinitions.map(applicationCacheRule)
        + [
            rule(
                "steam-http-cache",
                .appCaches,
                "Steam web cache",
                "Steam web cache",
                "Temporary web content retained by Steam.",
                "Steam will download these files again when needed.",
                .reclaimable,
                "Library/Application Support/Steam/appcache/httpcache",
                .location,
                .fixed,
                .deleteContents,
                ["com.valvesoftware.steam"]
            ),
            rule(
                "steam-shader-cache",
                .appCaches,
                "Steam shader caches",
                "Game shader cache",
                "Generated shaders retained to reduce stutter in games.",
                "The selected game may rebuild shaders during a later launch.",
                .reviewRequired,
                "Library/Application Support/Steam/steamapps/shadercache",
                .children,
                .childWithSuffix("shader cache"),
                .deleteItem,
                ["com.valvesoftware.steam"]
            ),
            readOnlyRule(
                "steam-incomplete-downloads",
                .largeAppData,
                "Steam downloads in progress",
                "Incomplete or paused game downloads.",
                "Resume or cancel these downloads from Steam.",
                .home(
                    relativePath: "Library/Application Support/Steam/steamapps/downloading"
                ),
                .children,
                .child
            ),
            rule(
                "container-caches",
                .appCaches,
                "App container caches",
                "App cache",
                "Temporary files kept inside an app's private storage.",
                "The app will recreate the selected files when needed.",
                .reclaimable,
                "Library/Containers",
                .nestedChildren(relativePath: "Data/Library/Caches"),
                .appCache,
                .deleteContents
            ),
            rule(
                "group-container-caches",
                .appCaches,
                "Shared app caches",
                "Shared app cache",
                "Temporary files shared by apps from the same developer.",
                "The apps will recreate the selected files when needed.",
                .reviewRequired,
                "Library/Group Containers",
                .nestedChildren(relativePath: "Library/Caches"),
                .appCache,
                .deleteContents
            ),
            rule(
                "general-app-caches",
                .appCaches,
                "Other app caches",
                "App cache",
                "Temporary files kept by an installed app.",
                "The app will recreate the selected files when needed.",
                .reviewRequired,
                "Library/Caches",
                .children,
                .appCache,
                .deleteItem
            )
        ]

    private static let electronApplicationDefinitions: [ApplicationCacheDefinition] = [
        ApplicationCacheDefinition(
            id: "slack",
            name: "Slack",
            path: "Library/Application Support/Slack",
            bundleIdentifiers: ["com.tinyspeck.slackmacgap"]
        ),
        ApplicationCacheDefinition(
            id: "discord",
            name: "Discord",
            path: "Library/Application Support/discord",
            bundleIdentifiers: ["com.hnc.Discord"]
        ),
        ApplicationCacheDefinition(
            id: "discord-ptb",
            name: "Discord PTB",
            path: "Library/Application Support/discordptb",
            bundleIdentifiers: ["com.hnc.DiscordPTB"]
        ),
        ApplicationCacheDefinition(
            id: "discord-canary",
            name: "Discord Canary",
            path: "Library/Application Support/discordcanary",
            bundleIdentifiers: ["com.hnc.DiscordCanary"]
        ),
        ApplicationCacheDefinition(
            id: "notion",
            name: "Notion",
            path: "Library/Application Support/Notion",
            bundleIdentifiers: ["notion.id"]
        ),
        ApplicationCacheDefinition(
            id: "obsidian",
            name: "Obsidian",
            path: "Library/Application Support/obsidian",
            bundleIdentifiers: ["md.obsidian"]
        ),
        ApplicationCacheDefinition(
            id: "signal",
            name: "Signal",
            path: "Library/Application Support/Signal",
            bundleIdentifiers: ["org.whispersystems.signal-desktop"]
        ),
        ApplicationCacheDefinition(
            id: "github-desktop",
            name: "GitHub Desktop",
            path: "Library/Application Support/GitHub Desktop",
            bundleIdentifiers: ["com.github.GitHubClient"]
        ),
        ApplicationCacheDefinition(
            id: "claude-desktop",
            name: "Claude",
            path: "Library/Application Support/Claude",
            bundleIdentifiers: ["com.anthropic.claudefordesktop"]
        ),
        ApplicationCacheDefinition(
            id: "postman",
            name: "Postman",
            path: "Library/Application Support/Postman",
            bundleIdentifiers: ["com.postmanlabs.mac"]
        ),
        ApplicationCacheDefinition(
            id: "figma",
            name: "Figma",
            path: "Library/Application Support/Figma",
            bundleIdentifiers: ["com.figma.Desktop"]
        ),
        ApplicationCacheDefinition(
            id: "microsoft-teams",
            name: "Microsoft Teams",
            path: "Library/Application Support/Microsoft/Teams",
            bundleIdentifiers: ["com.microsoft.teams"]
        ),
        ApplicationCacheDefinition(
            id: "linear",
            name: "Linear",
            path: "Library/Application Support/Linear",
            bundleIdentifiers: ["com.linear"]
        ),
        ApplicationCacheDefinition(
            id: "loom",
            name: "Loom",
            path: "Library/Application Support/Loom",
            bundleIdentifiers: ["com.loom.desktop"]
        )
    ]

    private static func applicationCacheRule(
        _ definition: ApplicationCacheDefinition
    ) -> CleanupRule {
        rule(
            "\(definition.id)-cache",
            .appCaches,
            "\(definition.name) cache",
            "\(definition.name) cache",
            "Temporary web, code, graphics, and shader files retained by \(definition.name).",
            "\(definition.name) will recreate the selected files when needed.",
            .reclaimable,
            definition.path,
            .matchingDirectories(
                names: [
                    "Cache",
                    "Code Cache",
                    "DawnGraphiteCache",
                    "DawnWebGPUCache",
                    "GPUCache",
                    "GraphiteDawnCache",
                    "ShaderCache"
                ],
                extensions: [],
                requiredAncestorExtensions: [],
                maximumDepth: 3
            ),
            .child,
            .deleteContents,
            definition.bundleIdentifiers
        )
    }
}
