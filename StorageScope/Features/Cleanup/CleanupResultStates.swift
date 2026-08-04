import SwiftUI

struct InitialScanView: View {
    let progress: ScanProgress?
    let cancel: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: 4) {
                Text(AppCopy.Results.buildingStorageMap)
                    .font(.title3.weight(.semibold))
                Text(progress?.currentLocation ?? AppCopy.Results.startingScan)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(StorageFormatting.size(progress?.discoveredBytes ?? 0))
                    .font(.system(.callout, design: .monospaced, weight: .medium))
                Text(
                    AppCopy.Results.acrossItemsSoFar(
                        progress?.discoveredItemCount ?? 0
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(AppCopy.Results.stopScanning, action: cancel)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

struct ScanReadyView: View {
    let startScan: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(AppCopy.Results.scanTitle, systemImage: "internaldrive")
        } description: {
            VStack(spacing: 5) {
                Text(AppCopy.Results.scanExplanation)
                Text(AppCopy.Results.scanSafety)
                    .font(.caption)
            }
        } actions: {
            Button(AppCopy.Results.scanAction, action: startScan)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct StorageEmptyState: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
            }
        }
    }
}

struct AccessNoticeView: View {
    let issueCount: Int
    let openSettings: () -> Void

    var body: some View {
        NoticeRow(
            title: AppCopy.Results.accessNoticeTitle,
            message: AppCopy.Results.accessNoticeMessage(issueCount),
            systemImage: "lock.trianglebadge.exclamationmark",
            tint: UtilityTheme.review,
            actionTitle: AppCopy.Results.openSettings,
            action: openSettings
        )
    }

}

struct ScanLimitNoticeView: View {
    let issueCount: Int
    let fullDiskAccessStatus: FullDiskAccessStatus

    var body: some View {
        NoticeRow(
            title: limitTitle,
            message: limitMessage,
            systemImage: "exclamationmark.arrow.triangle.2.circlepath",
            tint: UtilityTheme.managed
        )
    }

    private var limitTitle: String {
        AppCopy.Results.skippedTitle(issueCount)
    }

    private var limitMessage: String {
        switch fullDiskAccessStatus {
        case .granted:
            AppCopy.Results.skippedGrantedMessage
        case .denied:
            AppCopy.Results.skippedDeniedMessage
        case .unknown:
            AppCopy.Results.skippedUnknownMessage
        }
    }
}

struct RecoveryNoticeView: View {
    let report: RecoveryReport
    let showPreservedItems: () -> Void

    var body: some View {
        NoticeRow(
            title: recoveryTitle,
            message: recoveryMessage,
            systemImage: "arrow.uturn.backward.circle.fill",
            tint: UtilityTheme.ready,
            actionTitle: report.preservedItemCount > 0
                ? AppCopy.Results.showPreservedItems
                : nil,
            action: showPreservedItems
        )
    }

    private var recoveryTitle: String {
        AppCopy.Results.recoveryTitle(report.restoredItemCount)
    }

    private var recoveryMessage: String {
        report.preservedItemCount > 0
            ? AppCopy.Results.preservedItemsMessage
            : AppCopy.Results.rollbackMessage
    }
}

struct ScanNoticeView: View {
    let notice: ScanNotice

    var body: some View {
        NoticeRow(
            title: notice.title,
            message: notice.message,
            systemImage: "clock.arrow.circlepath",
            tint: UtilityTheme.managed
        )
    }
}

private struct NoticeRow: View {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 10)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .accessibilityElement(children: .contain)
    }
}
