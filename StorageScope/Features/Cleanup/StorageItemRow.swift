import SwiftUI

struct StorageItemRow: View {
    let item: StorageItem
    let isSelected: Bool
    let showsFileCount: Bool
    let toggleSelection: () -> Void
    let inspect: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            selectionControl

            Button(action: inspect) {
                HStack(spacing: 10) {
                    Image(systemName: item.category.systemImage)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 5) {
                            Text(item.detail)
                                .lineLimit(1)
                            if showsFileCount, item.fileCount > 0 {
                                Text("·")
                                    .accessibilityHidden(true)
                                Text(AppCopy.Count.files(item.fileCount))
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    Text(StorageFormatting.size(item.allocatedBytes))
                        .font(
                            .system(
                                .callout,
                                design: .monospaced,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.primary)
                        .frame(minWidth: 82, alignment: .trailing)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(item.title)
            .accessibilityValue(
                AppCopy.Row.accessibilityValue(
                    size: StorageFormatting.size(item.allocatedBytes),
                    safety: item.safety.displayName
                )
            )
            .accessibilityHint(AppCopy.Row.showDetailsHint)
        }
        .padding(.vertical, 8)
        .contextMenu {
            if item.isSelectable {
                Button(
                    isSelected
                        ? AppCopy.Row.deselectAction
                        : AppCopy.Row.selectAction
                ) {
                    toggleSelection()
                }
            }
            Button(AppCopy.Row.showDetailsAction, action: inspect)
        }
    }

    @ViewBuilder
    private var selectionControl: some View {
        if item.isSelectable {
            Toggle(
                isOn: Binding(
                    get: { isSelected },
                    set: { _ in toggleSelection() }
                )
            ) {
                Text(
                    isSelected
                        ? AppCopy.Row.deselect(item.title)
                        : AppCopy.Row.select(item.title)
                )
            }
            .labelsHidden()
            .toggleStyle(.checkbox)
            .accessibilityLabel(
                isSelected
                    ? AppCopy.Row.deselect(item.title)
                    : AppCopy.Row.select(item.title)
            )
        } else {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityLabel(AppCopy.Safety.managedElsewhere)
        }
    }
}
