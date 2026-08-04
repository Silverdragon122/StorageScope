import Foundation

extension CleanupCatalog {
    static let developmentEnvironmentRules: [CleanupRule] = [
        rule(
            "android-devices",
            .developer,
            "Android virtual devices",
            "Android virtual device",
            "Apps, settings, and files stored inside an Android virtual device.",
            "Everything stored inside the selected virtual device will be removed.",
            .reviewRequired,
            ".android/avd",
            .matchingDirectories(
                names: [],
                extensions: ["avd"],
                requiredAncestorExtensions: [],
                maximumDepth: 1
            ),
            .child,
            .deleteItem,
            ["com.google.android.studio"]
        ),
        rule(
            "android-download-cache",
            .developer,
            "Android tool downloads",
            "Android download",
            "Temporary downloads retained by Android development tools.",
            "Android tools will download the selected files again when needed.",
            .reclaimable,
            ".android/cache",
            .children,
            .child,
            .deleteItem,
            ["com.google.android.studio"]
        ),
        rule(
            "jetbrains-cache",
            .developer,
            "JetBrains caches",
            "IDE cache",
            "Indexes and temporary files created by JetBrains apps.",
            "The app will rebuild indexes after the selected cache is removed.",
            .reclaimable,
            "Library/Caches/JetBrains",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "jetbrains-logs",
            .logsAndTemporary,
            "JetBrains logs",
            "IDE logs",
            "Logs and thread dumps written by JetBrains apps.",
            "The selected logs will no longer be available for troubleshooting.",
            .reclaimable,
            "Library/Logs/JetBrains",
            .children,
            .child,
            .deleteItem
        ),
        editorCacheRule(
            "vscode-cache",
            name: "Visual Studio Code cache",
            path: "Library/Application Support/Code",
            bundleIdentifiers: ["com.microsoft.VSCode"]
        ),
        editorCacheRule(
            "vscode-insiders-cache",
            name: "Visual Studio Code Insiders cache",
            path: "Library/Application Support/Code - Insiders",
            bundleIdentifiers: ["com.microsoft.VSCodeInsiders"]
        ),
        editorCacheRule(
            "vscodium-cache",
            name: "VSCodium cache",
            path: "Library/Application Support/VSCodium",
            bundleIdentifiers: ["com.vscodium"]
        ),
        editorCacheRule(
            "cursor-cache",
            name: "Cursor cache",
            path: "Library/Application Support/Cursor",
            bundleIdentifiers: ["com.todesktop.230313mzl4w4u92"]
        ),
        editorCacheRule(
            "windsurf-cache",
            name: "Windsurf cache",
            path: "Library/Application Support/Windsurf",
            bundleIdentifiers: ["com.exafunction.windsurf"]
        ),
        rule(
            "zed-cache",
            .developer,
            "Zed cache",
            "Zed cache",
            "Temporary files and indexes created by Zed.",
            "Zed will recreate the selected files when needed.",
            .reclaimable,
            "Library/Caches/dev.zed.Zed",
            .children,
            .child,
            .deleteItem,
            ["dev.zed.Zed"]
        ),
        rule(
            "visual-studio-mac-cache",
            .developer,
            "Visual Studio for Mac cache",
            "IDE cache",
            "Indexes and temporary files created by Visual Studio for Mac.",
            "The editor will rebuild the selected files when needed.",
            .reclaimable,
            "Library/Caches/VisualStudio",
            .children,
            .child,
            .deleteItem,
            ["com.microsoft.visual-studio"]
        ),
        rule(
            "xamarin-cache",
            .developer,
            "Xamarin cache",
            "Xamarin cache",
            "Downloaded and generated files retained by Xamarin tools.",
            "Xamarin tools will recreate or download the selected files when needed.",
            .reclaimable,
            "Library/Caches/Xamarin",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "cmake-tools-cache",
            .developer,
            "CMake Tools cache",
            "CMake cache",
            "Generated metadata retained by CMake editor integrations.",
            "The integration will recreate these files when needed.",
            .reviewRequired,
            ".local/share/CMakeTools",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "codex-runtime-cache",
            .developer,
            "Codex runtimes",
            "Codex runtime",
            "Downloaded support runtimes used by Codex tools.",
            "Codex will download the selected runtime again when needed.",
            .reviewRequired,
            ".cache/codex-runtimes",
            .children,
            .child,
            .deleteItem,
            ["com.openai.codex"]
        ),
        rule(
            "claude-cli-cache",
            .developer,
            "Claude Code cache",
            "Claude Code cache",
            "Temporary files retained by Claude Code.",
            "Claude Code will recreate these files when needed.",
            .reclaimable,
            "Library/Caches/claude-cli-nodejs",
            .children,
            .child,
            .deleteItem
        ),
        readOnlyRule(
            "kotlin-native-data",
            .developer,
            "Kotlin Native toolchains",
            "Compiler distributions and dependencies installed by Kotlin Native.",
            "Remove versions with Kotlin-aware tooling.",
            .home(relativePath: ".konan"),
            .children,
            .child
        ),
        readOnlyRule(
            "expo-data",
            .developer,
            "Expo developer data",
            "Project state, device records, and downloads retained by Expo.",
            "Manage this data with Expo tools to preserve project and account state.",
            .home(relativePath: ".expo"),
            .children,
            .child
        )
    ]

    private static func editorCacheRule(
        _ id: String,
        name: String,
        path: String,
        bundleIdentifiers: Set<String>
    ) -> CleanupRule {
        rule(
            id,
            .developer,
            name,
            "Editor cache",
            "Temporary editor data, indexes, logs, and downloaded update files.",
            "The editor will recreate the selected files when needed.",
            .reclaimable,
            path,
            .matchingDirectories(
                names: [
                    "Cache",
                    "CachedData",
                    "CachedExtensionVSIXs",
                    "Code Cache",
                    "DawnGraphiteCache",
                    "DawnWebGPUCache",
                    "GPUCache",
                    "GraphiteDawnCache",
                    "ShaderCache",
                    "logs"
                ],
                extensions: [],
                requiredAncestorExtensions: [],
                maximumDepth: 3
            ),
            .child,
            .deleteContents,
            bundleIdentifiers
        )
    }
}
