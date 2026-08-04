import SwiftUI

struct StorageItemDetailsView: View {
    let item: StorageItem
    let showsFileCount: Bool
    let reveal: () -> Void
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            inspectorToolbar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    itemHeader

                    Divider()

                    inspectorSection(title: AppCopy.Details.whatItIs) {
                        Text(item.detail)
                    }

                    inspectorSection(title: consequenceTitle) {
                        Text(item.consequence)
                    }

                    inspectorSection(title: AppCopy.Details.details) {
                        VStack(spacing: 7) {
                            detailRow(
                                label: AppCopy.Details.category,
                                value: item.category.displayName
                            )
                            if showsFileCount, item.fileCount > 0 {
                                detailRow(
                                    label: AppCopy.Details.contents,
                                    value: AppCopy.Count.files(item.fileCount)
                                )
                            }
                            detailRow(
                                label: AppCopy.Details.cleanup,
                                value: item.isSelectable
                                    ? AppCopy.Details.available
                                    : AppCopy.Details.unavailable
                            )
                        }
                    }

                    inspectorSection(title: AppCopy.Details.location) {
                        Text(StorageFormatting.abbreviatedPath(item.url))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: reveal) {
                            Label(
                                AppCopy.Details.showInFinder,
                                systemImage: "finder"
                            )
                            .foregroundStyle(UtilityTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(UtilityLayout.contentInset)
            }
        }
    }

    private var inspectorToolbar: some View {
        HStack {
            Text(AppCopy.Details.inspector)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppCopy.Details.close)
        }
        .padding(.horizontal, UtilityLayout.contentInset)
        .frame(minHeight: 44)
    }

    private var itemHeader: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: item.category.systemImage)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(item.title)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(StorageFormatting.size(item.allocatedBytes))
                    .font(
                        .system(
                            .headline,
                            design: .monospaced,
                            weight: .semibold
                        )
                    )

                Label(item.safety.displayName, systemImage: item.safety.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(UtilityTheme.color(for: item.safety))
            }
        }
    }

    private func inspectorSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.callout.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            content()
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var consequenceTitle: String {
        item.safety == .protected
            ? AppCopy.Details.whyItStays
            : AppCopy.Details.afterCleanup
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}
