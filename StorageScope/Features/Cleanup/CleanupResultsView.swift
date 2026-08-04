import SwiftUI

struct CleanupResultsView: View {
    @Bindable var model: CleanupScreenModel
    @Binding var sortOrderRawValue: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let visibleItems = model.visibleItems
        let selectedItems = model.selectedItems

        VStack(spacing: 0) {
            if model.report != nil {
                resultsHeader(visibleItems)
            }
            resultsContent(visibleItems)

            if model.report != nil {
                selectionBar(
                    visibleItems: visibleItems,
                    selectedItems: selectedItems
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UtilityTheme.canvas)
        .navigationTitle(model.selectedFilter.title)
        .searchable(text: $model.searchText, prompt: AppCopy.Results.searchPrompt)
        .toolbar {
            ToolbarItemGroup {
                if model.report != nil {
                    Menu {
                        Picker(
                            AppCopy.Results.sortItems,
                            selection: $sortOrderRawValue
                        ) {
                            ForEach(CleanupItemSortOrder.allCases) { order in
                                Text(order.displayName)
                                    .tag(order.rawValue)
                            }
                        }
                    } label: {
                        Label(
                            AppCopy.Results.sortItems,
                            systemImage: "arrow.up.arrow.down"
                        )
                    }
                    .help(AppCopy.Results.sortHelp)
                    .accessibilityLabel(AppCopy.Results.sortItems)
                    .accessibilityValue(selectedSortOrder.displayName)
                }

                if model.isScanning {
                    Button {
                        model.cancelScan()
                    } label: {
                        Label(AppCopy.Results.stopScan, systemImage: "stop.circle")
                    }
                    .help(AppCopy.Results.stopScanHelp)
                } else {
                    Button {
                        model.startScan()
                    } label: {
                        Label(
                            AppCopy.Results.checkForChanges,
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    .help(AppCopy.Results.checkForChangesHelp)
                }
            }
        }
        .animation(
            reduceMotion ? nil : .snappy(duration: 0.25),
            value: model.inspectedItemID
        )
    }

    private var selectedSortOrder: CleanupItemSortOrder {
        CleanupItemSortOrder(rawValue: sortOrderRawValue) ?? .largestFirst
    }

    private func resultsHeader(
        _ visibleItems: [StorageItem]
    ) -> some View {
        StorageSummaryHeader(
            itemCount: visibleItems.count,
            totalBytes: visibleItems.reduce(into: Int64(0)) {
                $0 += $1.allocatedBytes
            },
            reclaimableBytes: bytes(with: .reclaimable, in: visibleItems),
            reviewBytes: bytes(with: .reviewRequired, in: visibleItems),
            protectedBytes: bytes(with: .protected, in: visibleItems),
            progress: model.scanProgress
        )
        .padding(.horizontal, UtilityLayout.contentInset)
        .padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(UtilityTheme.hairline)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func resultsContent(
        _ visibleItems: [StorageItem]
    ) -> some View {
        if let report = model.report {
            if report.items.isEmpty && !model.isScanning {
                StorageEmptyState(
                    title: AppCopy.Results.emptyReportTitle,
                    message: emptyReportMessage(report),
                    systemImage: emptyReportSystemImage(report),
                    actionTitle: shouldOfferFullDiskAccess(for: report)
                        ? AppCopy.Results.openSettings
                        : nil,
                    action: model.openPrivacySettings
                )
            } else {
                loadedResults(report, visibleItems: visibleItems)
            }
        } else {
            if model.isScanning {
                InitialScanView(
                    progress: model.scanProgress,
                    cancel: model.cancelScan
                )
            } else {
                ScanReadyView(startScan: model.startScan)
            }
        }
    }

    private func loadedResults(
        _ report: ScanReport,
        visibleItems: [StorageItem]
    ) -> some View {
        VStack(spacing: 0) {
            noticeStack(report)

            if visibleItems.isEmpty {
                if model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    StorageEmptyState(
                        title: AppCopy.Results.noItemsTitle,
                        message: AppCopy.Results.noItemsMessage,
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                } else {
                    StorageEmptyState(
                        title: AppCopy.Results.noMatchTitle(model.searchText),
                        message: AppCopy.Results.noMatchMessage,
                        systemImage: "magnifyingglass"
                    )
                }
            } else {
                List {
                    ForEach(CleanupSafety.allCases, id: \.self) { safety in
                        let items = visibleItems.filter {
                            $0.safety == safety
                        }
                        if !items.isEmpty {
                            Section {
                                ForEach(items) { item in
                                    StorageItemRow(
                                        item: item,
                                        isSelected: model.selectedItemIDs.contains(item.id),
                                        showsFileCount: model.showsFileCounts,
                                        toggleSelection: {
                                            model.toggleSelection(for: item)
                                        },
                                        inspect: {
                                            model.inspect(item)
                                        }
                                    )
                                    .listRowInsets(
                                        EdgeInsets(
                                            top: 0,
                                            leading: UtilityLayout.contentInset,
                                            bottom: 0,
                                            trailing: UtilityLayout.contentInset
                                        )
                                    )
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                SafetySectionHeader(
                                    safety: safety,
                                    items: items
                                )
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 0,
                                        leading: UtilityLayout.contentInset,
                                        bottom: 0,
                                        trailing: UtilityLayout.contentInset
                                    )
                                )
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 54)
            }
        }
    }

    @ViewBuilder
    private func noticeStack(_ report: ScanReport) -> some View {
        if
            model.recoveryReport != nil
                || !report.issues.isEmpty
                || !report.notices.isEmpty
        {
            VStack(spacing: 0) {
                if let recoveryReport = model.recoveryReport,
                   recoveryReport.restoredItemCount > 0
                        || recoveryReport.preservedItemCount > 0
                {
                    RecoveryNoticeView(
                        report: recoveryReport,
                        showPreservedItems: model.revealPreservedItems
                    )
                }

                if !fullDiskAccessIssues(in: report).isEmpty,
                   report.fullDiskAccessStatus == .denied
                {
                    AccessNoticeView(
                        issueCount: locationCount(
                            in: fullDiskAccessIssues(in: report)
                        ),
                        openSettings: model.openPrivacySettings
                    )
                }

                if !otherScanIssues(in: report).isEmpty {
                    ScanLimitNoticeView(
                        issueCount: locationCount(
                            in: otherScanIssues(in: report)
                        ),
                        fullDiskAccessStatus: report.fullDiskAccessStatus
                    )
                }

                ForEach(report.notices) { notice in
                    ScanNoticeView(notice: notice)
                }
            }
            .padding(.horizontal, UtilityLayout.contentInset)
            .padding(.vertical, 10)
        }
    }

    private func selectionBar(
        visibleItems: [StorageItem],
        selectedItems: [StorageItem]
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                selectionSummary(selectedItems)
                Spacer()
                selectionActions(
                    visibleItems: visibleItems,
                    selectedItems: selectedItems
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                selectionSummary(selectedItems)
                selectionActions(
                    visibleItems: visibleItems,
                    selectedItems: selectedItems
                )
            }
        }
        .padding(.horizontal, UtilityLayout.contentInset)
        .padding(.vertical, 13)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(UtilityTheme.strongerHairline)
                .frame(height: 1)
        }
    }

    private func selectionSummary(
        _ selectedItems: [StorageItem]
    ) -> some View {
        let selectedBytes = selectedItems.reduce(into: Int64(0)) {
            $0 += $1.allocatedBytes
        }

        return HStack(alignment: .firstTextBaseline, spacing: 7) {
            if selectedItems.isEmpty {
                Text(AppCopy.Results.chooseWhatToRemove)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(AppCopy.Count.items(selectedItems.count))
                    .font(.callout.weight(.medium))
                Text(StorageFormatting.size(selectedBytes))
                    .font(.system(.callout, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func selectionActions(
        visibleItems: [StorageItem],
        selectedItems: [StorageItem]
    ) -> some View {
        HStack(spacing: 9) {
            if selectedItems.isEmpty {
                Button(AppCopy.Results.selectReadyItems) {
                    model.selectAllVisibleReclaimableItems()
                }
                .disabled(
                    !visibleItems.contains {
                        $0.isSelectable && $0.safety == .reclaimable
                    }
                )
            } else {
                Button(AppCopy.Results.clearSelection) {
                    model.clearSelection()
                }
            }

            Button {
                model.showReview()
            } label: {
                Text(AppCopy.Results.reviewCleanup)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedItems.isEmpty || model.isScanning)
        }
        .controlSize(.regular)
    }

    private func bytes(
        with safety: CleanupSafety,
        in visibleItems: [StorageItem]
    ) -> Int64 {
        visibleItems.reduce(into: 0) { total, item in
            if item.safety == safety {
                total += item.allocatedBytes
            }
        }
    }

    private func fullDiskAccessIssues(
        in report: ScanReport
    ) -> [ScanIssue] {
        report.issues.filter { $0.kind == .permissionDenied }
    }

    private func otherScanIssues(in report: ScanReport) -> [ScanIssue] {
        if report.fullDiskAccessStatus == .denied {
            return report.issues.filter { $0.kind != .permissionDenied }
        }
        return report.issues
    }

    private func locationCount(in issues: [ScanIssue]) -> Int {
        Set(issues.map(\.locationName)).count
    }

    private func emptyReportMessage(_ report: ScanReport) -> String {
        guard !report.issues.isEmpty else {
            return AppCopy.Results.noLocationsFound
        }
        if
            report.fullDiskAccessStatus == .denied,
            !fullDiskAccessIssues(in: report).isEmpty
        {
            return AppCopy.Results.fullDiskAccessNeededForScan
        }
        return AppCopy.Results.locationsChanged
    }

    private func emptyReportSystemImage(_ report: ScanReport) -> String {
        guard !report.issues.isEmpty else { return "internaldrive" }
        return report.fullDiskAccessStatus == .denied
            && !fullDiskAccessIssues(in: report).isEmpty
            ? "lock.trianglebadge.exclamationmark"
            : "arrow.triangle.2.circlepath"
    }

    private func shouldOfferFullDiskAccess(for report: ScanReport) -> Bool {
        report.fullDiskAccessStatus == .denied
            && !fullDiskAccessIssues(in: report).isEmpty
    }
}
