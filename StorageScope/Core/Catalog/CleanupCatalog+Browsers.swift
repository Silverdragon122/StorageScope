import Foundation

private struct BrowserCatalogEntry {
    let id: String
    let name: String
    let cachePath: String?
    let profilePath: String?
    let bundleIdentifiers: Set<String>
}

extension CleanupCatalog {
    static let browserRules: [CleanupRule] =
        browserDefinitions.compactMap(browserCacheRule)
        + browserDefinitions.compactMap(browserProfileRule)

    private static let browserDefinitions: [BrowserCatalogEntry] = [
        BrowserCatalogEntry(
            id: "chrome",
            name: "Google Chrome",
            cachePath: "Library/Caches/Google/Chrome",
            profilePath: "Library/Application Support/Google/Chrome",
            bundleIdentifiers: ["com.google.Chrome"]
        ),
        BrowserCatalogEntry(
            id: "chrome-beta",
            name: "Google Chrome Beta",
            cachePath: "Library/Caches/Google/Chrome Beta",
            profilePath: "Library/Application Support/Google/Chrome Beta",
            bundleIdentifiers: ["com.google.Chrome.beta"]
        ),
        BrowserCatalogEntry(
            id: "chrome-dev",
            name: "Google Chrome Dev",
            cachePath: "Library/Caches/Google/Chrome Dev",
            profilePath: "Library/Application Support/Google/Chrome Dev",
            bundleIdentifiers: ["com.google.Chrome.dev"]
        ),
        BrowserCatalogEntry(
            id: "chrome-canary",
            name: "Google Chrome Canary",
            cachePath: "Library/Caches/Google/Chrome Canary",
            profilePath: "Library/Application Support/Google/Chrome Canary",
            bundleIdentifiers: ["com.google.Chrome.canary"]
        ),
        BrowserCatalogEntry(
            id: "chrome-for-testing",
            name: "Chrome for Testing",
            cachePath: "Library/Caches/Google/Chrome for Testing",
            profilePath: "Library/Application Support/Google/Chrome for Testing",
            bundleIdentifiers: ["com.google.Chrome.forTesting"]
        ),
        BrowserCatalogEntry(
            id: "chromium",
            name: "Chromium",
            cachePath: "Library/Caches/Chromium",
            profilePath: "Library/Application Support/Chromium",
            bundleIdentifiers: ["org.chromium.Chromium"]
        ),
        BrowserCatalogEntry(
            id: "brave",
            name: "Brave",
            cachePath: "Library/Caches/BraveSoftware/Brave-Browser",
            profilePath: "Library/Application Support/BraveSoftware/Brave-Browser",
            bundleIdentifiers: ["com.brave.Browser"]
        ),
        BrowserCatalogEntry(
            id: "brave-beta",
            name: "Brave Beta",
            cachePath: "Library/Caches/BraveSoftware/Brave-Browser-Beta",
            profilePath: "Library/Application Support/BraveSoftware/Brave-Browser-Beta",
            bundleIdentifiers: ["com.brave.Browser.beta"]
        ),
        BrowserCatalogEntry(
            id: "brave-nightly",
            name: "Brave Nightly",
            cachePath: "Library/Caches/BraveSoftware/Brave-Browser-Nightly",
            profilePath: "Library/Application Support/BraveSoftware/Brave-Browser-Nightly",
            bundleIdentifiers: ["com.brave.Browser.nightly"]
        ),
        BrowserCatalogEntry(
            id: "edge",
            name: "Microsoft Edge",
            cachePath: "Library/Caches/Microsoft Edge",
            profilePath: "Library/Application Support/Microsoft Edge",
            bundleIdentifiers: ["com.microsoft.edgemac"]
        ),
        BrowserCatalogEntry(
            id: "edge-beta",
            name: "Microsoft Edge Beta",
            cachePath: "Library/Caches/Microsoft Edge Beta",
            profilePath: "Library/Application Support/Microsoft Edge Beta",
            bundleIdentifiers: ["com.microsoft.edgemac.Beta"]
        ),
        BrowserCatalogEntry(
            id: "edge-dev",
            name: "Microsoft Edge Dev",
            cachePath: "Library/Caches/Microsoft Edge Dev",
            profilePath: "Library/Application Support/Microsoft Edge Dev",
            bundleIdentifiers: ["com.microsoft.edgemac.Dev"]
        ),
        BrowserCatalogEntry(
            id: "edge-canary",
            name: "Microsoft Edge Canary",
            cachePath: "Library/Caches/Microsoft Edge Canary",
            profilePath: "Library/Application Support/Microsoft Edge Canary",
            bundleIdentifiers: ["com.microsoft.edgemac.Canary"]
        ),
        BrowserCatalogEntry(
            id: "firefox",
            name: "Firefox",
            cachePath: "Library/Caches/Firefox",
            profilePath: "Library/Application Support/Firefox",
            bundleIdentifiers: ["org.mozilla.firefox"]
        ),
        BrowserCatalogEntry(
            id: "safari",
            name: "Safari",
            cachePath: "Library/Caches/com.apple.Safari",
            profilePath: "Library/Safari",
            bundleIdentifiers: ["com.apple.Safari"]
        ),
        BrowserCatalogEntry(
            id: "vivaldi",
            name: "Vivaldi",
            cachePath: "Library/Caches/Vivaldi",
            profilePath: "Library/Application Support/Vivaldi",
            bundleIdentifiers: ["com.vivaldi.Vivaldi"]
        ),
        BrowserCatalogEntry(
            id: "opera",
            name: "Opera",
            cachePath: "Library/Caches/com.operasoftware.Opera",
            profilePath: "Library/Application Support/com.operasoftware.Opera",
            bundleIdentifiers: ["com.operasoftware.Opera"]
        ),
        BrowserCatalogEntry(
            id: "orion",
            name: "Orion",
            cachePath: "Library/Caches/com.kagi.kagimacOS",
            profilePath: "Library/Application Support/Orion",
            bundleIdentifiers: ["com.kagi.kagimacOS"]
        ),
        BrowserCatalogEntry(
            id: "arc",
            name: "Arc",
            cachePath: nil,
            profilePath: "Library/Application Support/Arc",
            bundleIdentifiers: ["company.thebrowser.Browser"]
        ),
        BrowserCatalogEntry(
            id: "tor-browser",
            name: "Tor Browser",
            cachePath: nil,
            profilePath: "Library/Application Support/TorBrowser-Data",
            bundleIdentifiers: ["org.torproject.torbrowser"]
        )
    ]

    private static func browserCacheRule(
        _ definition: BrowserCatalogEntry
    ) -> CleanupRule? {
        guard let path = definition.cachePath else { return nil }

        return rule(
            "\(definition.id)-cache",
            .browsers,
            "\(definition.name) cache",
            "Browser cache",
            "Temporary website files kept by \(definition.name).",
            "Websites may load more slowly once while the cache is rebuilt.",
            .reclaimable,
            path,
            .children,
            .child,
            .deleteItem,
            definition.bundleIdentifiers
        )
    }

    private static func browserProfileRule(
        _ definition: BrowserCatalogEntry
    ) -> CleanupRule? {
        guard let path = definition.profilePath else { return nil }

        return readOnlyRule(
            "\(definition.id)-profile-data",
            .browsers,
            "\(definition.name) profiles",
            "Bookmarks, history, cookies, extensions, offline website data, and settings.",
            "Manage this data from \(definition.name) to avoid losing browser information.",
            .home(relativePath: path),
            .location,
            .fixed
        )
    }
}
