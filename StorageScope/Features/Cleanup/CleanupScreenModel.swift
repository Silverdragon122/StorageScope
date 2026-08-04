import Foundation
import Observation

enum StorageFilter: Hashable {
    case all
    case category(StorageCategory)
}

@MainActor
@Observable
final class CleanupScreenModel {
    private(set) var report: ScanReport?
    private(set) var scanProgress: ScanProgress?
    private(set) var cleanupProgress: CleanupProgress?
    private(set) var cleanupReport: CleanupReport?
    private(set) var recoveryReport: RecoveryReport?
    private(set) var isScanning = false
    private(set) var isCleaning = false
    private(set) var blockingApplications: [CleanupApplication] = []

    var selectedFilter: StorageFilter = .all
    var selectedItemIDs: Set<StorageItem.ID> = []
    var inspectedItemID: StorageItem.ID?
    var searchText = ""
    var isReviewPresented = false
    var isOpenApplicationsAlertPresented = false
    private(set) var fullDiskAccessStatus: FullDiskAccessStatus
    private(set) var isWaitingForFullDiskAccessSettings = false
    var showsProtectedItems: Bool
    var showsFileCounts: Bool
    var itemSortOrder: CleanupItemSortOrder

    @ObservationIgnored private let scanner: any StorageScanning
    @ObservationIgnored private let cleaner: any StorageCleaning
    @ObservationIgnored private let workspace: any WorkspaceProviding
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var cleanupTask: Task<Void, Never>?
    @ObservationIgnored private var pendingCleanupItems: [StorageItem] = []
    @ObservationIgnored private var liveReportItemsByID:
        [StorageItem.ID: StorageItem] = [:]
    @ObservationIgnored private var baselineItemIDsByRule:
        [String: Set<StorageItem.ID>] = [:]
    @ObservationIgnored private var liveReportIssuesByID:
        [ScanIssue.ID: ScanIssue] = [:]
    @ObservationIgnored private var baselineIssueIDsByRule:
        [String: Set<ScanIssue.ID>] = [:]
    @ObservationIgnored private var hasLiveScanBaseline = false
    @ObservationIgnored private var hasPrepared = false
    @ObservationIgnored private let automaticallyScans: Bool
    @ObservationIgnored private let forceCloseMode: @MainActor () -> Bool
    @ObservationIgnored private let checkFullDiskAccess:
        @MainActor () -> FullDiskAccessStatus

    init(
        scanner: any StorageScanning = StorageScanner(),
        cleaner: any StorageCleaning = SafeCleanupService(),
        workspace: any WorkspaceProviding = WorkspaceAccess(),
        initialReport: ScanReport? = nil,
        initialProgress: ScanProgress? = nil,
        automaticallyScans: Bool? = nil,
        checkFullDiskAccess: @escaping @MainActor () -> FullDiskAccessStatus = {
            FullDiskAccessProbe().status()
        },
        forceCloseMode: @escaping @MainActor () -> Bool = {
            CleanupPreferences.forceCloseModeEnabled
        }
    ) {
        self.scanner = scanner
        self.cleaner = cleaner
        self.workspace = workspace
        self.report = initialReport
        self.scanProgress = initialProgress
        self.isScanning = initialProgress != nil
        self.automaticallyScans =
            automaticallyScans ?? CleanupPreferences.scanOnLaunchEnabled
        self.checkFullDiskAccess = checkFullDiskAccess
        self.fullDiskAccessStatus = initialReport?.fullDiskAccessStatus ?? .unknown
        self.forceCloseMode = forceCloseMode
        self.showsProtectedItems =
            CleanupPreferences.showProtectedItemsEnabled
        self.showsFileCounts = CleanupPreferences.showFileCountsEnabled
        self.itemSortOrder = CleanupPreferences.itemSortOrder
    }

    var visibleItems: [StorageItem] {
        let categoryItems: [StorageItem]
        switch selectedFilter {
        case .all:
            categoryItems = displayedItems
        case .category(let selectedCategory):
            categoryItems = displayedItems.filter {
                $0.category == selectedCategory
            }
        }

        let trimmedSearch = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let searchedItems: [StorageItem]
        if trimmedSearch.isEmpty {
            searchedItems = categoryItems
        } else {
            searchedItems = categoryItems.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedSearch)
                    || $0.detail.localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        return searchedItems.sorted(by: itemComesBefore)
    }

    var displayedItemCount: Int {
        displayedItems.count
    }

    var displayedBytes: Int64 {
        displayedItems.reduce(into: 0) {
            $0 += $1.allocatedBytes
        }
    }

    var selectedItems: [StorageItem] {
        (report?.items ?? [])
            .filter { selectedItemIDs.contains($0.id) }
            .sorted(by: itemComesBefore)
    }

    var selectedBytes: Int64 {
        selectedItems.reduce(into: 0) { $0 += $1.allocatedBytes }
    }

    func byteCount(with safety: CleanupSafety) -> Int64 {
        displayedItems.reduce(into: 0) { total, item in
            if item.safety == safety {
                total += item.allocatedBytes
            }
        }
    }

    var inspectedItem: StorageItem? {
        guard let inspectedItemID else { return nil }
        return report?.items.first { $0.id == inspectedItemID }
    }

    var requiresReviewAcknowledgment: Bool {
        selectedItems.contains { $0.safety == .reviewRequired }
    }

    var forceCloseModeEnabled: Bool {
        forceCloseMode()
    }

    func prepare() {
        guard !hasPrepared else { return }
        hasPrepared = true
        guard automaticallyScans else { return }

        requestScan(recoveringInterruptedWork: true)
    }

    func startScan() {
        requestScan(recoveringInterruptedWork: false)
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        scanProgress = nil
        clearLiveScanState()
    }

    func toggleSelection(for item: StorageItem) {
        guard item.isSelectable, !isCleaning else { return }
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    func selectAllVisibleReclaimableItems() {
        guard !isCleaning else { return }
        let IDs = visibleItems
            .filter { $0.isSelectable && $0.safety == .reclaimable }
            .map(\.id)
        selectedItemIDs.formUnion(IDs)
    }

    func clearSelection() {
        guard !isCleaning else { return }
        selectedItemIDs.removeAll()
    }

    func inspect(_ item: StorageItem) {
        inspectedItemID = item.id
    }

    func closeInspector() {
        inspectedItemID = nil
    }

    func applyDisplayPreferences(
        showsProtectedItems: Bool,
        showsFileCounts: Bool,
        sortOrderRawValue: String
    ) {
        self.showsProtectedItems = showsProtectedItems
        self.showsFileCounts = showsFileCounts
        self.itemSortOrder =
            CleanupItemSortOrder(rawValue: sortOrderRawValue)
            ?? .largestFirst

        if
            let inspectedItemID,
            !displayedItems.contains(where: { $0.id == inspectedItemID })
        {
            self.inspectedItemID = nil
        }
    }

    func showReview() {
        guard !selectedItems.isEmpty else { return }
        cleanupReport = nil
        cleanupProgress = nil
        isReviewPresented = true
    }

    func beginCleanup() {
        guard
            !selectedItems.isEmpty,
            !isCleaning,
            cleanupTask == nil
        else {
            return
        }

        let items = selectedItems
        let activeBundleIdentifiers = workspace.activeBundleIdentifiers()
        let blockingBundleIdentifiers = items.reduce(into: Set<String>()) {
            identifiers,
            item in
            identifiers.formUnion(
                item.blockedBundleIdentifiers.intersection(
                    activeBundleIdentifiers
                )
            )
        }

        guard blockingBundleIdentifiers.isEmpty else {
            pendingCleanupItems = items
            blockingApplications = workspace.applications(
                withBundleIdentifiers: blockingBundleIdentifiers
            )
            isOpenApplicationsAlertPresented = true
            return
        }

        startCleanup(items: items)
    }

    func freeFilesAndContinueCleanup() {
        guard
            !pendingCleanupItems.isEmpty,
            !isCleaning,
            cleanupTask == nil
        else {
            return
        }

        let items = pendingCleanupItems
        let bundleIdentifiers = Set(
            blockingApplications.map(\.bundleIdentifier)
        )
        pendingCleanupItems = []
        isOpenApplicationsAlertPresented = false

        if forceCloseModeEnabled {
            workspace.forceTermination(
                ofApplicationsWithBundleIdentifiers: bundleIdentifiers
            )
        } else {
            workspace.requestTermination(
                ofApplicationsWithBundleIdentifiers: bundleIdentifiers
            )
        }
        startCleanup(
            items: items,
            waitingForApplications: bundleIdentifiers
        )
    }

    func cancelFreeFilesPrompt() {
        isOpenApplicationsAlertPresented = false
        pendingCleanupItems = []
        blockingApplications = []
    }

    private func startCleanup(
        items: [StorageItem],
        waitingForApplications bundleIdentifiers: Set<String> = []
    ) {
        isCleaning = true
        cleanupReport = nil

        cleanupTask = Task { [weak self, cleaner, workspace] in
            if !bundleIdentifiers.isEmpty {
                for _ in 0..<60 {
                    guard !Task.isCancelled else { return }
                    if workspace.activeBundleIdentifiers().isDisjoint(
                        with: bundleIdentifiers
                    ) {
                        break
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }

            let activeBundleIdentifiers = workspace.activeBundleIdentifiers()
            let cleanupReport = await cleaner.cleanup(
                request: CleanupRequest(
                    items: items,
                    activeBundleIdentifiers: activeBundleIdentifiers
                ),
                progress: { [weak self] progress in
                    await self?.receiveCleanupProgress(progress)
                }
            )

            guard let self, !Task.isCancelled else { return }
            self.cleanupReport = cleanupReport
            self.removeDeletedItems(from: cleanupReport)
            self.cleanupProgress = nil
            self.isCleaning = false
            self.cleanupTask = nil
            self.blockingApplications = []
            self.selectedItemIDs.removeAll()
        }
    }

    func closeReview() {
        guard !isCleaning else { return }
        isReviewPresented = false
        cleanupReport = nil
        if CleanupPreferences.refreshAfterCleanupEnabled {
            startScan()
        }
    }

    func reveal(_ item: StorageItem) {
        workspace.reveal(item.url)
    }

    func openPrivacySettings() {
        isWaitingForFullDiskAccessSettings = true
        workspace.openPrivacySettings()
    }

    func refreshFullDiskAccess() {
        let previousStatus = fullDiskAccessStatus
        fullDiskAccessStatus = checkFullDiskAccess()
        isWaitingForFullDiskAccessSettings = false
        if previousStatus != .granted, fullDiskAccessStatus == .granted {
            startScan()
        }
    }

    func revealPreservedItems() {
        guard let location = recoveryReport?.preservedLocation else { return }
        workspace.reveal(location)
    }

    func itemCount(in category: StorageCategory) -> Int {
        displayedItems.count { $0.category == category }
    }

    func byteCount(in category: StorageCategory) -> Int64 {
        displayedItems.reduce(into: 0) { total, item in
            if item.category == category {
                total += item.allocatedBytes
            }
        }
    }

    private func requestScan(recoveringInterruptedWork: Bool) {
        guard !isCleaning else { return }
        fullDiskAccessStatus = checkFullDiskAccess()
        startScanOperation(
            recoveringInterruptedWork: recoveringInterruptedWork
        )
    }

    private func startScanOperation(recoveringInterruptedWork: Bool) {
        guard !isCleaning else { return }
        scanTask?.cancel()
        selectedItemIDs.removeAll()
        inspectedItemID = nil
        prepareLiveScanState(from: report)
        isScanning = true
        scanProgress = ScanProgress(
            completedRules: 0,
            totalRules: CleanupCatalog.standard.rules.count,
            currentLocation: AppCopy.Core.startingScan,
            discoveredBytes: 0,
            discoveredItemCount: 0
        )

        scanTask = Task { [weak self, scanner, cleaner] in
            if recoveringInterruptedWork {
                let recoveryReport = await cleaner.recoverInterruptedCleanups()
                guard let self, !Task.isCancelled else { return }
                self.recoveryReport = recoveryReport
            }

            if let cachedReport = await scanner.cachedReport() {
                guard let self, !Task.isCancelled else { return }
                if self.report == nil {
                    self.report = cachedReport
                    self.fullDiskAccessStatus = cachedReport.fullDiskAccessStatus
                    self.prepareLiveScanState(from: cachedReport)
                }
            }

            let report = await scanner.scan { [weak self] progress in
                await self?.receiveScanProgress(progress)
            }

            guard let self, !Task.isCancelled else { return }
            self.report = report
            self.fullDiskAccessStatus = report.fullDiskAccessStatus
            self.isScanning = false
            self.scanProgress = nil
            self.scanTask = nil
            self.clearLiveScanState()
        }
    }

    private func receiveScanProgress(_ progress: ScanProgress) {
        guard isScanning else { return }
        scanProgress = progress

        for ruleID in progress.refreshedRuleIDs {
            if let itemIDs = baselineItemIDsByRule.removeValue(forKey: ruleID) {
                for itemID in itemIDs {
                    liveReportItemsByID.removeValue(forKey: itemID)
                }
            }
            if let issueIDs = baselineIssueIDsByRule.removeValue(forKey: ruleID) {
                for issueID in issueIDs {
                    liveReportIssuesByID.removeValue(forKey: issueID)
                }
            }
        }

        for item in progress.indexedItems {
            liveReportItemsByID[item.id] = item
        }
        for issue in progress.issues {
            liveReportIssuesByID[issue.id] = issue
        }

        guard
            !liveReportItemsByID.isEmpty
                || !liveReportIssuesByID.isEmpty
                || hasLiveScanBaseline
        else {
            return
        }

        report = ScanReport(
            items: Array(liveReportItemsByID.values),
            issues: Array(liveReportIssuesByID.values),
            notices: progress.notices,
            fullDiskAccessStatus: progress.fullDiskAccessStatus,
            scannedAt: Date(),
            duration: .zero,
            source: .live
        )
        fullDiskAccessStatus = progress.fullDiskAccessStatus
    }

    private func receiveCleanupProgress(_ progress: CleanupProgress) {
        guard isCleaning else { return }
        cleanupProgress = progress
    }

    private var displayedItems: [StorageItem] {
        let items = report?.items ?? []
        guard !showsProtectedItems else { return items }
        return items.filter { $0.safety != .protected }
    }

    private func itemComesBefore(
        _ first: StorageItem,
        _ second: StorageItem
    ) -> Bool {
        switch itemSortOrder {
        case .largestFirst:
            if first.allocatedBytes == second.allocatedBytes {
                return itemNameComesBefore(first, second)
            }
            return first.allocatedBytes > second.allocatedBytes
        case .smallestFirst:
            if first.allocatedBytes == second.allocatedBytes {
                return itemNameComesBefore(first, second)
            }
            return first.allocatedBytes < second.allocatedBytes
        case .name:
            let comparison = first.title.localizedStandardCompare(second.title)
            if comparison != .orderedSame {
                return comparison == .orderedAscending
            }
            if first.allocatedBytes != second.allocatedBytes {
                return first.allocatedBytes > second.allocatedBytes
            }
            return first.id < second.id
        }
    }

    private func itemNameComesBefore(
        _ first: StorageItem,
        _ second: StorageItem
    ) -> Bool {
        let comparison = first.title.localizedStandardCompare(second.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }
        return first.id < second.id
    }

    private func removeDeletedItems(from cleanupReport: CleanupReport) {
        let deletedIDs = Set(
            cleanupReport.results.compactMap { result -> String? in
                if case .deleted = result.outcome {
                    return result.id
                }
                return nil
            }
        )
        guard !deletedIDs.isEmpty, let report else { return }

        self.report = ScanReport(
            items: report.items.filter { !deletedIDs.contains($0.id) },
            issues: report.issues,
            notices: report.notices,
            fullDiskAccessStatus: report.fullDiskAccessStatus,
            scannedAt: report.scannedAt,
            duration: report.duration,
            source: report.source
        )
        if
            let inspectedItemID,
            deletedIDs.contains(inspectedItemID)
        {
            self.inspectedItemID = nil
        }
    }

    private func ruleID(for issue: ScanIssue) -> String? {
        issue.id.split(
            separator: "|",
            maxSplits: 1,
            omittingEmptySubsequences: true
        )
        .first
        .map(String.init)
    }

    private func prepareLiveScanState(from baseline: ScanReport?) {
        clearLiveScanState()
        guard let baseline else { return }

        hasLiveScanBaseline = true
        liveReportItemsByID.reserveCapacity(baseline.items.count)
        liveReportIssuesByID.reserveCapacity(baseline.issues.count)

        for item in baseline.items {
            liveReportItemsByID[item.id] = item
            baselineItemIDsByRule[item.ruleID, default: []].insert(item.id)
        }
        for issue in baseline.issues {
            liveReportIssuesByID[issue.id] = issue
            if let ruleID = ruleID(for: issue) {
                baselineIssueIDsByRule[ruleID, default: []].insert(issue.id)
            }
        }
    }

    private func clearLiveScanState() {
        hasLiveScanBaseline = false
        liveReportItemsByID.removeAll(keepingCapacity: true)
        baselineItemIDsByRule.removeAll(keepingCapacity: true)
        liveReportIssuesByID.removeAll(keepingCapacity: true)
        baselineIssueIDsByRule.removeAll(keepingCapacity: true)
    }
}
