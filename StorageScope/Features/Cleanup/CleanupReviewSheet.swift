import SwiftUI

struct CleanupReviewSheet: View {
    @Bindable var model: CleanupScreenModel
    @State private var acknowledgedReviewedItems = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if let report = model.cleanupReport {
                CleanupCompletionView(report: report, done: model.closeReview)
            } else {
                reviewContent
            }
        }
        .interactiveDismissDisabled(model.isCleaning)
        .onAppear {
            acknowledgedReviewedItems = false
        }
        .alert(
            model.forceCloseModeEnabled
                ? AppCopy.Review.forceQuitRequired
                : AppCopy.Review.filesOpen,
            isPresented: $model.isOpenApplicationsAlertPresented
        ) {
            Button(AppCopy.Common.cancel, role: .cancel) {
                model.cancelFreeFilesPrompt()
            }
            Button(
                model.forceCloseModeEnabled
                    ? AppCopy.Review.forceQuitAndContinue
                    : AppCopy.Review.quitAndContinue,
                role: .destructive
            ) {
                model.freeFilesAndContinueCleanup()
            }
        } message: {
            Text(openApplicationsMessage)
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 0) {
            reviewHeader
            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.selectedItems) { item in
                        reviewRow(item)
                            .overlay(alignment: .bottom) {
                                Divider()
                            }
                    }
                }
                .padding(.horizontal, UtilityLayout.contentInset)
            }

            Divider()
            reviewFooter
        }
        .frame(width: 680, height: reviewSheetHeight)
    }

    private var reviewHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppCopy.Review.title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Text(
                AppCopy.Results.selectedEstimated(
                    count: model.selectedItems.count,
                    size: StorageFormatting.size(model.selectedBytes)
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, UtilityLayout.contentInset)
        .padding(.vertical, 16)
    }

    private func reviewRow(_ item: StorageItem) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: item.safety.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(UtilityTheme.color(for: item.safety))
                .frame(width: 18, height: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.callout.weight(.medium))
                    Spacer(minLength: 12)
                    Text(StorageFormatting.size(item.allocatedBytes))
                        .font(
                            .system(
                                .callout,
                                design: .monospaced,
                                weight: .medium
                            )
                        )
                }
                Text(item.consequence)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private var reviewFooter: some View {
        VStack(alignment: .leading, spacing: 12) {
            if model.requiresReviewAcknowledgment {
                Toggle(
                    AppCopy.Review.acknowledgment,
                    isOn: $acknowledgedReviewedItems
                )
                .toggleStyle(.checkbox)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            }

            if model.isCleaning {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(AppCopy.Review.cleanupInProgress)
                            .font(.callout.weight(.medium))
                        Spacer()
                        Text(cleanupProgressText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    ProgressView(
                        value: Double(
                            model.cleanupProgress?.completedItemCount ?? 0
                        ),
                        total: Double(
                            max(1, model.cleanupProgress?.totalItemCount ?? 1)
                        )
                    )
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 12) {
                        deletionSummary
                        Spacer()
                        deletionActions
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        deletionSummary
                        deletionActions
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.horizontal, UtilityLayout.contentInset)
        .padding(.vertical, 14)
        .background(.bar)
    }

    private var deletionSummary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(AppCopy.Review.deletionPermanent)
                .font(.callout.weight(.medium))
            Text(AppCopy.Review.listedItemsOnly)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var deletionActions: some View {
        HStack(spacing: 10) {
            Button(AppCopy.Common.cancel, role: .cancel) {
                model.isReviewPresented = false
            }
            .keyboardShortcut(.cancelAction)

            Button(
                AppCopy.Review.deleteSelected,
                role: .destructive
            ) {
                model.beginCleanup()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .keyboardShortcut(.defaultAction)
            .disabled(!canDelete)
        }
    }

    private var reviewSheetHeight: CGFloat {
        let visibleRowCount = min(model.selectedItems.count, 5)
        let rowsHeight = CGFloat(visibleRowCount) * 52
        let acknowledgmentHeight: CGFloat = model.requiresReviewAcknowledgment
            ? 30
            : 0
        let progressHeight: CGFloat = model.isCleaning ? 30 : 0
        let accessibilityHeight: CGFloat = dynamicTypeSize.isAccessibilitySize
            ? 100
            : 0
        return min(
            610,
            max(
                220,
                132
                    + rowsHeight
                    + acknowledgmentHeight
                    + progressHeight
                    + accessibilityHeight
            )
        )
    }

    private var canDelete: Bool {
        !model.isCleaning
            && (!model.requiresReviewAcknowledgment || acknowledgedReviewedItems)
    }

    private var cleanupProgressText: String {
        guard let progress = model.cleanupProgress else {
            if !model.blockingApplications.isEmpty {
                return AppCopy.Review.waitingForApps
            }
            return AppCopy.Review.preparingItems
        }
        return AppCopy.Review.removing(progress.currentItemTitle)
    }

    private var openApplicationsMessage: String {
        let applicationNames = model.blockingApplications.map(\.name)
        let applicationList = applicationNames.formatted(
            .list(type: .and, width: .standard)
        )
        if model.forceCloseModeEnabled {
            return AppCopy.Review.forceQuitMessage(
                applicationCount: applicationNames.count,
                applicationList: applicationList
            )
        }
        return AppCopy.Review.quitMessage(
            applicationCount: applicationNames.count,
            applicationList: applicationList
        )
    }
}

#Preview("Review") {
    CleanupReviewSheet(model: CleanupPreviewData.cleanupReviewModel())
}

#Preview("Review — Large Text") {
    CleanupReviewSheet(model: CleanupPreviewData.cleanupReviewModel())
        .environment(\.dynamicTypeSize, .accessibility2)
}
