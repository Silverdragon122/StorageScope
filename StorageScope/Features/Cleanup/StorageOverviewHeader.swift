import SwiftUI

struct StorageSummaryHeader: View {
    let itemCount: Int
    let totalBytes: Int64
    let reclaimableBytes: Int64
    let reviewBytes: Int64
    let protectedBytes: Int64
    let progress: ScanProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    totalSummary
                    Spacer(minLength: 16)
                    if let progress {
                        scanStatus(progress)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    totalSummary
                    if let progress {
                        scanStatus(progress)
                    }
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    storageBreakdown
                }

                VStack(alignment: .leading, spacing: 6) {
                    storageBreakdown
                }
            }

            if let progress {
                ProgressView(value: progress.fractionCompleted)
                    .controlSize(.small)
                    .accessibilityLabel(AppCopy.Results.scanProgress)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var totalSummary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(StorageFormatting.size(totalBytes))
                .font(
                    .system(
                        .title2,
                        design: .monospaced,
                        weight: .semibold
                    )
                )
            Text(AppCopy.Count.items(itemCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var storageBreakdown: some View {
        summaryValue(
            title: AppCopy.Results.ready,
            bytes: reclaimableBytes,
            systemImage: CleanupSafety.reclaimable.systemImage
        )
        summaryValue(
            title: AppCopy.Results.review,
            bytes: reviewBytes,
            systemImage: CleanupSafety.reviewRequired.systemImage
        )
        summaryValue(
            title: AppCopy.Results.managed,
            bytes: protectedBytes,
            systemImage: CleanupSafety.protected.systemImage
        )
    }

    private func summaryValue(
        title: String,
        bytes: Int64,
        systemImage: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(.secondary)
            Text(StorageFormatting.size(bytes))
                .font(.system(.caption, design: .monospaced, weight: .medium))
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }

    private func scanStatus(_ progress: ScanProgress) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(AppCopy.Results.updatingStorageMap)
                .font(.caption.weight(.medium))
            Text(progress.currentLocation)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SafetySectionHeader: View {
    let safety: CleanupSafety
    let items: [StorageItem]

    private var bytes: Int64 {
        items.reduce(into: 0) { $0 += $1.allocatedBytes }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: safety.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(UtilityTheme.color(for: safety))
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(safety.sectionTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(safety.sectionSubtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(StorageFormatting.size(bytes))
                .font(.system(.caption, design: .monospaced, weight: .medium))
            Text(AppCopy.Count.items(items.count))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.top, 12)
        .padding(.bottom, 5)
        .textCase(nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private extension CleanupSafety {
    var sectionSubtitle: String {
        switch self {
        case .reclaimable:
            AppCopy.Safety.reclaimableSubtitle
        case .reviewRequired:
            AppCopy.Safety.reviewSubtitle
        case .protected:
            AppCopy.Safety.protectedSubtitle
        }
    }
}
