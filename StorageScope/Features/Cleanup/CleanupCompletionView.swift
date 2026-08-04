import SwiftUI

struct CleanupCompletionView: View {
    let report: CleanupReport
    let done: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        report.failedCount == 0
                            ? AppCopy.Completion.spaceReclaimed
                            : AppCopy.Completion.incomplete
                    )
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                    Text(completionSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(
                    systemName: report.failedCount == 0
                        ? "checkmark.circle.fill"
                        : "exclamationmark.triangle.fill"
                )
                .font(.title2)
                .foregroundStyle(completionColor)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, UtilityLayout.contentInset)
            .padding(.vertical, 16)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(report.results) { result in
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: resultSymbol(for: result))
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(resultColor(for: result))
                                .frame(width: 20)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.title)
                                    .font(.callout.weight(.semibold))
                                Text(resultMessage(for: result))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            Divider()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, UtilityLayout.contentInset)
            }

            Divider()

            HStack {
                Spacer()
                Button(AppCopy.Common.done, action: done)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, UtilityLayout.contentInset)
            .padding(.vertical, 14)
            .background(.bar)
        }
        .frame(width: 680, height: completionSheetHeight)
    }

    private var completionSheetHeight: CGFloat {
        let visibleRowCount = min(report.results.count, 6)
        let accessibilityHeight: CGFloat = dynamicTypeSize.isAccessibilitySize
            ? 80
            : 0
        return min(
            560,
            max(
                230,
                124
                    + CGFloat(visibleRowCount) * 52
                    + accessibilityHeight
            )
        )
    }

    private var completionColor: Color {
        report.failedCount == 0 ? UtilityTheme.ready : UtilityTheme.review
    }

    private var completionSummary: String {
        let removed = StorageFormatting.size(report.deletedBytes)
        if report.failedCount == 0 {
            return AppCopy.Completion.removed(removed)
        }
        return AppCopy.Completion.removedNeedsAttention(
            size: removed,
            count: report.failedCount
        )
    }

    private func resultSymbol(for result: CleanupItemResult) -> String {
        switch result.outcome {
        case .deleted:
            "checkmark.circle.fill"
        case .partiallyDeleted:
            "exclamationmark.triangle.fill"
        case .failed:
            "xmark.circle.fill"
        }
    }

    private func resultColor(for result: CleanupItemResult) -> Color {
        switch result.outcome {
        case .deleted:
            UtilityTheme.ready
        case .partiallyDeleted:
            UtilityTheme.review
        case .failed:
            .red
        }
    }

    private func resultMessage(for result: CleanupItemResult) -> String {
        switch result.outcome {
        case .deleted(let bytes):
            return AppCopy.Completion.removed(StorageFormatting.size(bytes))
        case .partiallyDeleted(let bytes, let reason):
            return AppCopy.Completion.partiallyRemoved(
                size: StorageFormatting.size(bytes),
                message: message(for: reason)
            )
        case .failed(let reason):
            return message(for: reason)
        }
    }

    private func message(for reason: CleanupFailureReason) -> String {
        switch reason {
        case .noLongerExists:
            AppCopy.Completion.noLongerExists
        case .changedSinceScan:
            AppCopy.Completion.changedSinceScan
        case .outsideAllowedLocation:
            AppCopy.Completion.outsideAllowedLocation
        case .protectedItem:
            AppCopy.Completion.protectedItem
        case .applicationIsOpen:
            AppCopy.Completion.applicationIsOpen
        case .unsafeFilesystemEntry:
            AppCopy.Completion.unsafeFilesystemEntry
        case .couldNotStage:
            AppCopy.Completion.couldNotStage
        case .couldNotDelete:
            AppCopy.Completion.couldNotDelete
        case .administratorAuthorizationCanceled:
            AppCopy.Completion.authorizationCanceled
        case .administratorAuthorizationFailed:
            AppCopy.Completion.authorizationFailed
        case .commandUnavailable:
            AppCopy.Completion.commandUnavailable
        case .commandFailed:
            AppCopy.Completion.commandFailed
        }
    }
}

#Preview("Cleanup complete") {
    CleanupCompletionView(
        report: CleanupReport(
            results: [
                CleanupItemResult(
                    id: "build-files",
                    title: "TrailNotes build files",
                    outcome: .deleted(bytes: 38_400_000_000)
                ),
                CleanupItemResult(
                    id: "app-cache",
                    title: "Slack cache",
                    outcome: .deleted(bytes: 4_100_000_000)
                )
            ],
            completedAt: Date()
        ),
        done: {}
    )
}

#Preview("Cleanup needs attention") {
    CleanupCompletionView(
        report: CleanupReport(
            results: [
                CleanupItemResult(
                    id: "build-files",
                    title: "TrailNotes build files",
                    outcome: .partiallyDeleted(
                        bytes: 37_900_000_000,
                        reason: .applicationIsOpen
                    )
                )
            ],
            completedAt: Date()
        ),
        done: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
