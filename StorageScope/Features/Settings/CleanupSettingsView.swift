import SwiftUI

struct CleanupSettingsView: View {
    @AppStorage(CleanupPreferences.scanOnLaunchKey)
    private var scanOnLaunchEnabled = true

    @AppStorage(CleanupPreferences.refreshAfterCleanupKey)
    private var refreshAfterCleanupEnabled = true

    @AppStorage(CleanupPreferences.showProtectedItemsKey)
    private var showProtectedItemsEnabled = true

    @AppStorage(CleanupPreferences.showFileCountsKey)
    private var showFileCountsEnabled = true

    @AppStorage(CleanupPreferences.itemSortOrderKey)
    private var itemSortOrderRawValue = CleanupItemSortOrder.largestFirst.rawValue

    @AppStorage(CleanupPreferences.forceCloseModeKey)
    private var forceCloseModeEnabled = false

    var body: some View {
        Form {
            scanningSection
            resultsSection
            cleanupSection
            restoreDefaultsSection
        }
        .formStyle(.grouped)
        .tint(UtilityTheme.accent)
        .frame(
            minWidth: 460,
            idealWidth: 500,
            minHeight: 520,
            idealHeight: 540
        )
    }

    private var scanningSection: some View {
        Section {
            Toggle(AppCopy.Settings.scanOnLaunch, isOn: $scanOnLaunchEnabled)
            Toggle(
                AppCopy.Settings.refreshAfterCleanup,
                isOn: $refreshAfterCleanupEnabled
            )
        } header: {
            Text(AppCopy.Settings.scanning)
        }
    }

    private var resultsSection: some View {
        Section {
            Toggle(
                AppCopy.Settings.showManagedStorage,
                isOn: $showProtectedItemsEnabled
            )
            Toggle(
                AppCopy.Settings.showFileCounts,
                isOn: $showFileCountsEnabled
            )

            Picker(
                AppCopy.Settings.sortItems,
                selection: $itemSortOrderRawValue
            ) {
                ForEach(CleanupItemSortOrder.allCases) { order in
                    Text(order.displayName)
                        .tag(order.rawValue)
                }
            }
        } header: {
            Text(AppCopy.Settings.results)
        }
    }

    private var cleanupSection: some View {
        Section {
            Toggle(
                AppCopy.Settings.forceQuitBlockingApps,
                isOn: $forceCloseModeEnabled
            )
        } header: {
            Text(AppCopy.Settings.safety)
        } footer: {
            Text(AppCopy.Settings.forceQuitExplanation)
        }
    }

    private var restoreDefaultsSection: some View {
        Section {
            Button {
                restoreDefaults()
            } label: {
                Label(
                    AppCopy.Settings.restoreDefaults,
                    systemImage: "arrow.counterclockwise"
                )
            }
        }
    }

    private func restoreDefaults() {
        scanOnLaunchEnabled = true
        refreshAfterCleanupEnabled = true
        showProtectedItemsEnabled = true
        showFileCountsEnabled = true
        itemSortOrderRawValue = CleanupItemSortOrder.largestFirst.rawValue
        forceCloseModeEnabled = false
    }
}

#Preview("Settings") {
    CleanupSettingsView()
}
