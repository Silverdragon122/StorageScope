import SwiftUI

struct CleanupSidebar: View {
    @Bindable var model: CleanupScreenModel

    var body: some View {
        List(selection: $model.selectedFilter) {
            Label {
                SidebarLabel(
                    title: AppCopy.Sidebar.allStorage,
                    count: model.displayedItemCount
                )
            } icon: {
                Image(systemName: "internaldrive")
                    .symbolRenderingMode(.hierarchical)
            }
            .tag(StorageFilter.all)

            Section(AppCopy.Sidebar.sources) {
                ForEach(StorageCategory.allCases) { category in
                    Label {
                        SidebarLabel(
                            title: category.displayName,
                            count: model.itemCount(in: category)
                        )
                    } icon: {
                        Image(systemName: category.systemImage)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .tag(StorageFilter.category(category))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(AppCopy.name)
    }
}

private struct SidebarLabel: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
            Spacer(minLength: 8)
            if count > 0 {
                Text(count, format: .number)
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
