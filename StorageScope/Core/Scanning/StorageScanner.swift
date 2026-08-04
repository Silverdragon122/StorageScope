import Foundation

actor StorageScanner: StorageScanning {
    private let catalog: CleanupCatalog
    private let homeURL: URL
    private let fileManager: FileManager
    private let sizeCalculator: AllocatedSizeCalculator
    private var candidateDiscovery: StorageCandidateDiscovery
    private let itemNaming: StorageItemNaming
    private let systemProbe: any SystemStorageProbing
    private let cacheStore: ScanCacheStore
    private let changeTracker: any FileSystemChangeTracking
    private let fullDiskAccessProbe: FullDiskAccessProbe
    private let catalogSignature: String

    init(
        catalog: CleanupCatalog = .standard,
        homeURL: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default,
        systemProbe: any SystemStorageProbing = LiveSystemStorageProbe(),
        cacheStore: ScanCacheStore = ScanCacheStore(),
        changeTracker: any FileSystemChangeTracking = LiveFileSystemChangeTracker()
    ) {
        self.catalog = catalog
        self.homeURL = homeURL.standardizedFileURL
        self.fileManager = fileManager
        self.sizeCalculator = AllocatedSizeCalculator(fileManager: fileManager)
        self.candidateDiscovery = StorageCandidateDiscovery(fileManager: fileManager)
        self.itemNaming = StorageItemNaming()
        self.systemProbe = systemProbe
        self.cacheStore = cacheStore
        self.changeTracker = changeTracker
        self.fullDiskAccessProbe = FullDiskAccessProbe(
            homeURL: self.homeURL
        )
        self.catalogSignature = Self.signature(for: catalog)
    }

    func cachedReport() async -> ScanReport? {
        guard let snapshot = await cacheStore.load(
            catalogSignature: catalogSignature,
            homePath: homeURL.path
        ) else {
            return nil
        }

        var items = snapshot.rules.values.flatMap(\.items)
        items.sort(by: Self.sortItems)
        return ScanReport(
            items: items,
            issues: deduplicated(snapshot.rules.values.flatMap(\.issues)),
            notices: snapshot.notices,
            fullDiskAccessStatus: fullDiskAccessProbe.status(),
            scannedAt: snapshot.scannedAt,
            duration: .zero,
            source: .cache
        )
    }

    func scan(
        progress: @escaping @Sendable (ScanProgress) async -> Void
    ) async -> ScanReport {
        let clock = ContinuousClock()
        let startedAt = clock.now
        candidateDiscovery.prepare(
            rules: catalog.rules,
            homeURL: homeURL
        )
        let scanEventID = changeTracker.currentEventID()
        let cachedSnapshot = await cacheStore.load(
            catalogSignature: catalogSignature,
            homePath: homeURL.path
        )
        let watchedPaths = Self.minimalWatchRoots(
            [
                homeURL.path,
                "/Library",
                "/private",
                "/System",
                "/Users",
                "/cores",
                "/nix",
                "/opt",
                "/usr/local"
            ].filter { fileManager.fileExists(atPath: $0) }
        )

        async let changeSetTask: FileSystemChangeSet = {
            guard let cachedSnapshot else {
                return FileSystemChangeSet(
                    changedPaths: [],
                    requiresFullScan: true
                )
            }
            return await changeTracker.changes(
                since: cachedSnapshot.eventID,
                watching: watchedPaths
            )
        }()
        async let systemStorageTask = systemProbe.inspect()

        let changeSet = await changeSetTask
        let systemStorage = await systemStorageTask
        let changedPathIndex = ChangedPathIndex(paths: changeSet.changedPaths)
        let fullDiskAccessStatus = fullDiskAccessProbe.status()
        var seenFiles: Set<FileKey> = []
        let claimedPaths = ClaimedPathIndex()
        var items: [StorageItem] = []
        var pendingIndexedItems: [StorageItem] = []
        var issues: [ScanIssue] = []
        var pendingIssues: [ScanIssue] = []
        var cachedRules: [String: CachedRuleScan] = [:]
        var pendingRefreshedRuleIDs: Set<String> = []
        items.reserveCapacity(catalog.rules.count)
        pendingIndexedItems.reserveCapacity(8)
        pendingIssues.reserveCapacity(4)
        cachedRules.reserveCapacity(catalog.rules.count)
        pendingRefreshedRuleIDs.reserveCapacity(16)
        var reusedRuleCount = 0
        var discoveredBytes: Int64 = 0
        var lastProgressInstant = clock.now
        var hasPublishedItems = false
        let probedRuleIDs = Set(systemStorage.records.map(\.ruleID))

        for record in systemStorage.records {
            guard let rule = catalog.rule(id: record.ruleID) else { continue }
            let recordURL = record.url.standardizedFileURL
            let identity = (try? FileIdentity(url: recordURL)) ?? FileIdentity(
                device: 0,
                inode: UInt64(bitPattern: Int64(record.ruleID.hashValue)),
                owner: 0,
                kind: .directory,
                modificationSeconds: 0,
                modificationNanoseconds: 0
            )
            let item = StorageItem(
                id: "\(rule.id)|\(recordURL.path)",
                ruleID: rule.id,
                category: rule.category,
                title: rule.itemTitle,
                detail: rule.itemDetail,
                consequence: rule.consequence,
                url: recordURL,
                allocatedBytes: record.allocatedBytes,
                fileCount: 0,
                safety: .protected,
                cleanupAction: .none,
                identity: identity,
                blockedBundleIdentifiers: []
            )
            items.append(item)
            pendingIndexedItems.append(item)
            discoveredBytes += item.allocatedBytes
            _ = claimedPaths.insert(recordURL.path)
        }
        pendingRefreshedRuleIDs.formUnion(probedRuleIDs)

        for ruleID in probedRuleIDs {
            cachedRules[ruleID] = CachedRuleScan(
                items: items.filter { $0.ruleID == ruleID },
                issues: []
            )
        }

        for (index, rule) in catalog.rules.enumerated() {
            if Task.isCancelled { break }
            pendingRefreshedRuleIDs.insert(rule.id)
            if probedRuleIDs.contains(rule.id) {
                let now = clock.now
                if Self.shouldPublishProgress(
                    pendingItemCount: pendingIndexedItems.count,
                    pendingIssueCount: pendingIssues.count,
                    elapsed: lastProgressInstant.duration(to: now),
                    isFinalRule: index == catalog.rules.count - 1
                ) {
                    await progress(
                        progressSnapshot(
                            completedRules: index + 1,
                            currentLocation: rule.locationName,
                            discoveredBytes: discoveredBytes,
                            discoveredItemCount: items.count,
                            indexedItems: pendingIndexedItems,
                            refreshedRuleIDs: pendingRefreshedRuleIDs,
                            issues: pendingIssues,
                            notices: systemStorage.notices,
                            fullDiskAccessStatus: fullDiskAccessStatus
                        )
                    )
                    hasPublishedItems =
                        hasPublishedItems || !pendingIndexedItems.isEmpty
                    pendingIndexedItems.removeAll(keepingCapacity: true)
                    pendingIssues.removeAll(keepingCapacity: true)
                    pendingRefreshedRuleIDs.removeAll(keepingCapacity: true)
                    lastProgressInstant = clock.now
                }
                continue
            }

            let rootURL = rule.location.resolve(homeURL: homeURL).standardizedFileURL
            if
                let cachedRule = reusableCachedRule(
                    for: rule,
                    rootURL: rootURL,
                    snapshot: cachedSnapshot,
                    changes: changeSet,
                    changedPaths: changedPathIndex
                )
            {
                items.append(contentsOf: cachedRule.items)
                pendingIndexedItems.append(contentsOf: cachedRule.items)
                issues.append(contentsOf: cachedRule.issues)
                pendingIssues.append(contentsOf: cachedRule.issues)
                for item in cachedRule.items {
                    _ = claimedPaths.insert(item.url.standardizedFileURL.path)
                    discoveredBytes += item.allocatedBytes
                }
                cachedRules[rule.id] = cachedRule
                reusedRuleCount += 1

                let now = clock.now
                if Self.shouldPublishProgress(
                    pendingItemCount: pendingIndexedItems.count,
                    pendingIssueCount: pendingIssues.count,
                    elapsed: lastProgressInstant.duration(to: now),
                    isFinalRule: index == catalog.rules.count - 1
                ) {
                    await progress(
                        progressSnapshot(
                            completedRules: index + 1,
                            currentLocation: rule.locationName,
                            discoveredBytes: discoveredBytes,
                            discoveredItemCount: items.count,
                            indexedItems: pendingIndexedItems,
                            refreshedRuleIDs: pendingRefreshedRuleIDs,
                            issues: pendingIssues,
                            notices: systemStorage.notices,
                            fullDiskAccessStatus: fullDiskAccessStatus
                        )
                    )
                    hasPublishedItems =
                        hasPublishedItems || !pendingIndexedItems.isEmpty
                    pendingIndexedItems.removeAll(keepingCapacity: true)
                    pendingIssues.removeAll(keepingCapacity: true)
                    pendingRefreshedRuleIDs.removeAll(keepingCapacity: true)
                    lastProgressInstant = clock.now
                }
                continue
            }

            let firstItemIndex = items.count
            let firstIssueIndex = issues.count
            do {
                let candidates = try candidateDiscovery.candidates(
                    for: rule,
                    rootURL: rootURL,
                    homeURL: homeURL
                )

                for candidate in candidates {
                    if Task.isCancelled { break }

                    let candidateURL = candidate.url.standardizedFileURL
                    guard let excludedPaths = claimedPaths.exclusionsIfUnclaimed(
                        for: candidateURL.path
                    ) else {
                        continue
                    }

                    do {
                        let measurement = try sizeCalculator.measure(
                            url: candidateURL,
                            seenFiles: &seenFiles,
                            countRootAllocation: rule.cleanupAction != .deleteContents,
                            excluding: excludedPaths
                        )
                        let identity = measurement.rootIdentity

                        guard
                            identity.kind != .symbolicLink,
                            identity.kind != .other
                        else {
                            continue
                        }

                        if measurement.encounteredUnreadableEntry {
                            let scanIssue = issue(
                                for: rule,
                                path: candidateURL.path,
                                kind: .permissionDenied
                            )
                            issues.append(scanIssue)
                            pendingIssues.append(scanIssue)
                        }

                        guard claimedPaths.insert(candidateURL.path) else { continue }
                        guard measurement.allocatedBytes > 0 else { continue }

                        let item = StorageItem(
                            id: "\(rule.id)|\(candidateURL.path)",
                            ruleID: rule.id,
                            category: rule.category,
                            title: itemNaming.title(
                                for: rule,
                                candidate: candidate,
                                rootURL: rootURL
                            ),
                            detail: rule.itemDetail,
                            consequence: rule.consequence,
                            url: candidateURL,
                            allocatedBytes: measurement.allocatedBytes,
                            fileCount: measurement.fileCount,
                            safety: rule.safety,
                            cleanupAction: rule.cleanupAction.itemAction(
                                identifier: candidate.identifier
                            ),
                            identity: identity,
                            blockedBundleIdentifiers: rule.blockedBundleIdentifiers.union(
                                itemNaming.inferredBundleIdentifiers(
                                    for: rule,
                                    candidate: candidate,
                                    rootURL: rootURL
                                )
                            )
                        )
                        items.append(item)
                        pendingIndexedItems.append(item)
                        discoveredBytes += item.allocatedBytes

                        let now = clock.now
                        if
                            !hasPublishedItems
                                || pendingIndexedItems.count >= 6
                                || lastProgressInstant.duration(to: now)
                                    >= .milliseconds(80)
                        {
                            await progress(
                                progressSnapshot(
                                    completedRules: index,
                                    currentLocation: rule.locationName,
                                    discoveredBytes: discoveredBytes,
                                    discoveredItemCount: items.count,
                                    indexedItems: pendingIndexedItems,
                                    refreshedRuleIDs: pendingRefreshedRuleIDs,
                                    issues: pendingIssues,
                                    notices: systemStorage.notices,
                                    fullDiskAccessStatus: fullDiskAccessStatus
                                )
                            )
                            hasPublishedItems = true
                            pendingIndexedItems.removeAll(
                                keepingCapacity: true
                            )
                            pendingIssues.removeAll(keepingCapacity: true)
                            pendingRefreshedRuleIDs.removeAll(
                                keepingCapacity: true
                            )
                            lastProgressInstant = clock.now
                        }
                    } catch is CancellationError {
                        break
                    } catch SizeMeasurementError.changedDuringScan {
                        let scanIssue = issue(
                            for: rule,
                            path: candidateURL.path,
                            kind: .changedDuringScan
                        )
                        issues.append(scanIssue)
                        pendingIssues.append(scanIssue)
                    } catch {
                        let scanIssue = issue(
                            for: rule,
                            path: candidateURL.path,
                            kind: issueKind(for: error)
                        )
                        issues.append(scanIssue)
                        pendingIssues.append(scanIssue)
                    }
                }
            } catch {
                if fileManager.fileExists(atPath: rootURL.path) {
                    let scanIssue = issue(
                        for: rule,
                        path: rootURL.path,
                        kind: issueKind(for: error)
                    )
                    issues.append(scanIssue)
                    pendingIssues.append(scanIssue)
                }
            }

            cachedRules[rule.id] = CachedRuleScan(
                items: Array(items.dropFirst(firstItemIndex)),
                issues: Array(issues.dropFirst(firstIssueIndex))
            )

            let invalidatesCachedContent = cachedSnapshot?
                .rules[rule.id]
                .map { !$0.items.isEmpty || !$0.issues.isEmpty }
                ?? false
            let now = clock.now
            if
                invalidatesCachedContent
                    || Self.shouldPublishProgress(
                        pendingItemCount: pendingIndexedItems.count,
                        pendingIssueCount: pendingIssues.count,
                        elapsed: lastProgressInstant.duration(to: now),
                        isFinalRule: index == catalog.rules.count - 1
                    )
            {
                await progress(
                    progressSnapshot(
                        completedRules: index + 1,
                        currentLocation: rule.locationName,
                        discoveredBytes: discoveredBytes,
                        discoveredItemCount: items.count,
                        indexedItems: pendingIndexedItems,
                        refreshedRuleIDs: pendingRefreshedRuleIDs,
                        issues: pendingIssues,
                        notices: systemStorage.notices,
                        fullDiskAccessStatus: fullDiskAccessStatus
                    )
                )
                hasPublishedItems =
                    hasPublishedItems || !pendingIndexedItems.isEmpty
                pendingIndexedItems.removeAll(keepingCapacity: true)
                pendingIssues.removeAll(keepingCapacity: true)
                pendingRefreshedRuleIDs.removeAll(keepingCapacity: true)
                lastProgressInstant = clock.now
            }
        }

        items.sort(by: Self.sortItems)
        let completedAt = Date()
        let report = ScanReport(
            items: items,
            issues: deduplicated(issues),
            notices: systemStorage.notices,
            fullDiskAccessStatus: fullDiskAccessStatus,
            scannedAt: completedAt,
            duration: startedAt.duration(to: clock.now),
            source: reusedRuleCount > 0
                ? .incremental(
                    reusedRuleCount: reusedRuleCount,
                    totalRuleCount: catalog.rules.count
                )
                : .full
        )

        if !Task.isCancelled {
            let cacheEventID = scanEventID > 0
                ? scanEventID
                : changeTracker.currentEventID()
            await cacheStore.save(
                ScanCacheSnapshot(
                    catalogSignature: catalogSignature,
                    homePath: homeURL.path,
                    eventID: cacheEventID,
                    scannedAt: completedAt,
                    rules: cachedRules,
                    notices: systemStorage.notices
                )
            )
        }

        return report
    }

    private func progressSnapshot(
        completedRules: Int,
        currentLocation: String,
        discoveredBytes: Int64,
        discoveredItemCount: Int,
        indexedItems: [StorageItem],
        refreshedRuleIDs: Set<String>,
        issues: [ScanIssue],
        notices: [ScanNotice],
        fullDiskAccessStatus: FullDiskAccessStatus
    ) -> ScanProgress {
        ScanProgress(
            completedRules: completedRules,
            totalRules: catalog.rules.count,
            currentLocation: currentLocation,
            discoveredBytes: discoveredBytes,
            discoveredItemCount: discoveredItemCount,
            indexedItems: indexedItems,
            refreshedRuleIDs: refreshedRuleIDs,
            issues: issues,
            notices: notices,
            fullDiskAccessStatus: fullDiskAccessStatus
        )
    }

    private static func shouldPublishProgress(
        pendingItemCount: Int,
        pendingIssueCount: Int,
        elapsed: Duration,
        isFinalRule: Bool
    ) -> Bool {
        isFinalRule
            || pendingItemCount > 0
            || pendingIssueCount > 0
            || elapsed >= .milliseconds(80)
    }

    private func reusableCachedRule(
        for rule: CleanupRule,
        rootURL: URL,
        snapshot: ScanCacheSnapshot?,
        changes: FileSystemChangeSet,
        changedPaths: ChangedPathIndex
    ) -> CachedRuleScan? {
        guard
            !changes.requiresFullScan,
            let cachedRule = snapshot?.rules[rule.id],
            cachedRule.issues.isEmpty,
            !changedPaths.overlaps(rootURL.path)
        else {
            return nil
        }

        let identitiesStillMatch = cachedRule.items.allSatisfy { item in
            (try? FileIdentity(url: item.url)) == item.identity
        }
        return identitiesStillMatch ? cachedRule : nil
    }

    private static func sortItems(_ first: StorageItem, _ second: StorageItem) -> Bool {
        if first.allocatedBytes == second.allocatedBytes {
            return first.title.localizedStandardCompare(second.title) == .orderedAscending
        }
        return first.allocatedBytes > second.allocatedBytes
    }

    private static func minimalWatchRoots(_ paths: [String]) -> [String] {
        let orderedPaths = Set(paths.map {
            URL(fileURLWithPath: $0).standardizedFileURL.path
        })
        .sorted {
            if $0.count == $1.count {
                return $0 < $1
            }
            return $0.count < $1.count
        }

        var roots: [String] = []
        for path in orderedPaths {
            guard !roots.contains(where: {
                path == $0 || path.hasPrefix($0 + "/")
            }) else {
                continue
            }
            roots.append(path)
        }
        return roots
    }

    private static func signature(for catalog: CleanupCatalog) -> String {
        catalog.rules.map { rule in
            [
                rule.id,
                rule.category.rawValue,
                rule.locationName,
                rule.itemTitle,
                rule.itemDetail,
                rule.consequence,
                rule.safety.rawValue,
                String(reflecting: rule.location),
                String(reflecting: rule.source),
                String(reflecting: rule.nameStyle),
                String(reflecting: rule.cleanupAction),
                rule.blockedBundleIdentifiers.sorted().joined(separator: ",")
            ].joined(separator: "|")
        }
        .joined(separator: "\n")
    }

    private func issue(
        for rule: CleanupRule,
        path: String,
        kind: ScanIssueKind
    ) -> ScanIssue {
        ScanIssue(
            id: "\(rule.id)|\(kind.rawValue)|\(path)",
            locationName: rule.locationName,
            kind: kind
        )
    }

    private func issueKind(for error: Error) -> ScanIssueKind {
        let nsError = error as NSError
        if
            nsError.domain == NSCocoaErrorDomain,
            nsError.code == CocoaError.fileReadNoPermission.rawValue
        {
            return .permissionDenied
        }
        if
            nsError.domain == NSPOSIXErrorDomain,
            nsError.code == Int(EACCES) || nsError.code == Int(EPERM)
        {
            return .permissionDenied
        }
        return .unreadable
    }

    private func deduplicated(_ issues: [ScanIssue]) -> [ScanIssue] {
        var seen: Set<String> = []
        return issues.filter { seen.insert($0.id).inserted }
    }
}
