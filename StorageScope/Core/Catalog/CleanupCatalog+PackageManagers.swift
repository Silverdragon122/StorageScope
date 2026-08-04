import Foundation

extension CleanupCatalog {
    static let developerToolRules: [CleanupRule] =
        packageManagerRules + developmentEnvironmentRules

    static let packageManagerRules: [CleanupRule] = [
        downloadCacheRule(
            "homebrew-cache",
            name: "Homebrew downloads",
            item: "Homebrew download",
            path: "Library/Caches/Homebrew"
        ),
        downloadCacheRule(
            "npm-cache",
            name: "npm package cache",
            item: "npm package",
            path: ".npm/_cacache"
        ),
        downloadCacheRule(
            "npm-exec-cache",
            name: "npm command cache",
            item: "Cached command package",
            path: ".npm/_npx"
        ),
        rule(
            "pnpm-store",
            .developer,
            "pnpm package store",
            "pnpm package",
            "Downloaded packages shared between projects.",
            "Projects will restore the selected package when it is needed again.",
            .reviewRequired,
            "Library/pnpm/store",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "pnpm-legacy-store",
            .developer,
            "Legacy pnpm package store",
            "pnpm package",
            "Downloaded packages retained by older pnpm versions.",
            "Older projects may need to download the selected package again.",
            .reviewRequired,
            ".pnpm-store",
            .children,
            .child,
            .deleteItem
        ),
        downloadCacheRule(
            "yarn-classic-cache",
            name: "Yarn Classic cache",
            item: "Yarn package",
            path: "Library/Caches/Yarn"
        ),
        downloadCacheRule(
            "yarn-modern-cache",
            name: "Yarn global cache",
            item: "Yarn package",
            path: ".yarn/berry/cache"
        ),
        downloadCacheRule(
            "bun-package-cache",
            name: "Bun package cache",
            item: "Bun package",
            path: ".bun/install/cache"
        ),
        downloadCacheRule(
            "deno-cache",
            name: "Deno dependency cache",
            item: "Deno dependency",
            path: "Library/Caches/deno"
        ),
        downloadCacheRule(
            "node-gyp-cache",
            name: "Node native-build cache",
            item: "Node headers",
            path: "Library/Caches/node-gyp"
        ),
        rule(
            "playwright-browsers",
            .developer,
            "Playwright browsers",
            "Browser runtime",
            "Browser builds downloaded for Playwright automation.",
            "Playwright will download the selected browser again when it is needed.",
            .reviewRequired,
            "Library/Caches/ms-playwright",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "cypress-runtime-cache",
            .developer,
            "Cypress runtimes",
            "Cypress runtime",
            "Downloaded Cypress application versions.",
            "Cypress will download the selected version again when it is needed.",
            .reviewRequired,
            "Library/Caches/Cypress",
            .children,
            .child,
            .deleteItem
        ),
        downloadCacheRule(
            "puppeteer-browser-cache",
            name: "Puppeteer browsers",
            item: "Browser runtime",
            path: ".cache/puppeteer",
            safety: .reviewRequired
        ),
        downloadCacheRule(
            "electron-runtime-cache",
            name: "Electron runtime cache",
            item: "Electron runtime",
            path: "Library/Caches/electron"
        ),
        downloadCacheRule(
            "electron-builder-cache",
            name: "Electron Builder cache",
            item: "Build tool download",
            path: "Library/Caches/electron-builder"
        ),
        downloadCacheRule(
            "cocoapods-cache",
            name: "CocoaPods download cache",
            item: "Pod download",
            path: "Library/Caches/CocoaPods"
        ),
        downloadCacheRule(
            "carthage-cache",
            name: "Carthage cache",
            item: "Carthage download",
            path: "Library/Caches/org.carthage.CarthageKit"
        ),
        downloadCacheRule(
            "pip-cache",
            name: "pip package cache",
            item: "Python package",
            path: "Library/Caches/pip"
        ),
        downloadCacheRule(
            "uv-cache",
            name: "uv package cache",
            item: "Python package",
            path: ".cache/uv"
        ),
        downloadCacheRule(
            "uv-legacy-cache",
            name: "Legacy uv package cache",
            item: "Python package",
            path: "Library/Caches/uv"
        ),
        downloadCacheRule(
            "poetry-cache",
            name: "Poetry package cache",
            item: "Python package",
            path: "Library/Caches/pypoetry"
        ),
        downloadCacheRule(
            "pipenv-cache",
            name: "Pipenv cache",
            item: "Python package",
            path: "Library/Caches/pipenv"
        ),
        downloadCacheRule(
            "cargo-registry-cache",
            name: "Rust package archives",
            item: "Rust package",
            path: ".cargo/registry/cache"
        ),
        downloadCacheRule(
            "cargo-registry-sources",
            name: "Expanded Rust package sources",
            item: "Rust package source",
            path: ".cargo/registry/src"
        ),
        downloadCacheRule(
            "cargo-registry-index",
            name: "Rust registry index",
            item: "Rust registry",
            path: ".cargo/registry/index"
        ),
        downloadCacheRule(
            "cargo-git-cache",
            name: "Rust Git database",
            item: "Rust source database",
            path: ".cargo/git/db"
        ),
        downloadCacheRule(
            "cargo-git-checkouts",
            name: "Rust source checkouts",
            item: "Rust source checkout",
            path: ".cargo/git/checkouts"
        ),
        rule(
            "gradle-cache",
            .developer,
            "Gradle cache",
            "Gradle files",
            "Downloaded dependencies and generated build data.",
            "Gradle will recreate or download the selected files when needed.",
            .reclaimable,
            ".gradle/caches",
            .children,
            .child,
            .deleteItem,
            ["com.google.android.studio"]
        ),
        rule(
            "gradle-wrapper-distributions",
            .developer,
            "Gradle distributions",
            "Gradle version",
            "Gradle versions downloaded by project wrappers.",
            "A project will download the selected Gradle version again when needed.",
            .reviewRequired,
            ".gradle/wrapper/dists",
            .children,
            .child,
            .deleteItem,
            ["com.google.android.studio"]
        ),
        rule(
            "gradle-daemon-data",
            .developer,
            "Gradle daemon logs",
            "Gradle version logs",
            "Logs and process records retained by Gradle daemons.",
            "The selected logs will no longer be available for troubleshooting.",
            .reclaimable,
            ".gradle/daemon",
            .children,
            .child,
            .deleteItem,
            ["com.google.android.studio"]
        ),
        readOnlyRule(
            "maven-repository",
            .developer,
            "Maven local repository",
            "Downloaded packages mixed with artifacts built and installed locally.",
            "Use Maven-aware tooling so unpublished local artifacts are not lost.",
            .home(relativePath: ".m2/repository"),
            .children,
            .child
        ),
        rule(
            "ivy-package-cache",
            .developer,
            "Ivy package cache",
            "Ivy package",
            "Downloaded packages retained by Ivy and sbt.",
            "The selected package may need to be downloaded again.",
            .reviewRequired,
            ".ivy2/cache",
            .children,
            .child,
            .deleteItem
        ),
        downloadCacheRule(
            "coursier-macos-cache",
            name: "Coursier package cache",
            item: "JVM package",
            path: "Library/Caches/Coursier"
        ),
        downloadCacheRule(
            "coursier-xdg-cache",
            name: "Coursier package cache",
            item: "JVM package",
            path: ".cache/coursier"
        ),
        rule(
            "go-build-cache",
            .developer,
            "Go build cache",
            "Go build files",
            "Compiled packages and test results cached by the Go toolchain.",
            "Go will rebuild these files when they are needed.",
            .reclaimable,
            "Library/Caches/go-build",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "go-module-cache",
            .developer,
            "Go module cache",
            "Go module",
            "Downloaded source modules shared between Go projects.",
            "Go will download the selected module again when a project needs it.",
            .reviewRequired,
            "go/pkg/mod",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "nuget-global-packages",
            .developer,
            "NuGet global packages",
            "NuGet package",
            "Expanded packages shared by .NET projects.",
            "Projects will restore the selected package again when needed.",
            .reviewRequired,
            ".nuget/packages",
            .children,
            .child,
            .deleteItem
        ),
        downloadCacheRule(
            "nuget-http-cache",
            name: "NuGet HTTP cache",
            item: "NuGet response cache",
            path: ".local/share/NuGet/v3-cache"
        ),
        downloadCacheRule(
            "nuget-plugin-cache",
            name: "NuGet plugin cache",
            item: "NuGet plugin result",
            path: ".local/share/NuGet/plugins-cache"
        ),
        downloadCacheRule(
            "composer-home-cache",
            name: "Composer package cache",
            item: "Composer package",
            path: ".composer/cache"
        ),
        downloadCacheRule(
            "composer-xdg-cache",
            name: "Composer package cache",
            item: "Composer package",
            path: ".cache/composer"
        ),
        downloadCacheRule(
            "github-cli-cache",
            name: "GitHub CLI cache",
            item: "GitHub CLI cache",
            path: ".cache/gh"
        ),
        downloadCacheRule(
            "ccache-data",
            name: "Compiler cache",
            item: "Compiled object cache",
            path: ".cache/ccache"
        ),
        downloadCacheRule(
            "sccache-data",
            name: "Shared compiler cache",
            item: "Compiled object cache",
            path: "Library/Caches/Mozilla.sccache"
        )
    ]

    private static func downloadCacheRule(
        _ id: String,
        name: String,
        item: String,
        path: String,
        safety: CleanupSafety = .reclaimable,
        blockedBundleIdentifiers: Set<String> = []
    ) -> CleanupRule {
        rule(
            id,
            .developer,
            name,
            item,
            "Downloaded or generated files retained to make developer tools faster.",
            "The owning tool will recreate or download the selected files when needed.",
            safety,
            path,
            .children,
            .child,
            .deleteItem,
            blockedBundleIdentifiers
        )
    }
}
