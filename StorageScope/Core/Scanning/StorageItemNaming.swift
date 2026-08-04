import Foundation

struct StorageItemNaming {
    private static let knownNames: [String: String] = [
        "ai.elementlabs.lmstudio": AppCopy.Core.applicationName(
            bundleIdentifier: "ai.elementlabs.lmstudio",
            fallback: "LM Studio"
        ),
        "com.anthropic.claudefordesktop": AppCopy.Core.applicationName(
            bundleIdentifier: "com.anthropic.claudefordesktop",
            fallback: "Claude"
        ),
        "com.apple.MobileSMS": AppCopy.Core.applicationName(
            bundleIdentifier: "com.apple.MobileSMS",
            fallback: "Messages"
        ),
        "com.apple.Safari": AppCopy.Core.applicationName(
            bundleIdentifier: "com.apple.Safari",
            fallback: "Safari"
        ),
        "com.apple.mail": AppCopy.Core.applicationName(
            bundleIdentifier: "com.apple.mail",
            fallback: "Mail"
        ),
        "com.brave.Browser": AppCopy.Core.applicationName(
            bundleIdentifier: "com.brave.Browser",
            fallback: "Brave"
        ),
        "com.google.Chrome": AppCopy.Core.applicationName(
            bundleIdentifier: "com.google.Chrome",
            fallback: "Google Chrome"
        ),
        "com.hnc.Discord": AppCopy.Core.applicationName(
            bundleIdentifier: "com.hnc.Discord",
            fallback: "Discord"
        ),
        "com.microsoft.VSCode": AppCopy.Core.applicationName(
            bundleIdentifier: "com.microsoft.VSCode",
            fallback: "Visual Studio Code"
        ),
        "com.microsoft.edgemac": AppCopy.Core.applicationName(
            bundleIdentifier: "com.microsoft.edgemac",
            fallback: "Microsoft Edge"
        ),
        "com.openai.chat": AppCopy.Core.applicationName(
            bundleIdentifier: "com.openai.chat",
            fallback: "ChatGPT"
        ),
        "com.openai.codex": AppCopy.Core.applicationName(
            bundleIdentifier: "com.openai.codex",
            fallback: "Codex"
        ),
        "com.spotify.client": AppCopy.Core.applicationName(
            bundleIdentifier: "com.spotify.client",
            fallback: "Spotify"
        ),
        "com.tinyspeck.slackmacgap": AppCopy.Core.applicationName(
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            fallback: "Slack"
        ),
        "company.thebrowser.Browser": AppCopy.Core.applicationName(
            bundleIdentifier: "company.thebrowser.Browser",
            fallback: "Arc"
        ),
        "md.obsidian": AppCopy.Core.applicationName(
            bundleIdentifier: "md.obsidian",
            fallback: "Obsidian"
        ),
        "notion.id": AppCopy.Core.applicationName(
            bundleIdentifier: "notion.id",
            fallback: "Notion"
        ),
        "org.mozilla.firefox": AppCopy.Core.applicationName(
            bundleIdentifier: "org.mozilla.firefox",
            fallback: "Firefox"
        )
    ]

    func inferredBundleIdentifiers(
        for rule: CleanupRule,
        candidate: ScanCandidate,
        rootURL: URL
    ) -> Set<String> {
        guard rule.nameStyle == .appCache else { return [] }

        let relativeComponents = Array(
            candidate.url.pathComponents.dropFirst(rootURL.pathComponents.count)
        )
        guard let owner = relativeComponents.first, owner.contains(".") else {
            return []
        }
        return [owner]
    }

    func title(
        for rule: CleanupRule,
        candidate: ScanCandidate,
        rootURL: URL
    ) -> String {
        if let titleOverride = candidate.titleOverride {
            switch rule.nameStyle {
            case .appCache:
                return AppCopy.Core.cacheTitle(friendlyName(for: titleOverride))
            default:
                return friendlyName(for: titleOverride)
            }
        }

        let candidateName = friendlyName(
            for: candidate.url.deletingPathExtension().lastPathComponent
        )

        switch rule.nameStyle {
        case .fixed:
            return rule.itemTitle
        case .child:
            return candidateName
        case .childWithSuffix(let suffix):
            return LocalizedCopy.catalogDynamicTitle(
                ruleID: rule.id,
                value: candidateName,
                fallbackFormat: "%@ \(suffix)"
            )
        case .enclosingPackageWithSuffix(let suffix):
            let packageName = enclosingPackageName(for: candidate.url)
            return LocalizedCopy.catalogDynamicTitle(
                ruleID: rule.id,
                value: packageName ?? rule.itemTitle,
                fallbackFormat: "%@ \(suffix)"
            )
        case .appCache:
            let relativeComponents = Array(
                candidate.url.pathComponents.dropFirst(rootURL.pathComponents.count)
            )
            let owner = relativeComponents.first ?? candidate.url.lastPathComponent
            return AppCopy.Core.cacheTitle(friendlyName(for: owner))
        case .simulatorDevice:
            return candidateName
        }
    }

    private func enclosingPackageName(for url: URL) -> String? {
        var currentURL = url.deletingLastPathComponent()
        while currentURL.path != "/" {
            let pathExtension = currentURL.pathExtension.lowercased()
            if pathExtension == "fcpbundle" || pathExtension == "imovielibrary" {
                return friendlyName(
                    for: currentURL.deletingPathExtension().lastPathComponent
                )
            }
            currentURL.deleteLastPathComponent()
        }
        return nil
    }

    private func friendlyName(for rawName: String) -> String {
        if let knownName = Self.knownNames[rawName] {
            return knownName
        }

        var simplified = rawName
        let dotParts = simplified.split(separator: ".")
        if dotParts.count > 1, let last = dotParts.last {
            simplified = String(last)
        }

        if
            let separatorIndex = simplified.lastIndex(of: "-"),
            simplified.distance(
                from: simplified.index(after: separatorIndex),
                to: simplified.endIndex
            ) >= 16
        {
            simplified = String(simplified[..<separatorIndex])
        }

        simplified = simplified
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        var result = ""
        for character in simplified {
            if
                character.isUppercase,
                let lastCharacter = result.last,
                !lastCharacter.isWhitespace,
                !lastCharacter.isUppercase
            {
                result.append(" ")
            }
            result.append(character)
        }

        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppCopy.Core.storedFiles : trimmed
    }
}
